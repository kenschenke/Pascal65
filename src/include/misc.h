/**
 * misc.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for enumerations
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef MISC_H
#define MISC_H

#include <chunks.h>
#include <real.h>

typedef enum {
    ccLetter, ccDigit, ccSpecial, ccQuote, ccWhiteSpace,
    ccEndOfFile, ccError,
} TCharCode;

typedef enum {
    tcDummy, tcIdentifier, tcNumber, tcString, tcEndOfFile, tcError,

    tcBOOLEAN, tcCHAR, tcINTEGER, tcREAL,

    tcFALSE, tcTRUE,

    tcUpArrow, tcStar, tcLParen, tcRParen, tcMinus, tcPlus,
    tcEqual, tcLBracket, tcRBracket, tcColon, tcSemicolon, tcLt,
    tcGt, tcComma, tcPeriod, tcSlash, tcColonEqual, tcLe, tcGe,
    tcNe, tcDotDot,

    tcAND, tcARRAY, tcBEGIN, tcCASE, tcCONST, tcDIV,
    tcDO, tcDOWNTO, tcELSE, tcEND, tcFILE, tcFOR, tcFUNCTION,
    tcGOTO, tcIF, tcIN, tcLABEL, tcMOD, tcNIL, tcNOT, tcOF, tcOR,
    tcPACKED, tcPROCEDURE, tcPROGRAM, tcRECORD, tcREPEAT, tcSET,
    tcTHEN, tcTO, tcTYPE, tcUNTIL, tcVAR, tcWHILE, tcWITH,
} TTokenCode;

typedef enum {
    tyDummy, tyInteger, tyReal, tyCharacter, tyString,
} TDataType;

typedef union {
    int integer;
    char character;
    CHUNKNUM stringChunkNum;
} TDataValue;

#endif // end of MISC_H
