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
    ccLetter, ccDigit, ccSpecial, ccQuote, ccWhiteSpace, ccDollar,
    ccEndOfFile, ccError,
} TCharCode;

typedef enum {
    tcDummy, tcIdentifier, tcNumber, tcString, tcEndOfFile, tcError,

    tcBOOLEAN, tcBYTE, tcCARDINAL, tcCHAR, tcINTEGER, tcLONGINT, tcREAL, tcSHORTINT, tcWORD,

    tcFALSE, tcTRUE,

    tcUpArrow, tcStar, tcLParen, tcRParen, tcMinus, tcPlus,
    tcEqual, tcLBracket, tcRBracket, tcColon, tcSemicolon, tcLt,
    tcGt, tcComma, tcPeriod, tcSlash, tcColonEqual, tcLe, tcGe,
    tcNe, tcDotDot,

    tcAND, tcARRAY, tcBEGIN, tcCASE, tcCONST, tcDIV,
    tcDO, tcDOWNTO, tcELSE, tcEND, tcFILE, tcFOR, tcFUNCTION,
    tcGOTO, tcIF, tcIMPLEMENTATION, tcIN, tcINTERFACE, tcLABEL,
    tcMOD, tcNIL, tcNOT, tcOF, tcOR, tcPACKED, tcPROCEDURE,
    tcPROGRAM, tcRECORD, tcREPEAT, tcSET, tcTHEN, tcTO, tcTYPE,
    tcUNIT, tcUNTIL, tcUSES, tcVAR, tcWHILE, tcWITH,
} TTokenCode;

typedef enum {
    tyDummy,
    tyShortInt, // -128..127
    tyByte,     // 0..255
    tyInteger,  // -32768..32767
    tyWord,     // 0..65535
    tyLongInt,  // -2147483648..2147483647
    tyCardinal, // 0..4294967295
    tyReal, tyCharacter, tyString,
} TDataType;

typedef union {
    char character;
    char shortInt;
    unsigned char byte;
    int integer;
    unsigned int word;
    long longInt;
    unsigned long cardinal;
    CHUNKNUM stringChunkNum;
} TDataValue;

#endif // end of MISC_H
