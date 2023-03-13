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
#include <real.h>

SYMBNODE routineNode;
TTokenCode parserToken;
TDataValue parserValue;
TDataType parserType;
CHUNKNUM parserIdentifier;
char parserString[MAX_LINE_LEN + 1];

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
    TTokenizerCode code;

    if (isMemBufAtEnd(parserIcode)) {
        Error(errUnexpectedEndOfFile);
        return;
    }

    readFromMemBuf(parserIcode, &code, 1);
    switch (code) {
        case tzLineNum:
            readFromMemBuf(parserIcode, &currentLineNumber, 2);
            getToken();
            break;

        case tzIdentifier:
        case tzString: {
            char len;
            readFromMemBuf(parserIcode, &len, 1);
            readFromMemBuf(parserIcode, parserString, len);
            parserString[len] = 0;
            parserToken = code == tzIdentifier ? tcIdentifier : tcString;
            break;
        }

        case tzInteger:
        case tzReal: {
            char len;

            if (code == tzInteger) {
                readFromMemBuf(parserIcode, &parserValue.integer, 2);
                parserType = tyInteger;
            } else {
                readFromMemBuf(parserIcode, &parserValue.real, 4);
                parserType = tyReal;
            }
            parserToken = tcNumber;
            readFromMemBuf(parserIcode, &len, 1);
            readFromMemBuf(parserIcode, parserString, len);
            parserString[len] = 0;
            break;
        }
        
        case tzToken:
            readFromMemBuf(parserIcode, &parserToken, 1);
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
