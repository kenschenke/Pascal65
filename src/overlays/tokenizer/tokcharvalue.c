/**
 * tokcharvalue.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Tokenize numeric character values, e.g. #65 or #$41
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <scanner.h>
#include <int32.h>

void getCharValueToken(void)
{
    char digit, isHex=0, ch, *ps;

    tokenValue.byte = 0;

    ps = tokenString;
    *ps++ = '#';
    ch = getChar();

    if (ch == '$') {
        *ps++ = '$';
        ch = getChar();
        isHex = 1;
    }

    // Acculumate the value as long as the total allowable
    // number of digits has not been exceeded.
    while(1) {
        if (isHex) {
            if (ch >= 'A' && ch <= 'F') {
                ch &= 0x7f;
            }
            else if (ch >= '0' && ch <= '9') {
                digit = ch - '0';
            }
            else if (ch >= 'a' && ch <= 'f') {
                digit = ch - 'a' + 10;
            } else {
                break;
            }

            if (tokenValue.byte) {
                tokenValue.byte <<= 4;
            }
            tokenValue.byte |= digit;
        } else if (getCharCode(ch) != ccDigit) {
            break;
        }

        *ps++ = ch;

        ch = getChar();
    }

    *ps = 0;
    if (!isHex) {
        tokenValue.byte = (unsigned char) parseInt32(tokenString+1);
    }

    tokenString[0] = tokenString[2] = '\'';
    tokenString[1] = tokenValue.byte;
    tokenString[3] = 0;
    tokenValue.byte = 0;

    tokenCode = tcString;
}

