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
#include <int32.h>
#include <real.h>

#define MAX_NUMBER_LEN 15

// sawDecimalPoint is non-zero if the scanner saw a decimal point and
// already consumed it.  This happens if the token starts with a
// decimal point but not a zero.
void getNumberToken(char sawDecimalPoint)
{
    char ch, *ps;
    int digitCount = 0;
    int countErrorFlag = 0;
    const int maxDigitCount = 20;
    char sawExponent = 0;    // non-zero if 'e' or 'E' encountered
    char sawExponentSign = 0;// non-zero when +|- encountered after e|E

    tokenizerCode = tzDummy;

    ch = getCurrentChar();
    if (getCharCode(ch) != ccDigit) {
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
        tokenizerCode = tzReal;
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

            // If type is tzReal then we have already seen
            // a decimal point and this one is not part
            // of the number.
            if (tokenizerCode == tzReal) {
                putBackChar();
                break;
            }

            // Look at the next character and see if it's a
            // decimal point too.  If so, this is actually
            // the '..' operator.
            ch = getChar();
            if (ch == '.') {
                // We have a '..' operator.  Put the character back
                // so that the token can be extracted next.
                putBackChar();
                break;
            } else {
               tokenizerCode = tzReal;
               *ps++ = '.';
            }
        } else if (ch == 'e' || ch == 'E') {
            if (tokenizerCode != tzReal) {
                // This is not part of the number.
                break;
            }
            sawExponent = 1;
        } else if (ch == '-' || ch == '+') {
            if (tokenizerCode != tzReal || !sawExponent || sawExponentSign) {
                // this is not part of the number.
                break;
            }
            sawExponentSign = 1;
        } else if (getCharCode(ch) != ccDigit) {
            break;
        }

        *ps++ = ch;

        if (++digitCount > maxDigitCount) {
            countErrorFlag = 1;
        }

        ch = getChar();
    }

    *ps = 0;
    if (tokenizerCode == tzDummy) {
        tokenValue.cardinal = parseInt32(tokenString);
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
    }

    tokenCode = countErrorFlag ? tcError : tcNumber;
}
