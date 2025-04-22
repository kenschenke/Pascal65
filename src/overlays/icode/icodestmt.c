/**
 * icodestmt.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Intermediate Code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <icode.h>
#include <chunks.h>
#include <misc.h>
#include <ast.h>
#include <common.h>
#include <string.h>
#include <int16.h>

static void icodeCaseStmt(struct stmt* pStmt);
static void icodeForLoop(struct stmt* pStmt);
static void icodeIfStmt(struct stmt* pStmt, CHUNKNUM chunkNum);
static void icodeRepeatStmt(struct stmt* pStmt, CHUNKNUM chunkNum);
static void icodeWhileStmt(struct stmt* pStmt, CHUNKNUM chunkNum);

static void icodeCaseStmt(struct stmt* pStmt)
{
	int num = currentLineNumber;
	int branch = 1;
	struct expr _expr;
	struct type exprType, labelType;
	struct stmt labelStmt;
	char branchLabel[15], bodyLabel[25], nextLabel[15], endLabel[15];
	CHUNKNUM exprChunk, labelChunk = pStmt->body;

	retrieveChunk(pStmt->expr, &_expr);
	retrieveChunk(_expr.evalType, &exprType);

	// Loop through the case branches
	while (labelChunk) {
		retrieveChunk(labelChunk, &labelStmt);

		strcpy(branchLabel, "CASE");
		strcat(branchLabel, formatInt16(num));
		strcat(branchLabel, "_");
		strcat(branchLabel, formatInt16(branch));

		strcpy(bodyLabel, "CASE");
		strcat(bodyLabel, formatInt16(num));
		strcat(bodyLabel, "_");
		strcat(bodyLabel, formatInt16(branch));
		strcat(bodyLabel, "_");
		strcat(bodyLabel, "BODY");

		strcpy(nextLabel, "CASE");
		strcat(nextLabel, formatInt16(num));
		strcat(nextLabel, "_");
		strcat(nextLabel, formatInt16(branch + 1));

		strcpy(endLabel, "ENDCASE");
		strcat(endLabel, formatInt16(num));

		icodeWriteUnaryLabel(IC_LOC, branchLabel);

		// Loop through the labels for this case branch
		exprChunk = labelStmt.expr;
		while (exprChunk)
		{
			retrieveChunk(exprChunk, &_expr);
			retrieveChunk(_expr.evalType, &labelType);

			icodeExprRead(pStmt->expr);
			icodeExprRead(exprChunk);
			icodeWriteBinaryShort(IC_EQU, exprType.kind, labelType.kind);
			icodeWriteUnaryLabel(IC_BIT, bodyLabel);

			exprChunk = _expr.right;
		}

		if (labelStmt.next) {
			icodeWriteUnaryLabel(IC_BRA, nextLabel);
		}
		else {
			icodeWriteUnaryLabel(IC_BRA, endLabel);
		}

		icodeWriteUnaryLabel(IC_LOC, bodyLabel);
		icodeStmts(labelStmt.body);
		if (labelStmt.next) {
			icodeWriteUnaryLabel(IC_BRA, endLabel);
		}

		++branch;
		labelChunk = labelStmt.next;
	}

	icodeWriteUnaryLabel(IC_LOC, endLabel);
}

static void icodeForLoop(struct stmt* pStmt)
{
	struct expr _expr;
	struct symbol sym;
	struct type controlType; //, targetType;
	CHUNKNUM controlExpr;
	char loopLabel[15], endLabel[15], controlKind, targetKind;

	strcpy(loopLabel, "FOR");
	strcat(loopLabel, formatInt16(pStmt->body));

	strcpy(endLabel, "ENDFOR");
	strcat(endLabel, formatInt16(pStmt->body));

	// Look up the control variable
	retrieveChunk(pStmt->init_expr, &_expr);
	// Should be an assignment with the control variable on the left.
	controlExpr = _expr.left;
	retrieveChunk(_expr.left, &_expr);
	retrieveChunk(_expr.evalType, &controlType);
	retrieveChunk(_expr.node, &sym);

	// Emit the initialization expression
	icodeExprRead(pStmt->init_expr);

	// Initialize the start of each iteration
	icodeWriteUnaryLabel(IC_LOC, loopLabel);
	// Push the value of the control variable onto the stack
	controlKind = icodeExprRead(controlExpr);

	// Push the target value onto the stack
	targetKind = icodeExprRead(pStmt->to_expr);

	// Compare the control value to the target value
	retrieveChunk(pStmt->to_expr, &_expr);
	// retrieveChunk(_expr.evalType, &targetType);
	icodeWriteBinaryShort(pStmt->isDownTo ? IC_LST : IC_GRT,
		controlKind, targetKind);
	icodeWriteUnaryLabel(IC_BIT, endLabel);

	icodeStmts(pStmt->body);

	// Increment (or decrement) the control variable
	icodeExprRead(controlExpr);
	icodeWriteUnaryShort(pStmt->isDownTo ? IC_PRE : IC_SUC, controlKind);
	icodeWriteUnary(IC_PSH, icodeOperVar(1,
		(controlType.flags & TYPE_FLAG_ISBYREF) ? IC_VVW : IC_VDW,
			controlKind, sym.level, sym.offset));
	icodeWriteBinaryShort(IC_SET, controlKind, controlKind);

	// Jump back up and check the control variable for the next iteration
	icodeWriteUnaryLabel(IC_BRA, loopLabel);
	icodeWriteUnaryLabel(IC_LOC, endLabel);
}

static void icodeIfStmt(struct stmt* pStmt, CHUNKNUM chunkNum)
{
	char elseLabel[15], endLabel[15];
	struct icode_operand *pFalseLabel;

	strcpy(elseLabel, "ELSE");
	strcat(elseLabel, formatInt16(chunkNum));

	strcpy(endLabel, "ENDIF");
	strcat(endLabel, formatInt16(chunkNum));

	// Evaluate the expression
	icodeExprRead(pStmt->expr);
	if (pStmt->else_body) {
		pFalseLabel = icodeOperLabel(1, elseLabel);
	} else {
		pFalseLabel = icodeOperLabel(1, endLabel);
	}
	icodeWriteUnary(IC_BIF, pFalseLabel);

	icodeStmts(pStmt->body);
	if (pStmt->else_body) {
		icodeWriteUnaryLabel(IC_BRA, endLabel);
		icodeWriteUnaryLabel(IC_LOC, elseLabel);
		icodeStmts(pStmt->else_body);
	}

	icodeWriteUnaryLabel(IC_LOC, endLabel);
}

static void icodeRepeatStmt(struct stmt* pStmt, CHUNKNUM chunkNum)
{
	char label[15];

	strcpy(label, "REPEAT");
	strcat(label, formatInt16(chunkNum));
	icodeWriteUnaryLabel(IC_LOC, label);
	icodeStmts(pStmt->body);

	// Evaluate the expression
	icodeExprRead(pStmt->expr);
	icodeWriteUnaryLabel(IC_BIF, label);
}

void icodeStmts(CHUNKNUM chunkNum)
{
	struct stmt _stmt;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_stmt);
		currentLineNumber = _stmt.lineNumber;

		icodeWriteUnary(IC_LIN, icodeOperWord(1, currentLineNumber));

		switch (_stmt.kind) {
		case STMT_EXPR:
			icodeExpr(_stmt.expr, 0);
			break;

		case STMT_IF_ELSE:
			icodeIfStmt(&_stmt, chunkNum);
			break;

		case STMT_FOR:
			icodeForLoop(&_stmt);
			break;

		case STMT_WHILE:
			icodeWhileStmt(&_stmt, chunkNum);
			break;

		case STMT_REPEAT:
			icodeRepeatStmt(&_stmt, chunkNum);
			break;

		case STMT_CASE:
			icodeCaseStmt(&_stmt);
			break;
		}

		chunkNum = _stmt.next;
	}
}

static void icodeWhileStmt(struct stmt* pStmt, CHUNKNUM chunkNum)
{
	char startLabel[15], endLabel[15];

	strcpy(startLabel, "WHILE");
	strcat(startLabel, formatInt16(chunkNum));

	strcpy(endLabel, "ENDWHILE");
	strcat(endLabel, formatInt16(chunkNum));

	icodeWriteUnaryLabel(IC_LOC, startLabel);

	// Evaluate the expression
	icodeExprRead(pStmt->expr);
	icodeWriteUnaryLabel(IC_BIF, endLabel);

	icodeStmts(pStmt->body);
	icodeWriteUnaryLabel(IC_BRA, startLabel);

	icodeWriteUnaryLabel(IC_LOC, endLabel);
}

