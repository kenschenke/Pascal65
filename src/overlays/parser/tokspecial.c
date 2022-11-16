/**
 * toknumber.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to tokenize a special character.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <scanner.h>

void getSpecialToken(void)
{
    char ch = getCurrentChar();
    char *ps = tokenString;
    
    *ps++ = ch;

    switch (ch) {
        case '^': tokenCode = tcUpArrow;   ch = getChar(); break;
        case '*': tokenCode = tcStar;      ch = getChar(); break;
        case '(': tokenCode = tcLParen;    ch = getChar(); break;
        case ')': tokenCode = tcRParen;    ch = getChar(); break;
        case '-': tokenCode = tcMinus;     ch = getChar(); break;
        case '+': tokenCode = tcPlus;      ch = getChar(); break;
        case '=': tokenCode = tcEqual;     ch = getChar(); break;
        case '[': tokenCode = tcLBracket;  ch = getChar(); break;
        case ']': tokenCode = tcRBracket;  ch = getChar(); break;
        case ';': tokenCode = tcSemicolon; ch = getChar(); break;
        case ',': tokenCode = tcComma;     ch = getChar(); break;
        case '/': tokenCode = tcSlash;     ch = getChar(); break;

        case ':':
            ch = getChar();     // : or :=
            if (ch == '=') {
                *ps++ = '=';
                tokenCode = tcColonEqual;
                getChar();
            } else {
                tokenCode = tcColon;
            }
            break;

        case '<':
            ch = getChar();     // < or <= or <>
            if (ch == '=') {
                *ps++ = '=';
                tokenCode = tcLe;
                getChar();
            } else if (ch == '>') {
                *ps++ = '>';
                tokenCode = tcNe;
                getChar();
            } else {
                tokenCode = tcLt;
            }
            break;

        case '>':
            ch = getChar();     // > or >=
            if (ch == '=') {
                *ps++ = '=';
                tokenCode = tcGe;
                getChar();
            } else {
                tokenCode = tcGt;
            }
            break;

        case '.':
            ch = getChar();     // . or ..
            if (ch == '.') {
                *ps++ = '.';
                tokenCode = tcDotDot;
                getChar();
            } else {
                tokenCode = tcPeriod;
            }
            break;
        
        default:
            tokenCode = tcError;
            getChar();
            Error(errUnrecognizable);
            break;
    }

    *ps = 0;
}
