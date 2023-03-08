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

typedef struct {
    TTokenCode code;
    TDataType type;
    TDataValue value;
    char string[MAX_LINE_LEN + 1];
} TOKEN;

extern TTokenCode tokenCode;
extern TDataType tokenType;
extern TDataValue tokenValue;
extern char tokenString[MAX_LINE_LEN + 1];

TCharCode getCharCode(unsigned char ch);

void getNextToken(void);

void getNumberToken(char sawDecimalPoint);
void getSpecialToken(void);
void getStringToken(void);
void getWordToken(void);

#endif // end of SCANNER_H
