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
static void skipWhiteSpace(SCANNER *scanner);

TCharCode   charCodeMap[128];

TOKEN *getNextToken(SCANNER *scanner)
{
    skipWhiteSpace(scanner);

    switch (charCodeMap[getCurrentChar(scanner->pTinBuf)]) {
        case ccLetter:
            getWordToken(&scanner->token, scanner);
            break;

        case ccDigit:
            getNumberToken(&scanner->token, scanner);
            break;

        case ccQuote:
            getStringToken(&scanner->token, scanner);
            break;

        case ccSpecial:
            getSpecialToken(&scanner->token, scanner);
            break;

        case ccEndOfFile:
            scanner->token.code = tcEndOfFile;
            break;
    }

    return &scanner->token;
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

static void skipWhiteSpace(SCANNER *scanner)
{
    char ch;

    initCharCodeMap();

    ch = getCurrentChar(scanner->pTinBuf);
    while(1) {
        if (ch == '/') {
            ch = getChar(scanner->pTinBuf);
            if (ch == '/') {
                ch = getLine(scanner->pTinBuf);
            } else {
                putBackChar(scanner->pTinBuf);
                break;
            }
        } else if (ch == '(') {
            ch = getChar(scanner->pTinBuf);
            if (ch == '*') {
                while (ch != eofChar) {
                    ch = getChar(scanner->pTinBuf);
                    if (ch == '*') {
                        ch = getChar(scanner->pTinBuf);
                        if (ch == ')') {
                            break;
                        }
                    }
                }
            } else {
                putBackChar(scanner->pTinBuf);
                break;
            }
        } else if (charCodeMap[ch] != ccWhiteSpace) {
            break;
        }
        ch = getChar(scanner->pTinBuf);
    }
}
