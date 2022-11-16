/**
 * scanner.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for tokenizing source code.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <scanner.h>
#include <string.h>

static void initCharCodeMap(void);
static void skipWhiteSpace(void);

TINBUF *pInputBuffer;

TTokenCode tokenCode;
TDataType tokenType;
TDataValue tokenValue;
char tokenString[MAX_LINE_LEN + 1];

TCharCode   charCodeMap[128];

void getNextToken(void)
{
    skipWhiteSpace();

    switch (charCodeMap[getCurrentChar()]) {
        case ccLetter:
            getWordToken();
            break;

        case ccDigit:
            getNumberToken();
            break;

        case ccQuote:
            getStringToken();
            break;

        case ccSpecial:
            getSpecialToken();
            break;

        case ccEndOfFile:
            tokenCode = tcEndOfFile;
            break;
    }
}

static void initCharCodeMap(void)
{
    int i;

    if (charCodeMap['a'] != ccError) {
        return;  // already initialized
    }

    for (i = 97; i <= 122; ++i) charCodeMap[i] = ccLetter;
    for (i = 65; i <= 90; ++i) charCodeMap[i] = ccLetter;
    for (i = 48; i <= 57; ++i) charCodeMap[i] = ccDigit;
    charCodeMap['+' ] = charCodeMap['-' ] = ccSpecial;
    charCodeMap['*' ] = charCodeMap['/' ] = ccSpecial;
    charCodeMap['=' ] = charCodeMap['^' ] = ccSpecial;
    charCodeMap['.' ] = charCodeMap[',' ] = ccSpecial;
    charCodeMap['<' ] = charCodeMap['>' ] = ccSpecial;
    charCodeMap['(' ] = charCodeMap[')' ] = ccSpecial;
    charCodeMap['[' ] = charCodeMap[']' ] = ccSpecial;
    charCodeMap[':' ] = charCodeMap[';' ] = ccSpecial;
    charCodeMap[' ' ] = charCodeMap['\t'] = ccWhiteSpace;
    charCodeMap[13  ] = charCodeMap['\0'] = ccWhiteSpace;
    charCodeMap[10  ] = ccWhiteSpace;  // tab (C64 doesn't have this)
    charCodeMap['\''] = ccQuote;
    charCodeMap[eofChar] = ccEndOfFile;
}

static void skipWhiteSpace(void)
{
    char ch;

    initCharCodeMap();

    ch = getCurrentChar();
    while(1) {
        if (ch == '/') {
            ch = getChar();
            if (ch == '/') {
                ch = getLine();
            } else {
                putBackChar();
                break;
            }
        } else if (ch == '(') {
            ch = getChar();
            if (ch == '*') {
                while (ch != eofChar) {
                    ch = getChar();
                    if (ch == '*') {
                        ch = getChar();
                        if (ch == ')') {
                            break;
                        }
                    }
                }
            } else {
                putBackChar();
                break;
            }
        } else if (charCodeMap[ch] != ccWhiteSpace) {
            break;
        }
        ch = getChar();
    }
}
