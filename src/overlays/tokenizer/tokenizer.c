#include <tokenizer.h>
#include <membuf.h>
#include <error.h>
#include <scanner.h>
#include <string.h>
#include <common.h>

/**
 * The tokenizer creates a membuf to store the tokenized code.  In addition
 * to the Pascal language tokens such as tcSemicolon or tcIf, identifiers and
 * literals are stored in the intermediate code like this:
 * 
 * REWRITE: The tokenizer needs to create the symbol table nodes and populate
 * with enough information for the parser to add them to a symbol table.  This
 * would allow node creation code to be moved into the tokenizer overlay.
 * 
 * REWRITE: initPredefinedTypes can happen in the tokenizer, maybe in a
 * initTokenizer function.
 * 
 * TODO: Remove membuf's dependency on int16 and float shared routines.
 * 
 * TODO: Move testing code from shared code in parsertest to the parsertest overlay.
 * 
 * tzIdentifier
 *    The tzIdentifier code is followed by a one-byte integer string
 *    length followed by the string value (not null-terminated).
 * 
 * tzLineNum
 *    This code is followed by the two-byte line number integer.
 * 
 * tzToken
 *    The tzToken code is followed by the one-byte TTokenCode value.
 * 
 * tzInteger
 *    The tzInteger code is followed by the two-byte integer value.
 * 
 * tzReal
 *    The tzReal code is followed by the four-byte real value.
 * 
 * tzChar - NOT USED
 *    The tzChar code is followed by the one-byte character value.
 * 
 * tzString
 *    The tzString code is followed by a two-byte integer string
 *    length followed by the string value (not null-terminated).
 *    The string is stored with the quotes.
 */

static void initPredefined(CHUNKNUM symtabChunkNum);
static void initSymtabs(void);
static void setPredefinedType(CHUNKNUM typeId, CHUNKNUM typeChunk);
static void writeTzIdentifier(CHUNKNUM Icode);

static void initPredefinedTypes(CHUNKNUM symtabChunkNum) {
    TTYPE typeNode;
    SYMBNODE node;
    CHUNKNUM integerId, booleanId, charId, realId;
    CHUNKNUM falseId, trueId;

    // Enter the names of the predefined types and of "false"
    // and "true" into the symbol table.

    enterSymtab(symtabChunkNum, &node, "integer", dcType);
    integerId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "real", dcType);
    realId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "boolean", dcType);
    booleanId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "char", dcType);
    charId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "false", dcConstant);
    falseId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "true", dcConstant);
    trueId = node.node.nodeChunkNum;

    // Create the predefined type objects

    integerType = makeType(fcScalar, sizeof(int), integerId);
    realType = makeType(fcScalar, sizeof(unsigned long), realId);
    booleanType = makeType(fcEnum, sizeof(int), booleanId);
    charType = makeType(fcScalar, sizeof(char), charId);
    dummyType = makeType(fcNone, 1, 0);

    setPredefinedType(integerId, integerType);
    setPredefinedType(realId, realType);
    setPredefinedType(booleanId, booleanType);
    setPredefinedType(charId, charType);

    if (retrieveChunk(booleanType, (unsigned char *)&typeNode) == 0) {
        return;
    }
    typeNode.enumeration.max = 1;
    typeNode.enumeration.constIds = falseId;
    if (storeChunk(booleanType, (unsigned char *)&typeNode) == 0) {
        return;
    }

    // More initialization for the "false" and "true" id nodes.
    if (loadSymbNode(falseId, &node) == 0) {
        return;
    }
    node.node.nextNode = trueId;
    setType(&node.node.typeChunk, booleanType);
    node.defn.constant.value.integer = 0;
    saveSymbNode(&node);

    if (loadSymbNode(trueId, &node) == 0) {
        return;
    }
    setType(&node.node.typeChunk, booleanType);
    node.defn.constant.value.integer = 1;
    saveSymbNode(&node);

    // Initialize the dummy type object that will be used
    // for erroneous type definitions and for typeless objects.
    if (setType(&dummyType, makeType(fcNone, 1, 0)) == 0) {
        return;
    }
}

static void initSymtabs(void) {
    int i;

    currentNestingLevel = 0;
    for (i = 1; i < MAX_NESTING_LEVEL; ++i) symtabStack[i] = 0;

    makeSymtab(&globalSymtab);

    symtabStack[0] = globalSymtab;

    initPredefinedTypes(symtabStack[0]);
}

void initTokenizer(void) {
    initSymtabs();
}

static void setPredefinedType(CHUNKNUM typeId, CHUNKNUM typeChunkNum) {
    SYMTABNODE node;

    getChunkCopy(typeId, &node);
    setType(&node.typeChunk, typeChunkNum);
    storeChunk(typeId, (unsigned char *)&node);
}

CHUNKNUM tokenize(const char *filename) {
    CHUNKNUM Icode;
    TTokenizerCode tzType;
    extern char lineNumberChanged;
    
    allocMemBuf(&Icode);

    tinOpen(filename, abortSourceFileOpenFailed);

    while (!isBufferEof()) {
        getNextToken();

        if (lineNumberChanged) {
            tzType = tzLineNum;
            writeToMemBuf(Icode, &tzType, 1);
            writeToMemBuf(Icode, &currentLineNumber, 2);
            lineNumberChanged = 0;
        }

        switch (tokenCode) {
            case tcIdentifier:
            case tcString: {
                char len = (char) strlen(tokenString);
                tzType = tokenCode == tcIdentifier ? tzIdentifier : tzString;
                writeToMemBuf(Icode, &tzType, 1);
                writeToMemBuf(Icode, &len, 1);
                writeToMemBuf(Icode, tokenString, len);
                break;
            }

            case tcNumber:
                if (tokenType == tyInteger) {
                    tzType = tzInteger;
                    writeToMemBuf(Icode, &tzType, 1);
                    writeToMemBuf(Icode, &tokenValue.integer, 2);
                } else {
                    tzType = tzReal;
                    writeToMemBuf(Icode, &tzType, 1);
                    writeToMemBuf(Icode, &tokenValue.real, 4);
                }
                break;
            
            default:
                tzType = tzToken;
                writeToMemBuf(Icode, &tzType, 1);
                writeToMemBuf(Icode, &tokenCode, 1);
                break;
        }
    }

    tinClose();

    return Icode;
}
