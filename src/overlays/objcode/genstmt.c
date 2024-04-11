/**
 * genstmt.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Generate program statements in object code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>

#include <ast.h>
#include <asm.h>
#include <codegen.h>
#include <common.h>
#include <string.h>
#include <int16.h>

static void genCaseStmt(struct stmt* pStmt);
static void genForLoop(struct stmt* pStmt);
static void genIfStmt(struct stmt* pStmt, CHUNKNUM chunkNum);
static void genRepeatStmt(struct stmt* pStmt);
static void genWhileStmt(struct stmt* pStmt);

static void genCaseStmt(struct stmt* pStmt)
{
	int num = currentLineNumber;
	int branch = 1;
	struct expr _expr;
	struct type exprType, labelType;
	struct stmt labelStmt;
	char branchLabel[15], bodyLabel[15], nextLabel[15], endLabel[15];
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

		linkAddressSet(branchLabel, codeOffset);

		// Loop through the labels for this case branch
		exprChunk = labelStmt.expr;
		while (exprChunk)
		{
			retrieveChunk(exprChunk, &_expr);
			retrieveChunk(_expr.evalType, &labelType);

			genExpr(pStmt->expr, 1, 0, 0);
			genExpr(exprChunk, 1, 0, 0);
			genTwo(LDA_IMMEDIATE, exprType.kind);	// data type of case expression
			genTwo(LDX_IMMEDIATE, labelType.kind);	// data type of case label
			genTwo(LDY_IMMEDIATE, EXPR_EQ);			// perform equality operation
			genThreeAddr(JSR, RT_COMP);				// do the comparison
			genThreeAddr(JSR, RT_POPEAX);			// pop the results off the stack
			genTwo(CMP_IMMEDIATE, 0);
			genTwo(BEQ, 3);							// branch to next label if not equal

			// If the comparison was equal, jump to the body for this case branch
			linkAddressLookup(bodyLabel, codeOffset + 1, 0, LINKADDR_BOTH);
			genThreeAddr(JMP, 0);

			exprChunk = _expr.right;
		}

		if (labelStmt.next) {
			linkAddressLookup(nextLabel, codeOffset + 1, 0, LINKADDR_BOTH);
			genThreeAddr(JMP, 0);
		}
		else {
			linkAddressLookup(endLabel, codeOffset + 1, 0, LINKADDR_BOTH);
			genThreeAddr(JMP, 0);
		}

		linkAddressSet(bodyLabel, codeOffset);
		genStmts(labelStmt.body);
		if (labelStmt.next) {
			linkAddressLookup(endLabel, codeOffset + 1, 0, LINKADDR_BOTH);
			genThreeAddr(JMP, 0);
		}

		++branch;
		labelChunk = labelStmt.next;
	}

	linkAddressSet(endLabel, codeOffset);
}

static void genForLoop(struct stmt* pStmt)
{
	struct expr _expr;
	struct type controlType, targetType;
	CHUNKNUM controlExpr;
	unsigned short startOffset;
	char endLabel[15];

	strcpy(endLabel, "FOR");
	strcat(endLabel, formatInt16(pStmt->body));

	// Look up the control variable
	retrieveChunk(pStmt->init_expr, &_expr);
	// Should be an assignment with the control variable on the left.
	controlExpr = _expr.left;
	retrieveChunk(_expr.left, &_expr);
	retrieveChunk(_expr.evalType, &controlType);

	// Emit the initialization expression
	genExpr(pStmt->init_expr, 1, 0, 0);

	// Initialize the start of each iteration
	startOffset = codeBase + codeOffset;
	// Push the value of the control variable onto the stack
	genExpr(controlExpr, 1, 0, 0);

	// Push the target value onto the stack
	genExpr(pStmt->to_expr, 1, 0, 0);

	// Compare the control value to the target value
	retrieveChunk(pStmt->to_expr, &_expr);
	retrieveChunk(_expr.evalType, &targetType);
	genTwo(LDA_IMMEDIATE, controlType.kind);
	genTwo(LDX_IMMEDIATE, targetType.kind);
	genTwo(LDY_IMMEDIATE, pStmt->isDownTo ? EXPR_LT : EXPR_GT);
	genThreeAddr(JSR, RT_COMP);
	genThreeAddr(JSR, RT_POPEAX);
	genTwo(CMP_IMMEDIATE, 0);
	// If the target value has not been reached, jump to the body code
	genTwo(BEQ, 3);		// JMP + two_byte_addr = 3
	linkAddressLookup(endLabel, codeOffset + 1, 0, LINKADDR_BOTH);
	// Target value has been reached.  Jump to end address.
	genThreeAddr(JMP, 0);

	genStmts(pStmt->body);

	// Increment (or decrement) the control variable
	genExpr(controlExpr, 1, 0, 0);
	genTwo(LDA_IMMEDIATE, controlType.kind);
	genThreeAddr(JSR, pStmt->isDownTo ? RT_PRED : RT_SUCC);
	genThreeAddr(JSR, controlType.size == 2 ? RT_STOREINTSTACK : RT_STOREINT32STACK);

	// Jump back up and check the control variable for the next iteration
	genThreeAddr(JMP, startOffset);
	linkAddressSet(endLabel, codeOffset);
}

static void genIfStmt(struct stmt* pStmt, CHUNKNUM chunkNum)
{
	char elseLabel[15], endLabel[15];

	strcpy(elseLabel, "ELSE");
	strcat(elseLabel, formatInt16(chunkNum));

	strcpy(endLabel, "ENDIF");
	strcat(endLabel, formatInt16(chunkNum));

	// Evaluate the expression
	genExpr(pStmt->expr, 1, 0, 0);
	genThreeAddr(JSR, RT_POPEAX);
	genTwo(AND_IMMEDIATE, 1);

	// Dump the true block
	genTwo(BNE, 3);		// JMP + two_byte_address = 3
	if (pStmt->else_body) {
		linkAddressLookup(elseLabel, codeOffset + 1, 0, LINKADDR_BOTH);
		genThreeAddr(JMP, 0);
	}
	else {
		linkAddressLookup(endLabel, codeOffset + 1, 0, LINKADDR_BOTH);
		genThreeAddr(JMP, 0);
	}

	// True
	genStmts(pStmt->body);

	// Dump the else block
	if (pStmt->else_body) {
		linkAddressLookup(endLabel, codeOffset + 1, 0, LINKADDR_BOTH);
		genThreeAddr(JMP, 0);
		linkAddressSet(elseLabel, codeOffset);
		genStmts(pStmt->else_body);
	}

	linkAddressSet(endLabel, codeOffset);
}

static void genRepeatStmt(struct stmt* pStmt)
{
	unsigned short startAddr;
	int num = currentLineNumber;

	startAddr = codeBase + codeOffset;

	genStmts(pStmt->body);

	// Evaluate the expression
	genExpr(pStmt->expr, 1, 0, 0);
	genThreeAddr(JSR, RT_POPEAX);
	genTwo(AND_IMMEDIATE, 1);
	genTwo(BNE, 3);		// JMP + address_two_bytes = 3
	genThreeAddr(JMP, startAddr);
}

void genStmts(CHUNKNUM chunkNum)
{
	struct stmt _stmt;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_stmt);
		currentLineNumber = _stmt.lineNumber;

#if 0
		genOne(NOP);
		genOne(PHA);
		genTwo(LDA_IMMEDIATE, (char)_stmt.lineNumber);
		genOne(PLA);
		genOne(NOP);
#endif

		switch (_stmt.kind) {
		case STMT_EXPR:
			genExpr(_stmt.expr, 0, 0, 0);
			break;

		case STMT_IF_ELSE:
			genIfStmt(&_stmt, chunkNum);
			break;

		case STMT_FOR:
			genForLoop(&_stmt);
			break;

		case STMT_WHILE:
			genWhileStmt(&_stmt);
			break;

		case STMT_REPEAT:
			genRepeatStmt(&_stmt);
			break;

		case STMT_CASE:
			genCaseStmt(&_stmt);
			break;
		}

		chunkNum = _stmt.next;
	}
}

static void genWhileStmt(struct stmt* pStmt)
{
	unsigned short startAddr;
	char endLabel[15];

	strcpy(endLabel, "ENDWHILE");
	strcat(endLabel, formatInt16(currentLineNumber));
	startAddr = codeBase + codeOffset;

	// Evaluate the expression
	genExpr(pStmt->expr, 1, 0, 0);
	genThreeAddr(JSR, RT_POPEAX);
	genTwo(AND_IMMEDIATE, 1);
	genTwo(BNE, 3);	// JMP + two_address_bytes = 3
	linkAddressLookup(endLabel, codeOffset + 1, 0, LINKADDR_BOTH);
	genThreeAddr(JMP, 0);	// jmp ENDWHILE

	genStmts(pStmt->body);
	genThreeAddr(JMP, startAddr);

	linkAddressSet(endLabel, codeOffset);
}
