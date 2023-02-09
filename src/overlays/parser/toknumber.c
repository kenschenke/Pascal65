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
#include <int16.h>
#include <real.h>

#define MAX_NUMBER_LEN 15

// sawDecimalPoint is non-zero if the scanner saw a decimal point and
// already consumed it.  This happens if the token starts with a
// decimal point but not a zero.
void getNumberToken(char sawDecimalPoint)
{
    const int maxInteger = SHRT_MAX;
    char ch, *ps;
    int digitCount = 0;
    int countErrorFlag = 0;
    const int maxDigitCount = 20;
    int value = 0;
    TDataType type = tyInteger;
    char sawDotDotFlag = 0;  // non-zero if encountered '..'
    char sawExponent = 0;    // non-zero if 'e' or 'E' encountered
    char sawExponentSign = 0;// non-zero when +|- encountered after e|E

    ch = getCurrentChar();
    if (charCodeMap[ch] != ccDigit) {
        Error(errInvalidNumber);
        return;  // failure
    }

    ps = tokenString;

    // If sawDecimalPoint is non-zero, this call came from
    // getSpecialToken() when it saw a decimal point followed
    // by a digit.  The digit was put back but the decimal
    // point needs to be preserved
    if (sawDecimalPoint) {
        *ps++ = '.';
        type = tyReal;
        ++digitCount;
    }

    // Acculumate the value as long as the total allowable
    // number of digits has not been exceeded.
    while(1) {
        if (ch == '.') {
            // If we already saw a decimal point then this
            // is another one and not part of the number.
            if (sawDecimalPoint) {
                putBackChar();
                break;
            }

            // If type is tyReal then we have already seen
            // a decimal point and this one is not part
            // of the number.
            if (type == tyReal) {
                putBackChar();
                break;
            }

            ch = getChar();
            if (ch == '.') {
                // We have a '.' token.  Put the character back
                // so that the token can be extracted next.
                sawDotDotFlag = 1;
                putBackChar();
                break;
            } else {
               type = tyReal;
               *ps++ = '.';
            }
        } else if (ch == 'e' || ch == 'E') {
            if (type != tyReal) {
                // This is not part of the number.
                break;
            }
            sawExponent = 1;
        } else if (ch == '-' || ch == '+') {
            if (type != tyReal || !sawExponent || sawExponentSign) {
                // this is not part of the number.
                break;
            }
            sawExponentSign = 1;
        } else if (charCodeMap[ch] != ccDigit) {
            break;
        }

        *ps++ = ch;

        if (++digitCount > maxDigitCount) {
            countErrorFlag = 1;
        }

        ch = getChar();
    }

    *ps = 0;
    if (type == tyInteger) {
        tokenValue.integer = parseInt16(tokenString);
    } else {
        tokenValue.real = strToFloat(tokenString);
    }

    tokenType = type;
    tokenCode = countErrorFlag ? tcError : tcNumber;
}
