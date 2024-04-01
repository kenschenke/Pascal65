/**
 * tokstring.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to tokenize a string literal
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <scanner.h>

void getStringToken(void)
{
    char ch;
    char *ps = tokenString;

    *ps++ = '\'';

    // Get the string
    ch = getChar();     // first char after opening quote
    while (ch != eofChar) {
        if (ch == '\'') {   // look for another quote
            // Fetched a quote.  Now check for an adjacent quote,
            // since two consecutive quotes represent a single
            // quote in the string
            ch = getChar();
            if (ch != '\'')     // another quote, so previous
                break;          // quote ended the string
        }

        // Replace the end of line character with a blank
        else if (ch == 0)
            ch = ' ';

        // Append current char to string, then get the next char
        *ps++ = ch;
        ch = getChar();
    }

    if (ch == eofChar)
        Error(errUnexpectedEndOfFile);
    
    *ps++ = '\'';
    *ps = 0;

    tokenCode = tcString;
}
