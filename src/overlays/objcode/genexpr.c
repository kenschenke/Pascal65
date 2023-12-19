#include <stdio.h>
#include <string.h>

#include <codegen.h>
#include <asm.h>
#include <ast.h>

static void genIntOrRealMath(struct expr* pExpr, char noStack);
static void getExprType(CHUNKNUM chunkNum, struct type* pType);

#define EXPR_AND_OR_CODE 8
static unsigned char exprAndOr[] = {
	JSR, WORD_LOW(RT_POPTOINTOP2), WORD_HIGH(RT_POPTOINTOP2),
	JSR, WORD_LOW(RT_POPTOINTOP1), WORD_HIGH(RT_POPTOINTOP1),
	LDA_ZEROPAGE, ZP_INTOP1L,
	0, ZP_INTOP2L,
	STA_ZEROPAGE, ZP_INTOP1L,
	JSR, WORD_LOW(RT_PUSHBYTE), WORD_HIGH(RT_PUSHBYTE),
};

static unsigned char nameIsRetVal[] = {
	LDA_ZEROPAGE, ZP_STACKFRAMEL,
	SEC,
	SBC_IMMEDIATE, 4,
	STA_ZEROPAGE, ZP_PTR1L,
	LDA_ZEROPAGE, ZP_STACKFRAMEH,
	SBC_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1H,
};

static unsigned char nameIsByRef[] = {
	LDY_IMMEDIATE, 1,
	LDA_ZPINDIRECT, ZP_PTR1L,
	PHA,
	DEY,
	LDA_ZPINDIRECT, ZP_PTR1L,
	STA_ZEROPAGE, ZP_PTR1L,
	PLA,
	STA_ZEROPAGE, ZP_PTR1H,
};

#define EXPR_FIELD_OFFSETL 1
#define EXPR_FIELD_OFFSETH 3
static unsigned char exprField1[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_PUSHAX), WORD_HIGH(RT_PUSHAX),
	LDA_ZEROPAGE, ZP_PTR1L,
	LDX_ZEROPAGE, ZP_PTR1H,
	JSR, WORD_LOW(RT_CALCRECORD), WORD_HIGH(RT_CALCRECORD),
	STA_ZEROPAGE, ZP_PTR1L,
	STX_ZEROPAGE, ZP_PTR1H,
};

