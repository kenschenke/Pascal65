/**
 * scanner.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for tokenizing source code.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <scanner.h>
#include <tokenizer.h>
#include <string.h>
#include <error.h>

static void initCharCodeMap(void);
static void skipWhiteSpace(void);

TTokenCode tokenCode;
TTokenizerCode tokenizerCode;
TDataType tokenType;
TDataValue tokenValue;
char tokenString[MAX_LINE_LEN + 1];

void getNextToken(void)
{
    skipWhiteSpace();
    if (isCompilerDirective()) {
        // If the skipWhiteSpace function encountered a compiler directive inside
        // a comment then it leaves the tokenCode set to that directive. If so,
        // return so the directive can be tokenized and the comment closed out.
        return;
    }

    switch (getCharCode(getCurrentChar())) {
        case ccLetter:
            getWordToken();
            break;

        case ccDigit:
            getNumberToken(0);
            break;

        case ccQuote:
            getStringToken();
            break;

        case ccSpecial:
            getSpecialToken();
            break;

        case ccDollar:
            getHexToken();
            break;

        case ccHash:
            getCharValueToken();
            break;

        case ccPercent:
            getBinaryToken();
            break;

        case ccEndOfFile:
            tokenCode = tcEndOfFile;
            break;

        case ccError:
            Error(errUnexpectedToken);
            getChar();  // move past the bad character
            break;
    }
}

TCharCode getCharCode(unsigned char ch) {
    if ((ch >= 65 && ch <= 90) ||
        (ch >= 97 && ch <= 122) ||
        (ch >= 193 && ch <= 218)) {
        return ccLetter;
    }

    if (ch == '+' || ch == '-' || ch == '*' || ch == '/' ||
        ch == '=' || ch == '^' || ch == '.' || ch == ',' ||
        ch == '<' || ch == '>' || ch == '(' || ch == ')' ||
        ch == '[' || ch == ']' || ch == ':' || ch == ';' ||
        ch == '!' || ch == '&' || ch == '@') {
        return ccSpecial;
    }

    if (ch >= 48 && ch <= 57) return ccDigit;

    if (ch == ' ' || ch == '\t' || ch == 10 || ch == 13 || ch == '\0') {
        return ccWhiteSpace;
    }

    if (ch == '\'') return ccQuote;

    if (ch == '$') return ccDollar;

    if (ch == '#') return ccHash;

    if (ch == '%') return ccPercent;

    if (ch == eofChar) return ccEndOfFile;

    return ccError;
}

static void skipWhiteSpace(void)
{
    char ch;

    ch = getCurrentChar();
    while(1) {
        if (ch == '/') {
            ch = getChar();
            if (ch == '/') {
                ch = getLine();
                continue;
            } else {
                putBackChar();
                break;
            }
        } else if (ch == '(') {
            ch = getChar();
            if (ch == '*') {
                while (ch != eofChar) {
                    ch = getChar();
                    if (ch == '$') {
                        getChar();
                        // Check for a compiler directive
                        getWordToken();
                        // If a compiler directive was found, skip processing
                        // the rest of the comment
                        if (tokenCode == tcSTACKSIZE) {
                            break;
                        }
                    }
                    else if (ch == '*') {
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
        } else if (getCharCode(ch) != ccWhiteSpace) {
            break;
        }
        ch = getChar();
    }
}
