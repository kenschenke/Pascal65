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
	char first = 1;
	struct expr _expr;
	struct type exprType;
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

			if (first) {
				genExpr(pStmt->expr, 1, 0, 0);
			}
			genExpr(exprChunk, 1, 0, 0);

			if (exprType.kind == TYPE_INTEGER || exprType.kind == TYPE_ENUMERATION || exprType.kind == TYPE_CHARACTER) {
				genThreeAddr(JSR, RT_POPTOINTOP2);
				if (first) {
					genThreeAddr(JSR, RT_POPTOINTOP1);
				}
				genThreeAddr(JSR, RT_EQINT16);
				genTwo(BEQ, 3);		// JMP + two_byte_address = 3
				linkAddressLookup(bodyLabel, codeOffset + 1, 0, LINKADDR_BOTH);
				genThreeAddr(JMP, 0);
			}

			exprChunk = _expr.right;
			first = 0;
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
	CHUNKNUM controlExpr;
	int num = currentLineNumber;
	unsigned short startOffset;

	// Look up the control variable
	retrieveChunk(pStmt->init_expr, &_expr);
	// Should be an assignment with the control variable on the left.
	controlExpr = _expr.left;

	// Emit the initialization expression
	genExpr(pStmt->init_expr, 1, 0, 0);

	startOffset = codeBase + codeOffset;
	genStmts(pStmt->body);

	// Increment (or decrement) the control variable
	genExpr(controlExpr, 0, 0, 0);
	genThreeAddr(JSR, RT_READINT);
	genTwo(STA_ZEROPAGE, ZP_INTOP1L);
	genTwo(STX_ZEROPAGE, ZP_INTOP1H);
	if (pStmt->isDownTo) {
		genTwo(DEC_ZEROPAGE, ZP_INTOP1L);
		genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
		genTwo(CMP_IMMEDIATE, 0xff);
		genTwo(BNE, 2);		// dec + zeropage = 2
		genTwo(DEC_ZEROPAGE, ZP_INTOP1H);
	}
	else {
		genTwo(INC_ZEROPAGE, ZP_INTOP1L);
		genTwo(BNE, 2);		// inc + zeropage = 2
		genTwo(INC_ZEROPAGE, ZP_INTOP1H);
	}
	// store intOp1 back in ptr1
	genTwo(LDY_IMMEDIATE, 0);
	genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
	genTwo(STA_ZPINDIRECT, ZP_PTR1L);
	genOne(INY);
	genTwo(LDA_ZEROPAGE, ZP_INTOP1H);
	genTwo(STA_ZPINDIRECT, ZP_PTR1L);

	// intOp1 still contains the control variable's new value
	// Load the "to" value into intOp2
	genExpr(pStmt->to_expr, 0, 1, 0);
	genTwo(STA_ZEROPAGE, ZP_INTOP2L);
	genTwo(STX_ZEROPAGE, ZP_INTOP2H);

	if (pStmt->isDownTo) {
		genThreeAddr(JSR, RT_LTINT16);
	}
	else {
		genThreeAddr(JSR, RT_GTINT16);
	}
	genTwo(BNE, 3);		// JMP + two_byte_addr = 3
	genThreeAddr(JMP, startOffset);
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

#if 1
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
