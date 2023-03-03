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

SYMBNODE routineNode;

void condGetToken(TTokenCode tc, TErrorCode ec) {
    // Get another token only if the current one matches tc
    if (tc == tokenCode) {
        getToken();
    } else {
        Error(ec);
    }
}

void condGetTokenAppend(CHUNKNUM Icode, TTokenCode tc, TErrorCode ec) {
    // Get another token only if the current one matches tc.
    if (tc == tokenCode) {
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
    getNextToken();
}

void getTokenAppend(CHUNKNUM Icode)
{
    getToken();
    putTokenToIcode(Icode, tokenCode);
}

void initParser(void) {
    initSymtabsForParser();
}

CHUNKNUM parse(const char *filename)
{
    int i;
    TINBUF *tinBuf;

    for (i = 0; i <= 127; ++i) charCodeMap[i] = ccError;

    tinBuf = tin_open(filename, abortSourceFileOpenFailed);
    pInputBuffer = tinBuf;

    getToken();
    parseProgram();
    tin_close(tinBuf);

    // printf("\n%20d source lines.\n", scanner->pTinBuf->currentLineNumber);
    // printf("%20d syntax errors.\n", errorCount);

    return routineNode.node.nodeChunkNum;
}

void resync(const TTokenCode *pList1,
            const TTokenCode *pList2,
            const TTokenCode *pList3) {
    TErrorCode errorCode;

    // Is the current token in one of the lists?
    char errorFlag = !tokenIn(tokenCode, pList1) &&
                    !tokenIn(tokenCode, pList2) &&
                    !tokenIn(tokenCode, pList3);
    
    if (errorFlag) {
        // Nope.  Flag it as an error.
        errorCode = tokenCode == tcEndOfFile ?
            errUnexpectedEndOfFile : errUnexpectedToken;
        Error(errorCode);

        // Skip tokens
        while (!tokenIn(tokenCode, pList1) &&
            !tokenIn(tokenCode, pList2) &&
            !tokenIn(tokenCode, pList3) &&
            tokenCode != tcPeriod &&
            tokenCode != tcEndOfFile) {
            getToken();
        }

        // Flag an unexpected end of file (if haven't already)
        if ((tokenCode == tcEndOfFile) &&
            (errorCode != errUnexpectedEndOfFile)) {
            Error(errUnexpectedEndOfFile);
        }
    }
}
