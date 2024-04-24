/**
 * parscommon.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Common data for parser
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <misc.h>

// Tokens that can start a statement.
extern const TTokenCode tlStatementStart[] = {
    tcBEGIN, tcCASE, tcFOR, tcIF, tcREPEAT, tcWHILE, tcIdentifier,
    tcDummy
};

// Tokens that can follow a statement
extern const TTokenCode tlStatementFollow[] = {
    tcSemicolon, tcPeriod, tcEND, tcELSE, tcUNTIL, tcDummy
};

// Tokens that cannot occur outside a statement such as IF
extern const TTokenCode tlStatementListNotAllowed[] = {
    tcELSE, tcDummy
};

// Tokens that can start a CASE label
extern const TTokenCode tlCaseLabelStart[] = {
    tcIdentifier, tcNumber, tcPlus, tcMinus, tcString, tcDummy
};

// Tokens that can start an expression
extern const TTokenCode tlExpressionStart[] = {
    tcPlus, tcMinus, tcIdentifier, tcNumber, tcString,
    tcNOT, tcLParen, tcAt, tcDummy
};

// Tokens that can follow an expression
extern const TTokenCode tlExpressionFollow[] = {
    tcComma, tcRParen, tcRBracket, tcColon, tcTHEN, tcTO, tcDOWNTO,
    tcDO, tcOF, tcDummy
};

// Relational operators
extern const TTokenCode tlRelOps[] = {
    tcEqual, tcNe, tcLt, tcGt, tcLe, tcGe, tcDummy
};

// Unary + and - operators
extern const TTokenCode tlUnaryOps[] = {
    tcPlus, tcMinus, tcDummy
};

// Additive operators
extern const TTokenCode tlAddOps[] = {
    tcPlus, tcMinus, tcOR, tcLShift, tcRShift, tcDummy
};

// Multiplicative operators
extern const TTokenCode tlMulOps[] = {
    tcStar, tcSlash, tcDIV, tcMOD, tcAND, tcAmpersand, tcBang, tcDummy
};

// Tokens that can end a program
extern const TTokenCode tlProgramEnd[] = {
    tcPeriod, tcDummy
};

/// Tokens that can start a declaration
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

// Tokens that can start a procedure or function definition
const TTokenCode tlProcFuncStart[] = {
    tcPROCEDURE, tcFUNCTION, tcDummy
};

// Tokens that can follow a procedure or function definition
const TTokenCode tlProcFuncFollow[] = {
    tcSemicolon, tcDummy
};

// Tokens that can follow a routine header
const TTokenCode tlHeaderFollow[] = {
    tcSemicolon, tcDummy
};

// Tokens that can follow a function id in a header
const TTokenCode tlProgProcIdFollow[] = {
    tcLParen, tcColon, tcSemicolon, tcDummy
};

// Tokens that can follow a function id in a header
const TTokenCode tlFuncIdFollow[] = {
    tcLParen, tcColon, tcSemicolon, tcDummy
};

// Tokens than can follow an actual variable parameter
const TTokenCode tlActualVarParmFollow[] = {
    tcComma, tcRParen, tcDummy
};

// Tokens that can follow a formal parameter list
const TTokenCode tlFormalParmsFollow[] = {
    tcRParen, tcSemicolon, tcDummy
};

const TTokenCode tlSubscriptOrFieldStart[] = {
    tcLBracket, tcPeriod, tcDummy
};

// Individual tokens
extern const TTokenCode tlColonEqual[] = {tcColonEqual, tcDummy};
extern const TTokenCode tlDO[] = {tcDO, tcDummy};
extern const TTokenCode tlTHEN[] = {tcTHEN, tcDummy};
extern const TTokenCode tlTODOWNTO[] = {tcTO, tcDOWNTO, tcDummy};
extern const TTokenCode tlOF[] = {tcOF, tcDummy};
extern const TTokenCode tlColon[] = {tcColon, tcDummy};
extern const TTokenCode tlEND[] = {tcEND, tcDummy};

char tokenIn(TTokenCode tc, const TTokenCode *pList) {
    const TTokenCode *pCode;  // ptr to token code in list

    if (!pList) return 0;

    for (pCode = pList; *pCode; ++pCode) {
        if (*pCode == tc) return 1;  // in list
    }

    return 0;  // not in list
}