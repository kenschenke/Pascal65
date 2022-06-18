#ifndef MISC_H
#define MISC_H

typedef enum {
    ccLetter, ccDigit, ccSpecial, ccQuote, ccWhiteSpace,
    ccEndOfFile, ccError,
} TCharCode;

typedef enum {
    tcDummy, tcIdentifier, tcNumber, tcString, tcEndOfFile, tcError,

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
    tyDummy, tyInteger, tyCharacter, tyString,
} TDataType;

typedef union {
    long integer;
    char character;
    char *pString;
} TDataValue;

#endif // end of MISC_H
