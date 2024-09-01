/**
 * parsexpr.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for parsing expressions.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <ast.h>
#include <common.h>
#include <string.h>

static CHUNKNUM parseArrayLiteral(void);

static CHUNKNUM parseArrayLiteral(void)
{
	struct expr _expr;
	CHUNKNUM arrayExpr, exprChunk, lastExpr = 0;

	arrayExpr = exprCreate(EXPR_ARRAY_LITERAL, 0, 0, 0, 0);

	// Parse comma-separated list of literals until a right paren

	while (parserToken != tcRParen) {
		exprChunk = parseExpression(1);
		if (lastExpr) {
			retrieveChunk(lastExpr, &_expr);
			_expr.right = exprChunk;
			storeChunk(lastExpr, &_expr);
		} else {
			retrieveChunk(arrayExpr, &_expr);
			_expr.left = exprChunk;
			storeChunk(arrayExpr, &_expr);
		}
		lastExpr = exprChunk;

		if (parserToken == tcComma) {
			getToken();
		} else if (parserToken != tcRParen) {
			Error(errUnexpectedToken);
			resync(tlExpressionStart, 0, 0);
		}
	}

	return arrayExpr;
}

CHUNKNUM parseExpression(char isVarInit)
{
	CHUNKNUM exprChunk = parseSimpleExpression(isVarInit);

	if (tokenIn(parserToken, tlRelOps)) {
		expr_t et;
		switch (parserToken) {
		case tcLt: et = EXPR_LT; break;
		case tcLe: et = EXPR_LTE; break;
		case tcGt: et = EXPR_GT; break;
		case tcGe: et = EXPR_GTE; break;
		case tcNe: et = EXPR_NE; break;
		case tcEqual: et = EXPR_EQ; break;
		}
		getToken();
		exprChunk = exprCreate(et, exprChunk, parseSimpleExpression(isVarInit), 0, 0);
	}

	resync(tlExpressionFollow, tlStatementFollow, tlStatementStart);

	return exprChunk;
}

CHUNKNUM parseFactor(char isVarInit)
{
	char unaryNeg = 0;
	CHUNKNUM exprChunk = 0;

	if (parserToken == tcMinus) {
		unaryNeg = 1;
		getToken();
	}

	switch (parserToken) {
	case tcIdentifier: {
		CHUNKNUM nameChunk = name_create(parserString);
		getToken();
		if (parserToken == tcLParen) {
			// Function / procecure call
			exprChunk = parseSubroutineCall(nameChunk,
				strcmp(parserString, "writestr") == 0 ? 1 : 0);
		}
		else {
			return parseVariable(nameChunk);
		}
		break;
	}

	case tcNumber: {
		char exprKind;
		if (parserType == tyReal) {
			parserValue.stringChunkNum = 0;
			copyRealString(parserString, &parserValue.stringChunkNum);
			exprKind = EXPR_REAL_LITERAL;
		} else if (parserType == tyByte) {
			exprKind = EXPR_BYTE_LITERAL;
		} else if (parserType == tyWord) {
			exprKind = EXPR_WORD_LITERAL;
		} else {
			exprKind = EXPR_DWORD_LITERAL;
		}
		exprChunk = exprCreate(exprKind, 0, 0, 0, &parserValue);
		getToken();
		break;
	}

	case tcTRUE:
	case tcFALSE:
		parserValue.integer = parserToken == tcTRUE ? 1 : 0;
		exprChunk = exprCreate(EXPR_BOOLEAN_LITERAL, 0, 0, 0, &parserValue);
		getToken();
		break;

	case tcNIL:
		parserValue.integer = 0;
		exprChunk = exprCreate(EXPR_WORD_LITERAL, 0, 0, 0, &parserValue);
		getToken();
		break;

	case tcString:
		if (strlen(parserString) == 3) {
			parserValue.character = parserString[1];
			exprChunk = exprCreate(EXPR_CHARACTER_LITERAL, 0, 0, 0, &parserValue);
		}
		else {
			parserValue.stringChunkNum = 0;
			copyQuotedString(parserString, &parserValue.stringChunkNum);
			exprChunk = exprCreate(EXPR_STRING_LITERAL, 0, 0, 0, &parserValue);
		}
		getToken();
		break;

	case tcNOT:
		getToken();
		return exprCreate(EXPR_NOT, parseFactor(0), 0, 0, 0);
	
	case tcAt:
		getToken();
		return exprCreate(EXPR_ADDRESS_OF, parseFactor(0), 0, 0, 0);
		break;

	case tcLParen: {
		CHUNKNUM expr;
		getToken();
		if (isVarInit) {
			// Array literal
			expr = parseArrayLiteral();
		} else {
			// Parenthesized subexpression: call parseExpression recursively
			expr = parseExpression(0);
		}
		if (parserToken == tcRParen) {
			getToken();
			return expr;
		}
		else {
			Error(errMissingRightParen);
		}
		break;
	}

	default:
		Error(errInvalidExpression);
		break;
	}

	if (unaryNeg) {
		struct expr _expr;
		retrieveChunk(exprChunk, &_expr);
		_expr.neg = 1;
		storeChunk(exprChunk, &_expr);
	}

	return exprChunk;
}

CHUNKNUM parseField(CHUNKNUM expr)
{
	CHUNKNUM rootExpr = 0, lastExpr = 0;

	while (parserToken == tcPeriod) {
		CHUNKNUM newExpr;

		getToken();

		// Create a new FIELD expression.  The left is the name expression
		// for the record.
		newExpr = exprCreate(EXPR_FIELD, lastExpr == 0 ? expr : lastExpr,
			exprCreate(EXPR_NAME, 0, 0, name_create(parserString), 0), 0, 0);

		rootExpr = newExpr;
		lastExpr = newExpr;

		getToken();
	}

	return rootExpr;
}

CHUNKNUM parseSimpleExpression(char isVarInit)
{
	CHUNKNUM exprChunk;
	char unaryNeg = 0;

	exprChunk = parseTerm(isVarInit);
	if (unaryNeg) {
		struct expr _expr;
		retrieveChunk(exprChunk, &_expr);
		_expr.neg = 1;
		storeChunk(exprChunk, &_expr);
	}

	while (tokenIn(parserToken, tlAddOps)) {
		expr_t et;
		switch (parserToken) {
		case tcPlus: et = EXPR_ADD; break;
		case tcMinus: et = EXPR_SUB; break;
		case tcOR: et = EXPR_OR; break;
		case tcLShift: et = EXPR_BITWISE_LSHIFT; break;
		case tcRShift: et = EXPR_BITWISE_RSHIFT; break;
		}

		getToken();
		exprChunk = exprCreate(et, exprChunk, parseTerm(isVarInit), 0, 0);
	}

	return exprChunk;
}

CHUNKNUM parseSubscripts(CHUNKNUM expr)
{
	// Loop to parse a list of subscripts separated by commas.
	do {
		getToken();
		expr = exprCreate(EXPR_SUBSCRIPT, expr, parseExpression(0), 0, 0);
	} while (parserToken == tcComma);

	// ]
	condGetToken(tcRBracket, errMissingRightBracket);

	return expr;
}

CHUNKNUM parseTerm(char isVarInit)
{
	expr_t ec;
	CHUNKNUM exprChunk;

	exprChunk = parseFactor(isVarInit);

	if (tokenIn(parserToken, tlMulOps)) {
		switch (parserToken) {
		case tcStar: ec = EXPR_MUL; break;
		case tcSlash: ec = EXPR_DIV; break;
		case tcDIV: ec = EXPR_DIVINT; break;
		case tcMOD: ec = EXPR_MOD; break;
		case tcAND: ec = EXPR_AND; break;
		case tcAmpersand: ec = EXPR_BITWISE_AND; break;
		case tcBang: ec = EXPR_BITWISE_OR; break;
		}

		getToken();
		return exprCreate(ec, exprChunk, parseTerm(isVarInit), 0, 0);
	}
	
	return exprChunk;
}

CHUNKNUM parseVariable(CHUNKNUM nameChunk)
{
	char doneFlag = 0;
	CHUNKNUM rootExpr = exprCreate(EXPR_NAME, 0, 0, nameChunk, 0);

	// getToken();

	// [ or . : Loop to parse any subscripts and fields.
	do {
		switch (parserToken) {
		case tcLBracket:
			rootExpr = parseSubscripts(rootExpr);
			break;

		case tcPeriod:
			rootExpr = parseField(rootExpr);
			break;
		
		case tcUpArrow:
			rootExpr = exprCreate(EXPR_POINTER, rootExpr, 0, 0, 0);
			getToken();
			break;

		default:
			doneFlag = 1;
			break;
		}
	} while (!doneFlag);

	// This function returns an expression node.
	// It can be one of:
	//
	// EXPR_NAME - just the variable itself
	//
	// EXPR_SUBSCRIPT - an array reference
	//
	// EXPR_FIELD - a record field reference
	//
	// It figures this out by looking at the token after the
	// variable.  If it's a left bracket, the variable is an array
	// and the subscripts must be parsed.  If it's a period the
	// variable is a record and the field(s) are parsed.

	// NOTE: The function should maintain an empty list of subscripts
	// that gets appended to as parsing continues within the function.
	// When a left bracket is detected, call parseSubscripts.
	// It runs until it sees a right bracket and will parse additional
	// subscripts separated by commas.  If more left brackets are found
	// it should append those to the current subscript chain so:
	// arr[1,2,3] is equivalent to arr[1][2][3] or a[1,2][3].

	return rootExpr;
}