// isRead is non-zero when this expression appears on the right
// side of an assignment and the data value being read needs
// to be on the top of the stack.
// 
// No stack is non-zero when the results of the operation
// should not be placed onto the runtime stack.  They are instead
// loaded in A.
//
// isParentHeapVar is non-zero when the parent expression is also
// a heap variable (array or record).  This is used for arrays embedded
// in records and records as array elements.  In such cases the embedded
// data struct does not get its own heap, but it part of its parent's.
void genExpr(CHUNKNUM chunkNum, char isRead, char noStack, char isParentHeapVar)
{
	char name[CHUNK_LEN + 1];
	struct expr _expr, exprLeft, exprRight;
	struct symbol sym;
	struct type leftType, rightType, resultType;

	retrieveChunk(chunkNum, &_expr);

	switch (_expr.kind) {
	case EXPR_ADD:
	case EXPR_SUB:
	case EXPR_MUL:
		genIntOrRealMath(&_expr, noStack);
		break;

	case EXPR_CALL:
		genSubroutineCall(chunkNum);
		break;

	case EXPR_DIVINT:
		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);
		retrieveChunk(_expr.evalType, &resultType);

		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genTwo(LDA_IMMEDIATE, leftType.kind);
		genTwo(LDX_IMMEDIATE, rightType.kind);
		genTwo(LDY_IMMEDIATE, resultType.kind);
		genThreeAddr(JSR, RT_DIVINT);
		if (noStack) {
			genThreeAddr(JSR, RT_POPEAX);
		}
		break;

	case EXPR_EQ:
	case EXPR_LT:
	case EXPR_LTE:
	case EXPR_GT:
	case EXPR_GTE:
	case EXPR_NE:
		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);

		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genTwo(LDA_IMMEDIATE, leftType.kind);
		genTwo(LDX_IMMEDIATE, rightType.kind);
		genTwo(LDY_IMMEDIATE, _expr.kind);
		genThreeAddr(JSR, RT_COMP);
		break;

	case EXPR_DIV:
		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);

		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genTwo(LDA_IMMEDIATE, leftType.kind);
		genTwo(LDX_IMMEDIATE, rightType.kind);
		genThreeAddr(JSR, RT_DIVIDE);
		break;

	case EXPR_MOD:
		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);

		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genTwo(LDA_IMMEDIATE, leftType.kind);
		genTwo(LDX_IMMEDIATE, rightType.kind);
		genThreeAddr(JSR, RT_MOD);
		if (noStack) {
			genThreeAddr(JSR, RT_POPEAX);
		}
		break;

	case EXPR_AND:
	case EXPR_OR:
		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		exprAndOr[EXPR_AND_OR_CODE] =
			(_expr.kind == EXPR_AND ? AND_ZEROPAGE : ORA_ZEROPAGE);
		writeCodeBuf(exprAndOr, 15);
		break;

	case EXPR_NOT:
		genExpr(_expr.left, 1, 0, 0);
		genTwo(AND_IMMEDIATE, 1);
		genTwo(EOR_IMMEDIATE, 1);
		genThreeAddr(JSR, RT_PUSHBYTE);
		break;

	case EXPR_ASSIGN:
		// The left expression will always be an address in ptr1.
		// The assignment will be carried out using the store* routines.

		// The right side will always leave the assigned value on the stack.

		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);
		getBaseType(&leftType);
		getBaseType(&rightType);
		genExpr(_expr.right, 1, 0, 0);
		genExpr(_expr.left, 0, 0, 0);		// push the variable's address next
		genTwo(LDA_IMMEDIATE, rightType.kind);
		genTwo(LDX_IMMEDIATE, leftType.kind);
		genThreeAddr(JSR, RT_ASSIGN);
		break;

	case EXPR_BOOLEAN_LITERAL:
		genBoolValueA(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHBYTE);
		}
		break;
	
	case EXPR_BYTE_LITERAL:
		genShortValueA(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHBYTE);
		}
		break;

	case EXPR_WORD_LITERAL:
		genIntValueAX(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHINT);
		}
		break;

	case EXPR_DWORD_LITERAL:
		genIntValueEAX(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHEAX);
		}
		break;

	case EXPR_REAL_LITERAL:
		genRealValueEAX(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHEAX);
		}
		break;

	case EXPR_CHARACTER_LITERAL:
		genCharValueA(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHBYTE);
		}
		break;

	case EXPR_NAME:
		memset(name, 0, sizeof(name));
		retrieveChunk(_expr.name, name);
		scope_lookup(name, &sym);
		retrieveChunk(sym.type, &rightType);
		if (rightType.kind == TYPE_DECLARED) {
			struct symbol typeSym;
			char typeFlags = rightType.flags;
			memset(name, 0, sizeof(name));
			retrieveChunk(rightType.name, name);
			scope_lookup(name, &typeSym);
			retrieveChunk(typeSym.type, &rightType);
			rightType.flags = typeFlags;
		}
		if (rightType.flags & TYPE_FLAG_ISRETVAL) {
			writeCodeBuf(nameIsRetVal, 13);
		}
		else if (rightType.kind == TYPE_ENUMERATION_VALUE) {
			struct decl _decl;
			struct expr value;
			retrieveChunk(sym.decl, &_decl);
			retrieveChunk(_decl.value, &value);
			genTwo(LDA_IMMEDIATE, WORD_LOW(value.value.integer));
			genTwo(LDX_IMMEDIATE, WORD_HIGH(value.value.integer));
			if (!noStack) {
				genThreeAddr(JSR, RT_PUSHINT);
			}
		}
		else {
			genTwo(LDA_IMMEDIATE, (unsigned char)(sym.level));
			genTwo(LDX_IMMEDIATE, (unsigned char)(sym.offset));
			genThreeAddr(JSR, RT_CALCSTACK);
		}
		if (rightType.flags & TYPE_FLAG_ISBYREF) {
			writeCodeBuf(nameIsByRef, 13);
		}
		if (isRead) {
			if (rightType.kind == TYPE_LONGINT || rightType.kind == TYPE_CARDINAL) {
				genThreeAddr(JSR, RT_READINT32);
				if (!noStack) {
					genThreeAddr(JSR, RT_PUSHEAX);
				}
			} else if (rightType.kind == TYPE_INTEGER || rightType.kind == TYPE_WORD || rightType.kind == TYPE_ENUMERATION) {
				genThreeAddr(JSR, RT_READINT);
				if (!noStack) {
					genThreeAddr(JSR, RT_PUSHINT);
				}
			}
			else if (rightType.kind == TYPE_REAL) {
				genThreeAddr(JSR, RT_READREAL);
				if (!noStack) {
					genThreeAddr(JSR, RT_PUSHEAX);
				}
			}
			else if (rightType.kind == TYPE_BOOLEAN || rightType.kind == TYPE_CHARACTER ||
				rightType.kind == TYPE_SHORTINT || rightType.kind == TYPE_BYTE) {
				genThreeAddr(JSR, RT_READBYTE);
				if (!noStack) {
					genThreeAddr(JSR, RT_PUSHBYTE);
				}
			}
		}
		break;

	case EXPR_ARG:
		break;

	case EXPR_SUBSCRIPT:
		// First, look up the left expression.  If it's also a subscript or a field,
		// it needs to be processed first.
		retrieveChunk(_expr.left, &exprLeft);
		if (exprLeft.kind != EXPR_NAME) {
			genExpr(_expr.left, 0, 0, 1);
			// Look up the array index
			genTwo(LDA_ZEROPAGE, ZP_PTR1L);
			genOne(PHA);
			genTwo(LDA_ZEROPAGE, ZP_PTR1H);
			genOne(PHA);
			genExpr(_expr.right, 1, 1, 1);
			genThreeAddr(JSR, RT_PUSHAX);
			genOne(PLA);
			genOne(TAX);
			genOne(PLA);
		}
		else {
			// Look up the array index
			genExpr(_expr.right, 1, 1, 1);
			genThreeAddr(JSR, RT_PUSHAX);
			// Put the address of the array variable into ptr1
			genExpr(_expr.left, 0, 1, 0);
			genTwo(LDY_IMMEDIATE, 1);
			genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
			genOne(TAX);
			genOne(DEY);
			genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
		}

		retrieveChunk(_expr.right, &exprRight);
		retrieveChunk(exprRight.evalType, &rightType);
		genTwo(LDY_IMMEDIATE, rightType.kind);
		genThreeAddr(JSR, RT_CALCARRAYOFFSET);
		genTwo(STA_ZEROPAGE, ZP_PTR1L);
		genTwo(STX_ZEROPAGE, ZP_PTR1H);

		if (!isParentHeapVar) {
			if (isRead) {
				getExprType(_expr.left, &leftType);
				retrieveChunk(leftType.subtype, &leftType);
				getBaseType(&leftType);
				if (leftType.kind == TYPE_BOOLEAN || leftType.kind == TYPE_CHARACTER ||
					leftType.kind == TYPE_BYTE || leftType.kind == TYPE_SHORTINT) {
					genThreeAddr(JSR, RT_READBYTE);
					genThreeAddr(JSR, RT_PUSHBYTE);
				}
				else if (leftType.kind == TYPE_REAL) {
					genThreeAddr(JSR, RT_READREAL);
					genThreeAddr(JSR, RT_PUSHREAL);
				}
				else if (leftType.kind == TYPE_CARDINAL || leftType.kind == TYPE_LONGINT) {
					genThreeAddr(JSR, RT_READINT32);
					genThreeAddr(JSR, RT_PUSHEAX);
				}
				else {
					genThreeAddr(JSR, RT_READINT);
					genThreeAddr(JSR, RT_PUSHINT);
				}
			}
		}
		break;

	case EXPR_FIELD:
		// First, look up the left expression.  If it's also a subscript or a field,
		// it needs to be processed first.
		retrieveChunk(_expr.left, &exprLeft);
		retrieveChunk(_expr.right, &exprRight);
		getExprType(_expr.left, &leftType);
		if (leftType.subtype) {
			retrieveChunk(leftType.subtype, &leftType);
		}
		if (leftType.kind == TYPE_DECLARED) {
			memset(name, 0, sizeof(name));
			retrieveChunk(leftType.name, name);
			scope_lookup(name, &sym);
			retrieveChunk(sym.type, &leftType);
		}
		memset(name, 0, sizeof(name));
		retrieveChunk(exprRight.name, name);
		symtab_lookup(leftType.symtab, name, &sym);
		if (exprLeft.kind != EXPR_NAME) {
			genExpr(_expr.left, 0, 0, 1);
			// Look up the record index
			if (sym.offset) {
				exprField1[EXPR_FIELD_OFFSETL] = WORD_LOW(sym.offset);
				exprField1[EXPR_FIELD_OFFSETH] = WORD_HIGH(sym.offset);
				writeCodeBuf(exprField1, 18);
			}
		}
		else {
			// Look up the field offset
			if (sym.offset) {
				genTwo(LDA_IMMEDIATE, WORD_LOW(sym.offset));
				genTwo(LDX_IMMEDIATE, WORD_HIGH(sym.offset));
				genThreeAddr(JSR, RT_PUSHAX);
			}
			genExpr(_expr.left, 0, 1, 1);
			genTwo(LDY_IMMEDIATE, 1);
			genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
			genOne(TAX);
			genOne(DEY);
			genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
			if (sym.offset) {
				genThreeAddr(JSR, RT_CALCRECORD);
			}
			genTwo(STA_ZEROPAGE, ZP_PTR1L);
			genTwo(STX_ZEROPAGE, ZP_PTR1H);
		}

		if (!isParentHeapVar) {
			if (isRead) {
				getExprType(_expr.right, &rightType);
				if (rightType.kind == TYPE_BOOLEAN || rightType.kind == TYPE_CHARACTER) {
					genThreeAddr(JSR, RT_READBYTE);
					genThreeAddr(JSR, RT_PUSHBYTE);
				}
				else if (rightType.kind == TYPE_REAL) {
					genThreeAddr(JSR, RT_READREAL);
					genThreeAddr(JSR, RT_PUSHREAL);
				}
				else if (rightType.kind == TYPE_CARDINAL || rightType.kind == TYPE_LONGINT) {
					genThreeAddr(JSR, RT_READINT32);
					genThreeAddr(JSR, RT_PUSHEAX);
				}
				else {
					genThreeAddr(JSR, RT_READINT);
					genThreeAddr(JSR, RT_PUSHINT);
				}
			}
		}
		break;

	case EXPR_STRING_LITERAL:
		genStringValueAX(_expr.value.stringChunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHINT);
		}
		break;
	}
}

static void genIntOrRealMath(struct expr* pExpr, char noStack)
{
	struct type leftType, rightType, resultType;

	getExprType(pExpr->left, &leftType);
	getExprType(pExpr->right, &rightType);
	retrieveChunk(pExpr->evalType, &resultType);

	genExpr(pExpr->left, 1, 0, 0);
	genExpr(pExpr->right, 1, 0, 0);
	genTwo(LDA_IMMEDIATE, leftType.kind);
	genTwo(LDX_IMMEDIATE, rightType.kind);
	genTwo(LDY_IMMEDIATE, resultType.kind);
	switch (pExpr->kind) {
		case EXPR_ADD:
			genThreeAddr(JSR, RT_ADD);
			break;

		case EXPR_SUB:
			genThreeAddr(JSR, RT_SUBTRACT);
			break;

		case EXPR_MUL:
			genThreeAddr(JSR, RT_MULTIPLY);
			break;
	}

	if (noStack) {
		genThreeAddr(JSR, RT_POPEAX);
	}
}

static void getExprType(CHUNKNUM chunkNum, struct type* pType)
{
	struct expr _expr;

	retrieveChunk(chunkNum, &_expr);
	retrieveChunk(_expr.evalType, pType);
}

