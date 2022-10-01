/**
 * parser.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Entry point for parser overlay.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <scanner.h>
#include <error.h>
#include <common.h>
#include <symtab.h>
#include <parscommon.h>
#include <string.h>

void getToken(SCANNER *scanner);

void condGetToken(SCANNER *scanner, TTokenCode tc, TErrorCode ec) {
    // Get another token only if the current one matches tc
    if (tc == scanner->token.code) {
        getToken(scanner);
    } else {
        Error(ec);
    }
}

void condGetTokenAppend(SCANNER *scanner, CHUNKNUM Icode, TTokenCode tc, TErrorCode ec) {
    // Get another token only if the current one matches tc.
    if (tc == scanner->token.code) {
        getTokenAppend(scanner, Icode);
    } else {
        Error(ec);
    }
}

char enterGlobalSymtab(const char *pString, SYMTABNODE *node)
{
    return enterSymtab(globalSymtab, node, pString, dcUndefined);
}

char findSymtabNode(SYMTABNODE *pNode, const char *identifier) {
    if (symtabStackSearchAll(identifier, pNode) == 0) {
        Error(errUndefinedIdentifier);                         // error not found
        if (enterGlobalSymtab(identifier, pNode) == 0) {       // but enter it anyway
            return 0;
        }
    }

    return 1;
}

void getToken(SCANNER *scanner)
{
    getNextToken(scanner);
}

void getTokenAppend(SCANNER *scanner, CHUNKNUM Icode)
{
    getToken(scanner);
    putTokenToIcode(Icode, scanner->token.code);
}

void initParser(void) {
    initSymtabsForParser();
}

void parse(SCANNER *scanner)
{
    int i;
    SYMTABNODE programId;

#if 1
#if 0
    SYMTABNODE dummyProgram;
    DEFN defn;
    char nameChunk[CHUNK_LEN];

    for (i = 0; i <= 127; ++i) charCodeMap[i] = ccError;
    memset(&dummyProgram, 0, sizeof(SYMTABNODE));
    memset(&defn, 0, sizeof(DEFN));
    memset(nameChunk, 0, sizeof(nameChunk));
    memcpy(nameChunk, "DummyProgram", 12);
    allocChunk(&dummyProgram.defnChunk);
    allocChunk(&dummyProgram.nameChunkNum);
    defn.how = dcProgram;
    storeChunk(dummyProgram.defnChunk, (unsigned char *)&defn);
    storeChunk(dummyProgram.nameChunkNum, (unsigned char *)nameChunk);
#endif

    for (i = 0; i <= 127; ++i) charCodeMap[i] = ccError;

    getToken(scanner);
    parseProgram(scanner, &programId);
    // parseDeclarations(scanner, &dummyProgram);
    // parseCompound(scanner, pGlobalIcode);
#else
    int i;
    SYMTABNODE inputNode, outputNode;

    for (i = 0; i <= 127; ++i) charCodeMap[i] = ccError;
    enterGlobalSymtab("input", &inputNode);
    enterGlobalSymtab("output", &outputNode);

    getTokenAppend(scanner, pGlobalIcode);

    // Loop to parse statements until the end of the program.
    do {
        if (isFatalError || isStopKeyPressed()) {
            isFatalError = 1;  // Force the main program to exit
            break;
        }

        // Shouldn't see an end of file.
        if (scanner->token.code == tcEndOfFile) {
            Error(errUnexpectedEndOfFile);
            break;
        }

        parseStatement(scanner, pGlobalIcode);

        // If the current token is not a semicolon or the final period,
        // we have a syntax error.  If the current token is an identifier
        // (i.e. the start of the next statement), the error is a missing
        // semicolon.  Otherwise, the error is an unexpected token, and so
        // we skip tokens until we find a semicolon or a period, or until
        // we reach the end of the source file.
        if (scanner->token.code == tcSemicolon && scanner->token.code != tcPeriod) {
            if (scanner->token.code == tcIdentifier) {
                Error(errMissingSemicolon);

                while (scanner->token.code != tcSemicolon &&
                    scanner->token.code != tcPeriod &&
                    scanner->token.code != tcEndOfFile) {
                    getTokenAppend(scanner, pGlobalIcode);
                }
            }
        }

        // Skip over any semicolons before parsing the next statement.
        while (scanner->token.code == tcSemicolon) {
            getTokenAppend(scanner, pGlobalIcode);
        }
    } while (scanner->token.code != tcPeriod);
#endif

    // printf("\n%20d source lines.\n", scanner->pTinBuf->currentLineNumber);
    // printf("%20d syntax errors.\n", errorCount);
}

void resync(SCANNER *scanner,
                    const TTokenCode *pList1,
                    const TTokenCode *pList2,
                    const TTokenCode *pList3) {
    TErrorCode errorCode;

    // Is the current token in one of the lists?
    char errorFlag = !tokenIn(scanner->token.code, pList1) &&
                    !tokenIn(scanner->token.code, pList2) &&
                    !tokenIn(scanner->token.code, pList3);
    
    if (errorFlag) {
        // Nope.  Flag it as an error.
        errorCode = scanner->token.code == tcEndOfFile ?
            errUnexpectedEndOfFile : errUnexpectedToken;
        Error(errorCode);

        // Skip tokens
        while (!tokenIn(scanner->token.code, pList1) &&
            !tokenIn(scanner->token.code, pList2) &&
            !tokenIn(scanner->token.code, pList3) &&
            scanner->token.code != tcPeriod &&
            scanner->token.code != tcEndOfFile) {
            getToken(scanner);
        }

        // Flag an unexpected end of file (if haven't already)
        if ((scanner->token.code == tcEndOfFile) &&
            (errorCode != errUnexpectedEndOfFile)) {
            Error(errUnexpectedEndOfFile);
        }
    }
}
