/**
 * scanner.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for source file scanner and tokenizer
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef SCANNER_H
#define SCANNER_H

#include <buffer.h>
#include <misc.h>

extern TCharCode charCodeMap[128];

typedef struct {
    TTokenCode code;
    TDataType type;
    TDataValue value;
    char string[MAX_LINE_LEN + 1];
} TOKEN;

typedef struct {
    TINBUF *pTinBuf;
    TOKEN token;
} SCANNER;

TOKEN *getNextToken(SCANNER *scanner);

void getNumberToken(TOKEN *token, SCANNER *scanner);
void getSpecialToken(TOKEN *token, SCANNER *scanner);
void getStringToken(TOKEN *token, SCANNER *scanner);
void getWordToken(TOKEN *token, SCANNER *scanner);

char scanner_isFatalError(SCANNER *scanner);

#endif // end of SCANNER_H
