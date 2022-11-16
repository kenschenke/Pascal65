/**
 * toknumber.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to tokenize a numeric literal.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <scanner.h>
#include <limits.h>

void getNumberToken(void)
{
    const int maxInteger = SHRT_MAX;
    char ch, *ps;
    int digitCount = 0;
    int countErrorFlag = 0;
    const int maxDigitCount = 20;
    int value = 0;

    ch = getCurrentChar();
    if (charCodeMap[ch] != ccDigit) {
        Error(errInvalidNumber);
        return;  // failure
    }

    // Acculumate the value as long as the total allowable
    // number of digits has not been exceeded.
    ps = tokenString;
    do {
        *ps++ = ch;

        if (++digitCount <= maxDigitCount) {
            value = 10 * value + (ch - '0');
        } else {
            countErrorFlag = 1;
        }

        ch = getChar();
    } while (charCodeMap[ch] == ccDigit);

    *ps = 0;
    tokenValue.integer = value;
    tokenType = tyInteger;
    tokenCode = countErrorFlag ? tcError : tcNumber;
}
