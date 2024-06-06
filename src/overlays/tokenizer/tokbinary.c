/**
 * tokbinary.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Tokenize binary values, e.g. %11010001
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <scanner.h>
#include <limits.h>

void getBinaryToken(void)
{
    char digit, ch, *ps;

    tokenValue.cardinal = 0;

    ps = tokenString;
    *ps++ = '%';
    ch = getChar();

    // Acculumate the value as long as the total allowable
    // number of digits has not been exceeded.
    while(1) {
        if (ch == '0' || ch == '1') {
            digit = ch - '0';
        } else {
            break;
        }

        if (tokenValue.cardinal) {
            tokenValue.cardinal <<= 1;
        }
        tokenValue.cardinal |= digit;

        *ps++ = ch;

        ch = getChar();
    }

    *ps = 0;
    if (tokenValue.cardinal < UCHAR_MAX) {
        tokenValue.byte = tokenValue.cardinal;
        tokenizerCode = tzByte;
    }
    else if (tokenValue.cardinal < USHRT_MAX) {
        tokenValue.word = tokenValue.cardinal;
        tokenizerCode = tzWord;
    } else {
        tokenizerCode = tzCardinal;
    }
    tokenCode = tcNumber;
}

