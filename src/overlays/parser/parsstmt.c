/**
 * parsstmt.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for parsing statements.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <string.h>
#include <parser.h>
#include <ast.h>
#include <common.h>

CHUNKNUM parseAssignment(CHUNKNUM nameChunk)
{
	CHUNKNUM exprChunk, target = parseVariable(nameChunk);

	// :=
	resync(tlColonEqual, tlExpressionStart, 0);
	condGetToken(tcColonEqual, errMissingColonEqual);

	// <expr>
	exprChunk = parseExpression();

	return exprCreate(EXPR_ASSIGN, target, exprChunk, 0, 0);
}

CHUNKNUM parseCASE(void)
{
	char caseBranchFlag;
	CHUNKNUM exprChunk, caseChunk = 0, firstCase = 0, lastCase = 0;
	struct stmt _stmt;

	// CASE
	getToken();

	// <expr>
	exprChunk = parseExpression();

	// OF
	resync(tlOF, tlCaseLabelStart, 0);
	condGetToken(tcOF, errMissingOF);

	// Loop to parse CASE branches
	caseBranchFlag = tokenIn(parserToken, tlCaseLabelStart);
	while (caseBranchFlag) {
		if (tokenIn(parserToken, tlCaseLabelStart)) {
			caseChunk = parseCaseBranch();
		}
		else {
			caseChunk = 0;
		}

		if (firstCase) {
			retrieveChunk(lastCase, &_stmt);
			_stmt.next = caseChunk;
			storeChunk(lastCase, &_stmt);
		}
		else {
			firstCase = caseChunk;
		}
		lastCase = caseChunk;

		if (parserToken == tcSemicolon) {
			caseBranchFlag = 1;
			getToken();
		}
		else if (tokenIn(parserToken, tlCaseLabelStart)) {
			Error(errMissingSemicolon);
			caseBranchFlag = 1;
		}
		else {
			caseBranchFlag = 0;
		}
	}

	// END
	resync(tlEND, tlStatementStart, 0);
	condGetToken(tcEND, errMissingEND);

	return stmtCreate(STMT_CASE, exprChunk, firstCase);
}

CHUNKNUM parseCaseBranch(void)
{
	char caseLabelFlag;
	struct expr _expr;
	CHUNKNUM firstLabel = 0, labelChunk = 0, lastLabel = 0;

	// <case-label-list>
	do {
		labelChunk = parseCaseLabel();
		if (firstLabel) {
			retrieveChunk(lastLabel, &_expr);
			_expr.right = labelChunk;
			storeChunk(lastLabel, &_expr);
		}
		else {
			firstLabel = labelChunk;
		}
		lastLabel = labelChunk;
		if (parserToken == tcComma) {
			// Saw comma, look for another case label
			getToken();
			if (tokenIn(parserToken, tlCaseLabelStart)) caseLabelFlag = 1;
			else {
				Error(errMissingConstant);
				caseLabelFlag = 0;
			}
		}
		else {
			caseLabelFlag = 0;
		}
	} while (caseLabelFlag);

	// :
	resync(tlColon, tlStatementStart, 0);
	condGetToken(tcColon, errMissingColon);

	return stmtCreate(STMT_CASE_LABEL, firstLabel, parseStatement());
}

CHUNKNUM parseCaseLabel(void)
{
	struct expr _expr;
	char signFlag = 0;  // non-zero if unary sign, else zero
	CHUNKNUM exprChunk;

	// Unary + or -
	if (tokenIn(parserToken, tlUnaryOps)) {
		signFlag = 1;
		getToken();
	}

	if (parserToken == tcIdentifier && signFlag) {
		Error(errInvalidConstant);
	}

	exprChunk = parseExpression();
	retrieveChunk(exprChunk, &_expr);
	switch (_expr.kind) {
	case EXPR_INTEGER_LITERAL:
		if (signFlag) {
			_expr.value.integer = -_expr.value.integer;
			storeChunk(exprChunk, &_expr);
		}
		break;
	}

	return exprChunk;
}

CHUNKNUM parseCompound(void)
{
	CHUNKNUM code;

	getToken();
	
	code = parseStatementList(tcEND);

	condGetToken(tcEND, errMissingEND);

	return code;
}

CHUNKNUM parseFOR(void)
{
	char isDownTo;
	struct stmt _stmt;
	CHUNKNUM controlChunk = 0, initExpr, exitExpr, stmtChunk;

	// FOR
	getToken();

	// <id>
	if (parserToken == tcIdentifier) {
		controlChunk = exprCreate(EXPR_NAME, 0, 0, name_create(parserString), 0);
		getToken();
	}
	else {
		Error(errMissingIdentifier);
	}

	// :=
	resync(tlColonEqual, tlExpressionStart, 0);
	condGetToken(tcColonEqual, errMissingColonEqual);

	// <init-expr>
	initExpr = exprCreate(EXPR_ASSIGN, controlChunk, parseExpression(), 0, 0);

	// TO or DOWNTO
	resync(tlTODOWNTO, tlExpressionStart, 0);
	if (parserToken == tcTO) {
		isDownTo = 0;
	}
	else if (parserToken == tcDOWNTO) {
		isDownTo = 1;
	}
	else {
		Error(errMissingTOorDOWNTO);
	}
	getToken();

	// <exit-expr>
	exitExpr = parseExpression();

	// DO
	resync(tlDO, tlStatementStart, 0);
	condGetToken(tcDO, errMissingDO);

	// <stmt>
	stmtChunk = stmtCreate(STMT_FOR, 0, parseStatement());
	retrieveChunk(stmtChunk, &_stmt);
	_stmt.init_expr = initExpr;
	_stmt.to_expr = exitExpr;
	_stmt.isDownTo = isDownTo;
	storeChunk(stmtChunk, &_stmt);
	return stmtChunk;
}

CHUNKNUM parseIF(void)
{
	struct stmt _stmt;
	CHUNKNUM exprChunk, trueChunk, falseChunk=0, stmtChunk;

	// IF
	getToken();

	// <expr>
	exprChunk = parseExpression();

	// THEN
	resync(tlTHEN, tlStatementStart, 0);
	condGetToken(tcTHEN, errMissingTHEN);

	// <stmt-if-true>
	trueChunk = parseStatement();

	if (parserToken == tcELSE) {
		// ELSE
		getToken();
		// <stmt-if-false>
		falseChunk = parseStatement();
	}

	stmtChunk = stmtCreate(STMT_IF_ELSE, exprChunk, trueChunk);
	retrieveChunk(stmtChunk, &_stmt);
	_stmt.else_body = falseChunk;
	storeChunk(stmtChunk, &_stmt);
	return stmtChunk;
}

CHUNKNUM parseREPEAT(void)
{
	CHUNKNUM stmtList;

	// REPEAT
	getToken();

	// <stmt-list>
	stmtList = parseStatementList(tcUNTIL);

	// UNTIL
	condGetToken(tcUNTIL, errMissingUNTIL);

	// <stmt>
	return stmtCreate(STMT_REPEAT, parseExpression(), stmtList);
}

CHUNKNUM parseStatement(void)
{
	CHUNKNUM stmtChunk = 0;

	switch (parserToken) {
		case tcIdentifier: {
			CHUNKNUM nameChunk = name_create(parserString);
			getToken();
			if (parserToken == tcLParen || parserToken == tcSemicolon) {
				// procedure/function call
				char isWriteWriteln =
					(strcmp(parserString, "write") == 0 ||
						strcmp(parserString, "writeln") == 0) ? 1 : 0;
				stmtChunk = stmtCreate(STMT_EXPR, parseSubroutineCall(nameChunk, isWriteWriteln),
					0);
			}
			else {
				// assignment
				stmtChunk = stmtCreate(STMT_EXPR, parseAssignment(nameChunk), 0);
			}
			break;
		}

		case tcBEGIN:
			stmtChunk = parseCompound();
			break;

		case tcIF:
			stmtChunk = parseIF();
			break;

		case tcFOR:
			stmtChunk = parseFOR();
			break;

		case tcREPEAT:
			stmtChunk = parseREPEAT();
			break;

		case tcWHILE:
			stmtChunk = parseWHILE();
			break;

		case tcCASE:
			stmtChunk = parseCASE();
			break;
	}

	if (parserToken != tcEndOfFile) {
		resync(tlStatementFollow, tlStatementStart, 0);
	}

	return stmtChunk;
}

CHUNKNUM parseStatementList(TTokenCode terminator)
{
	struct stmt _stmt;
	CHUNKNUM lastStmt, firstStmt = 0;

	do {
		CHUNKNUM stmtChunk = parseStatement();

		if (tokenIn(parserToken, tlStatementStart)) {
			Error(errMissingSemicolon);
		}
		else if (tokenIn(parserToken, tlStatementListNotAllowed))
			Error(errUnexpectedToken);
		else while (parserToken == tcSemicolon) {
			getToken();
		}

		if (!firstStmt) {
			firstStmt = stmtChunk;
		}
		else {
			retrieveChunk(lastStmt, &_stmt);
			_stmt.next = stmtChunk;
			storeChunk(lastStmt, &_stmt);
		}
		lastStmt = stmtChunk;
	} while (parserToken != terminator && parserToken != tcEndOfFile);

	return firstStmt;
}

CHUNKNUM parseWHILE(void)
{
	CHUNKNUM exprChunk;

	// WHILE
	getToken();

	// <expr>
	exprChunk = parseExpression();

	// DO
	resync(tlDO, tlStatementStart, 0);
	condGetToken(tcDO, errMissingDO);

	// <stmt>
	return stmtCreate(STMT_WHILE, exprChunk, parseStatement());
}
