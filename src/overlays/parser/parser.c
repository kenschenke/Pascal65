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
#include <tokenizer.h>

SYMBNODE routineNode;
TTokenCode parserToken;
TDataValue parserValue;
CHUNKNUM parserIdentifier;
TTokenizerCode parserTokenizerCode;
char parserString[CHUNK_LEN + 1];

static CHUNKNUM parserIcode;

void condGetToken(TTokenCode tc, TErrorCode ec) {
    // Get another token only if the current one matches tc
    if (tc == parserToken) {
        getToken();
    } else {
        Error(ec);
    }
}

void condGetTokenAppend(CHUNKNUM Icode, TTokenCode tc, TErrorCode ec) {
    // Get another token only if the current one matches tc.
    if (tc == parserToken) {
        getTokenAppend(Icode);
    } else {
        Error(ec);
    }
}

char enterGlobalSymtab(const char *pString, SYMBNODE *node)
{
    return enterSymtab(globalSymtab, node, pString, dcUndefined);
}

char findSymtabNode(SYMBNODE *pNode, const char *identifier) {
    if (symtabStackSearchAll(identifier, pNode) == 0) {
        Error(errUndefinedIdentifier);                         // error not found
        if (enterGlobalSymtab(identifier, pNode) == 0) {       // but enter it anyway
            return 0;
        }
    }

    return 1;
}

void getToken(void)
{
    if (isMemBufAtEnd(parserIcode)) {
        Error(errUnexpectedEndOfFile);
        return;
    }

    readFromMemBuf(parserIcode, &parserTokenizerCode, 1);
    switch (parserTokenizerCode) {
        case tzIdentifier:
            readFromMemBuf(parserIcode, &parserIdentifier, 2);
            getChunkCopy(parserIdentifier, parserString);
            parserToken = tcIdentifier;
            break;

        case tzInteger:
            readFromMemBuf(parserIcode, &parserValue.integer, 2);
            parserToken = tcNumber;
            break;
        
        case tzReal:
            readFromMemBuf(parserIcode, &parserValue.real, 4);
            parserToken = tcNumber;
            break;
        
        case tzChar:
            readFromMemBuf(parserIcode, &parserValue.character, 1);
            parserToken = tcString;
            break;
        
        case tzString:
            // readFromMemBuf(parserIcode, &parserValue.string.len, 2);
            // readFromMemBuf(parserIcode, &parserValue.string.chunkNum, 2);
            // getChunkCopy(parserValue.string.chunkNum, parserString);
            parserToken = tcString;
            break;
    }
}

void getTokenAppend(CHUNKNUM Icode)
{
    getToken();
    putTokenToIcode(Icode, parserToken);
}

void initParser(void) {
    initSymtabsForParser();
}

CHUNKNUM parse(CHUNKNUM Icode)
{
    parserIcode = Icode;
    setMemBufPos(Icode, 0);

    getToken();
    parseProgram();

    // printf("\n%20d source lines.\n", scanner->pTinBuf->currentLineNumber);
    // printf("%20d syntax errors.\n", errorCount);

    return routineNode.node.nodeChunkNum;
}

void resync(const TTokenCode *pList1,
            const TTokenCode *pList2,
            const TTokenCode *pList3) {
    TErrorCode errorCode;

    // Is the current token in one of the lists?
    char errorFlag = !tokenIn(parserToken, pList1) &&
                    !tokenIn(parserToken, pList2) &&
                    !tokenIn(parserToken, pList3);
    
    if (errorFlag) {
        // Nope.  Flag it as an error.
        errorCode = parserToken == tcEndOfFile ?
            errUnexpectedEndOfFile : errUnexpectedToken;
        Error(errorCode);

        // Skip tokens
        while (!tokenIn(parserToken, pList1) &&
            !tokenIn(parserToken, pList2) &&
            !tokenIn(parserToken, pList3) &&
            parserToken != tcPeriod &&
            parserToken != tcEndOfFile) {
            getToken();
        }

        // Flag an unexpected end of file (if haven't already)
        if ((parserToken == tcEndOfFile) &&
            (errorCode != errUnexpectedEndOfFile)) {
            Error(errUnexpectedEndOfFile);
        }
    }
}
