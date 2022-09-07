/**
 * common.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to initialize common data shared between overlays
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <common.h>
#include <symtab.h>
#include <icode.h>
#include <cbm.h>
#include <conio.h>
#include <types.h>

short cntSymtabs;
CHUNKNUM firstSymtabChunk;
CHUNKNUM globalSymtab;
ICODE *pGlobalIcode;
char isFatalError;

// Tokens that can start a declaration
const TTokenCode tlDeclarationStart[] = {
    tcCONST, tcTYPE, tcVAR, tcPROCEDURE, tcFUNCTION, tcDummy
};

// Tokens that can follow a declaration
const TTokenCode tlDeclarationFollow[] = {
    tcSemicolon, tcIdentifier, tcDummy
};

// Tokens that can start an identifier or field
const TTokenCode tlIdentifierStart[] = {
    tcIdentifier, tcDummy
};

// Tokens that can follow an identifier or field
const TTokenCode tlIdentifierFollow[] = {
    tcComma, tcIdentifier, tcColon, tcSemicolon, tcDummy
};

// Tokens that can follow an identifier or field sublist
const TTokenCode tlSublistFollow[] = {
    tcColon, tcDummy
};

// Tokens that can follow a field declaration
const TTokenCode tlFieldDeclFollow[] = {
    tcSemicolon, tcIdentifier, tcEND, tcDummy
};

// Tokens that can start an enumeration constant
const TTokenCode tlEnumConstStart[] = {
    tcIdentifier, tcDummy
};

// Tokens that can follow an enumeration constant
const TTokenCode tlEnumConstFollow[] = {
    tcComma, tcIdentifier, tcRParen, tcSemicolon, tcDummy
};

// Tokens that can follow a subrange limit
const TTokenCode tlSubrangeLimitFollow[] = {
    tcDotDot, tcIdentifier, tcPlus, tcMinus, tcString,
    tcRBracket, tcComma, tcSemicolon, tcOF, tcDummy
};

// Tokens that can start an index type
const TTokenCode tlIndexStart[] = {
    tcIdentifier, tcNumber, tcString, tcLParen, tcPlus, tcMinus,
    tcDummy
};

// Tokens that can follow an index type
const TTokenCode tlIndexFollow[] = {
    tcComma, tcRBracket, tcOF, tcSemicolon, tcDummy
};

// Tokens that can follow an index type list
const TTokenCode tlIndexListFollow[] = {
    tcOF, tcIdentifier, tcLParen, tcARRAY, tcRECORD,
    tcPlus, tcMinus, tcNumber, tcString, tcSemicolon, tcDummy
};

const TTokenCode tlSubscriptOrFieldStart[] = {
    tcLBracket, tcPeriod, tcDummy
};

void initCommon(void)
{
    SYMTAB symtab;

    cntSymtabs = 0;
    firstSymtabChunk = 0;
    isFatalError = 0;

    makeSymtab(&symtab);
    globalSymtab = symtab.symtabChunkNum;
    initPredefinedTypes(&symtab);
    pGlobalIcode = makeIcode();
}

char isStopKeyPressed()
{
    char ch = 0;

    if (kbhit()) {
        ch = cgetc();
    }

    return ch == CH_STOP;
}
