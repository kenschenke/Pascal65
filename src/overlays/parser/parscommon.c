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

// Tokens that can start a CASE label
extern const TTokenCode tlCaseLabelStart[] = {
    tcIdentifier, tcNumber, tcPlus, tcMinus, tcString, tcDummy
};

// Tokens that can start an expression
extern const TTokenCode tlExpressionStart[] = {
    tcPlus, tcMinus, tcIdentifier, tcNumber, tcString,
    tcNOT, tcLParen, tcDummy
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
    tcPlus, tcMinus, tcOR, tcDummy
};

// Multiplicative operators
extern const TTokenCode tlMulOps[] = {
    tcStar, tcSlash, tcDIV, tcMOD, tcAND, tcDummy
};

// Tokens that can end a program
extern const TTokenCode tlProgramEnd[] = {
    tcPeriod, tcDummy
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