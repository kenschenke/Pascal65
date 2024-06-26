/**
 * scanner.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for source file scanner and tokenizer
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef SCANNER_H
#define SCANNER_H

#include <buffer.h>
#include <misc.h>
#include <tokenizer.h>

typedef struct {
    TTokenCode code;
    TDataType type;
    TDataValue value;
    char string[MAX_LINE_LEN + 1];
} TOKEN;

extern TTokenCode tokenCode;
extern TTokenizerCode tokenizerCode;
extern TDataValue tokenValue;
extern char tokenString[MAX_LINE_LEN + 1];

TCharCode getCharCode(unsigned char ch);

void getNextToken(void);

void getBinaryToken(void);   // numeric value as a binary value, e.g. %11010001
void getCharValueToken(void);  // character as a numeric value, e.g. #65 or #$41
void getHexToken(void);
void getNumberToken(char sawDecimalPoint);
void getSpecialToken(void);
void getStringToken(void);
void getWordToken(void);

#endif // end of SCANNER_H
