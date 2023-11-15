/**
 * parser.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Entry point for parser overlay.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <membuf.h>
#include <ast.h>
#include <error.h>
#include <tokenizer.h>
#include <common.h>
#include <parser.h>

CHUNKNUM parserIcode;
TTokenCode parserToken;
TDataValue parserValue;
TDataType parserType;
char parserString[MAX_LINE_LEN + 1];

#if 0
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
extern const TTokenCode tlColonEqual[] = { tcColonEqual, tcDummy };
extern const TTokenCode tlDO[] = { tcDO, tcDummy };
extern const TTokenCode tlTHEN[] = { tcTHEN, tcDummy };
extern const TTokenCode tlTODOWNTO[] = { tcTO, tcDOWNTO, tcDummy };
extern const TTokenCode tlOF[] = { tcOF, tcDummy };
extern const TTokenCode tlColon[] = { tcColon, tcDummy };
extern const TTokenCode tlEND[] = { tcEND, tcDummy };
#endif

CHUNKNUM parse(CHUNKNUM Icode)
{
	parserIcode = Icode;

    setMemBufPos(Icode, 0);
    getToken();
    return parseProgram();
}

void condGetToken(TTokenCode tc, TErrorCode ec) {
	// Get another token only if the current one matches tc
	if (tc == parserToken) {
		getToken();
	}
	else {
		Error(ec);
	}
}

void getToken(void)
{
    char code;

    if (isMemBufAtEnd(parserIcode)) {
        Error(errUnexpectedEndOfFile);
        return;
    }

    readFromMemBuf(parserIcode, &code, 1);
    switch (code) {
    case tzLineNum:
        readFromMemBuf(parserIcode, &currentLineNumber, 2);
        getToken();
        break;

    case tzIdentifier:
    case tzString: {
        char len;
        readFromMemBuf(parserIcode, &len, 1);
        readFromMemBuf(parserIcode, parserString, len);
        parserString[len] = 0;
        parserToken = code == tzIdentifier ? tcIdentifier : tcString;
        break;
    }

    case tzInteger:
    case tzReal: {
        char len;

        if (code == tzInteger) {
            readFromMemBuf(parserIcode, &parserValue.integer, 2);
            parserType = tyInteger;
        }
        else {
            parserType = tyReal;
        }
        parserToken = tcNumber;
        readFromMemBuf(parserIcode, &len, 1);
        readFromMemBuf(parserIcode, parserString, len);
        parserString[len] = 0;
        break;
    }

    case tzToken:
        readFromMemBuf(parserIcode, &parserToken, 1);
        break;
    }
}

void resync(const TTokenCode* pList1,
	const TTokenCode* pList2,
	const TTokenCode* pList3)
{
	TErrorCode errorCode;

	char errorFlag = !tokenIn(parserToken, pList1) &&
		!tokenIn(parserToken, pList2) &&
		!tokenIn(parserToken, pList3);

    if (errorFlag) {
        // Nope.  Flag it as an error
        errorCode = parserToken == tcEndOfFile ?
            errUnexpectedEndOfFile : errUnexpectedToken;
        Error(errorCode);

        // Skip tokens
        while (!tokenIn(parserToken, pList1) &&
            !tokenIn(parserToken, pList2) &&
            !tokenIn(parserToken, pList3) &&
            parserToken != tcPeriod &&
            parserToken != tcEndOfFile) {
            getToken();
        }

        // Flag an unexpected end of file
        if ((parserToken == tcEndOfFile) &&
            (errorCode != errUnexpectedEndOfFile)) {
            Error(errUnexpectedEndOfFile);
        }
    }
}

#if 0
char tokenIn(TTokenCode tc, const TTokenCode* pList)
{
	const TTokenCode* pCode;  // ptr to token code in list

	if (!pList) return 0;

	for (pCode = pList; *pCode; ++pCode) {
		if (*pCode == tc) return 1;  // in list
	}

	return 0;  // not in list
}
#endif

