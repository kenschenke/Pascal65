/**
 * tokword.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Source to tokenize a reserved word.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <scanner.h>
#include <string.h>
#include <ctype.h>

const int minResWordLength = 2;
const int maxResWordLength = 9;

typedef struct {
    const char *pString;
    TTokenCode code;
} TResWord;

static TResWord rw2[] = {
    {"do", tcDO}, {"if", tcIF}, {"in", tcIN}, {"of", tcOF},
    {"or", tcOR}, {"to", tcTO}, {NULL},
};

static TResWord rw3[] = {
    {"and", tcAND}, {"div", tcDIV}, {"end", tcEND}, {"for", tcFOR},
    {"mod", tcMOD}, {"nil", tcNIL}, {"not", tcNOT}, {"set", tcSET},
    {"var", tcVAR}, {NULL},
};

static TResWord rw4[] = {
    {"byte", tcBYTE}, {"case", tcCASE}, {"char", tcCHAR}, {"else", tcELSE},
    {"file", tcFILE}, {"goto", tcGOTO}, {"real", tcREAL}, {"then", tcTHEN},
    {"true", tcTRUE}, {"type", tcTYPE}, {"with", tcWITH}, {"word", tcWORD}, {NULL},
};

static TResWord rw5[] = {
    {"array", tcARRAY}, {"begin", tcBEGIN}, {"const", tcCONST}, {"false", tcFALSE},
    {"label", tcLABEL}, {"until", tcUNTIL}, {"while", tcWHILE},
    {NULL},
};

static TResWord rw6[] = {
    {"downto", tcDOWNTO}, {"packed", tcPACKED}, {"record", tcRECORD},
    {"repeat", tcREPEAT}, {NULL},
};

static TResWord rw7[] = {
    {"boolean", tcBOOLEAN}, {"integer", tcINTEGER}, {"longint", tcLONGINT},
    {"program", tcPROGRAM}, {NULL},
};

static TResWord rw8[] = {
    {"cardinal", tcCARDINAL}, {"function", tcFUNCTION}, {"shortint", tcSHORTINT}, {NULL},
};

static TResWord rw9[] = {
    {"procedure", tcPROCEDURE}, {NULL},
};

static TResWord *rwTable[] = {
    NULL, NULL, rw2, rw3, rw4, rw5, rw6, rw7, rw8, rw9,
};

static void checkForReservedWord(void)
{
    int len = strlen(tokenString);
    TResWord *prw;

    tokenCode = tcIdentifier;

    if (len >= minResWordLength && len <= maxResWordLength) {
        for (prw = rwTable[len]; prw->pString; ++prw) {
            if (strcmp(tokenString, prw->pString) == 0) {
                tokenCode = prw->code;
                break;
            }
        }
    }
}

void getWordToken(void)
{
    char ch, *ps;

    ch = getCurrentChar();
    ps = tokenString;

    // Extract the word
    do {
        *ps++ = ch;
        ch = getChar();
    } while (getCharCode(ch) == ccLetter || getCharCode(ch) == ccDigit);

    *ps = 0;

    // If this file came from a PC, convert lower-case ASCII
    // to upper-case ASCII.
    for (ps = tokenString; *ps; ++ps) {
        if (*ps >= 97 && *ps <= 122) {
            *ps -= 32;
        }
    }
    strlwr(tokenString);

    checkForReservedWord();
}

