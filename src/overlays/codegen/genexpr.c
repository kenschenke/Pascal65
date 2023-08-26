#include <stdio.h>
#include <string.h>

#include <codegen.h>
#include <asm.h>
#include <ast.h>

static void genComparison(CHUNKNUM chunkNum);
static void genIntOrRealExprAsReal(CHUNKNUM chunkNum, char kind);
static void genIntOrRealMath(struct expr* pExpr, char noStack);
static void getExprType(CHUNKNUM chunkNum, struct type* pType);

static void genComparison(CHUNKNUM chunkNum)
{
	struct expr _expr;
	struct type _type;

	retrieveChunk(chunkNum, &_expr);
	getExprType(_expr.left, &_type);

	if (_type.kind == TYPE_INTEGER || _type.kind == TYPE_CHARACTER) {
		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOINTOP2);
		genThreeAddr(JSR, RT_POPTOINTOP1);
		switch (_expr.kind) {
		case EXPR_LT: genThreeAddr(JSR, RT_LTINT16); break;
		case EXPR_LTE: genThreeAddr(JSR, RT_LEINT16); break;
		case EXPR_GT: genThreeAddr(JSR, RT_GTINT16); break;
		case EXPR_GTE: genThreeAddr(JSR, RT_GEINT16); break;
		case EXPR_EQ:
		case EXPR_NE:
			genThreeAddr(JSR, RT_EQINT16);
			break;
		}
	}
	else {
		// Real
		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOREAL);
		genThreeAddr(JSR, RT_COPYFPACC);
		genThreeAddr(JSR, RT_POPTOREAL);
		switch (_expr.kind) {
		case EXPR_LT: genThreeAddr(JSR, RT_FLOATLT); break;
		case EXPR_LTE: genThreeAddr(JSR, RT_FLOATLTE); break;
		case EXPR_GT: genThreeAddr(JSR, RT_FLOATGT); break;
		case EXPR_GTE: genThreeAddr(JSR, RT_FLOATGTE); break;
		case EXPR_EQ:
		case EXPR_NE:
			genThreeAddr(JSR, RT_FLOATEQ);
			break;
		}
	}

	genTwo(AND_IMMEDIATE, 1);
	if (_expr.kind == EXPR_NE) {
		genTwo(EOR_IMMEDIATE, 1);
	}
	genThreeAddr(JSR, RT_PUSHBYTE);
}

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
	struct type leftType, rightType;

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
		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOINTOP2);
		genThreeAddr(JSR, RT_POPTOINTOP1);
		genThreeAddr(JSR, RT_DIVINT16);
		if (noStack) {
			genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
		}
		else {
			genThreeAddr(JSR, RT_PUSHINTOP1);
		}
		break;

	case EXPR_EQ:
	case EXPR_LT:
	case EXPR_LTE:
	case EXPR_GT:
	case EXPR_GTE:
	case EXPR_NE:
		genComparison(chunkNum);
		break;

	case EXPR_DIV:
		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);

		genIntOrRealExprAsReal(_expr.left, leftType.kind);
		genIntOrRealExprAsReal(_expr.right, rightType.kind);

		genThreeAddr(JSR, RT_POPTOREAL);
		genThreeAddr(JSR, RT_COPYFPACC);
		genThreeAddr(JSR, RT_POPTOREAL);
		genThreeAddr(JSR, RT_FPDIV);
		genThreeAddr(JSR, RT_PUSHREAL);
		break;

	case EXPR_MOD:
		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOINTOP2);
		genThreeAddr(JSR, RT_POPTOINTOP1);
		genThreeAddr(JSR, RT_MODINT16);
		if (noStack) {
			genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
		}
		else {
			genThreeAddr(JSR, RT_PUSHINTOP1);
		}
		break;

	case EXPR_AND:
	case EXPR_OR:
		genExpr(_expr.left, 1, 0, 0);
		genExpr(_expr.right, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOINTOP2);
		genThreeAddr(JSR, RT_POPTOINTOP1);
		genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
		genTwo(_expr.kind == EXPR_AND ? AND_ZEROPAGE : ORA_ZEROPAGE, ZP_INTOP2L);
		genTwo(STA_ZEROPAGE, ZP_INTOP1L);
		genThreeAddr(JSR, RT_PUSHBYTE);
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

		// The right side will always leave the value to assign on the stack.

		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);
		genExpr(_expr.right, 1, 0, 0);
		if (leftType.kind == TYPE_REAL) {
			if (rightType.kind == TYPE_INTEGER) {
				genThreeAddr(JSR, RT_POPTOINTOP1);
				genThreeAddr(JSR, RT_INT16TOFLOAT);
				genThreeAddr(JSR, RT_PUSHREAL);
			}
			genExpr(_expr.left, 0, 0, 0);		// push the variable's address next
			genThreeAddr(JSR, RT_STOREREAL);
		}
		else if (leftType.kind == TYPE_BOOLEAN || leftType.kind == TYPE_CHARACTER) {
			genExpr(_expr.left, 0, 0, 0);		// push the variable's address next
			genThreeAddr(JSR, RT_STOREBYTE);
		}
		else {
			genExpr(_expr.left, 0, 0, 0);		// push the variable's address next
			genThreeAddr(JSR, RT_STOREINT);
		}
		break;

	case EXPR_BOOLEAN_LITERAL:
		genBoolValueA(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHBYTE);
		}
		break;

	case EXPR_INTEGER_LITERAL:
		genIntValueAX(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHINT);
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
			genTwo(LDA_ZEROPAGE, ZP_STACKFRAMEL);
			genOne(SEC);
			genTwo(SBC_IMMEDIATE, 4);
			genTwo(STA_ZEROPAGE, ZP_PTR1L);
			genTwo(LDA_ZEROPAGE, ZP_STACKFRAMEH);
			genTwo(SBC_IMMEDIATE, 0);
			genTwo(STA_ZEROPAGE, ZP_PTR1H);
		}
		else if (rightType.kind == TYPE_ENUMERATION_VALUE) {
			struct decl _decl;
			struct expr value;
			retrieveChunk(sym.decl, &_decl);
			retrieveChunk(_decl.value, &value);
			genTwo(LDA_IMMEDIATE, WORD_LOW(value.value.integer));
			genTwo(LDX_IMMEDIATE, WORD_HIGH(value.value.integer));
			genThreeAddr(JSR, RT_PUSHINT);
		}
		else {
			genTwo(LDA_IMMEDIATE, (unsigned char)(sym.level));
			genTwo(LDX_IMMEDIATE, (unsigned char)(sym.offset));
			genThreeAddr(JSR, RT_CALCSTACK);
		}
		if (rightType.flags & TYPE_FLAG_ISBYREF) {
			genTwo(LDY_IMMEDIATE, 1);
			genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
			genOne(PHA);
			genOne(DEY);
			genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
			genTwo(STA_ZEROPAGE, ZP_PTR1L);
			genOne(PLA);
			genTwo(STA_ZEROPAGE, ZP_PTR1H);
		}
		if (isRead) {
			if (rightType.kind == TYPE_INTEGER || rightType.kind == TYPE_ENUMERATION) {
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
			else if (rightType.kind == TYPE_BOOLEAN || rightType.kind == TYPE_CHARACTER) {
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

		genThreeAddr(JSR, RT_CALCARRAYOFFSET);
		genTwo(STA_ZEROPAGE, ZP_PTR1L);
		genTwo(STX_ZEROPAGE, ZP_PTR1H);

		if (!isParentHeapVar) {
			if (isRead) {
				getExprType(_expr.left, &leftType);
				if (leftType.kind == TYPE_BOOLEAN || leftType.kind == TYPE_CHARACTER) {
					genThreeAddr(JSR, RT_READBYTE);
					genThreeAddr(JSR, RT_PUSHBYTE);
				}
				else if (leftType.kind == TYPE_REAL) {
					genThreeAddr(JSR, RT_READREAL);
					genThreeAddr(JSR, RT_PUSHREAL);
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
				genTwo(LDA_IMMEDIATE, WORD_LOW(sym.offset));
				genTwo(LDX_IMMEDIATE, WORD_HIGH(sym.offset));
				genThreeAddr(JSR, RT_PUSHAX);
				genTwo(LDA_ZEROPAGE, ZP_PTR1L);
				genTwo(LDX_ZEROPAGE, ZP_PTR1H);
			}
			if (sym.offset) {
				genThreeAddr(JSR, RT_CALCRECORD);
				genTwo(STA_ZEROPAGE, ZP_PTR1L);
				genTwo(STX_ZEROPAGE, ZP_PTR1H);
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
				getExprType(_expr.left, &leftType);
				if (leftType.kind == TYPE_BOOLEAN || leftType.kind == TYPE_CHARACTER) {
					genThreeAddr(JSR, RT_READBYTE);
					genThreeAddr(JSR, RT_PUSHBYTE);
				}
				else if (leftType.kind == TYPE_REAL) {
					genThreeAddr(JSR, RT_READREAL);
					genThreeAddr(JSR, RT_PUSHREAL);
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

static void genIntOrRealExprAsReal(CHUNKNUM chunkNum, char kind)
{
	genExpr(chunkNum, 1, 0, 0);
	if (kind == TYPE_INTEGER) {
		genThreeAddr(JSR, RT_POPTOINTOP1);
		genThreeAddr(JSR, RT_INT16TOFLOAT);
		genThreeAddr(JSR, RT_PUSHREAL);
	}
}

static void genIntOrRealMath(struct expr* pExpr, char noStack)
{
	struct type leftType, rightType;

	getExprType(pExpr->left, &leftType);
	getExprType(pExpr->right, &rightType);
	if (leftType.kind == TYPE_INTEGER && rightType.kind == TYPE_INTEGER) {
		// Integer + Integer
		genExpr(pExpr->left, 1, 0, 0);
		genExpr(pExpr->right, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOINTOP2);
		genThreeAddr(JSR, RT_POPTOINTOP1);
		switch (pExpr->kind) {
		case EXPR_ADD: genThreeAddr(JSR, RT_ADDINT16); break;
		case EXPR_SUB: genThreeAddr(JSR, RT_SUBINT16); break;
		case EXPR_MUL: genThreeAddr(JSR, RT_MULTINT16); break;
		}
		if (noStack) {
			genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
		}
		else {
			genThreeAddr(JSR, RT_PUSHINTOP1);
		}
	}
	else {
		// Any other combo of real and real/integer
		genIntOrRealExprAsReal(pExpr->left, leftType.kind);
		genIntOrRealExprAsReal(pExpr->right, rightType.kind);

		genThreeAddr(JSR, RT_POPTOREAL);
		genThreeAddr(JSR, RT_COPYFPACC);
		genThreeAddr(JSR, RT_POPTOREAL);
		switch (pExpr->kind) {
		case EXPR_ADD: genThreeAddr(JSR, RT_FPADD); break;
		case EXPR_SUB: genThreeAddr(JSR, RT_FPSUB); break;
		case EXPR_MUL: genThreeAddr(JSR, RT_FPMULT); break;
		}
		genThreeAddr(JSR, RT_PUSHREAL);
	}
}

static void getExprType(CHUNKNUM chunkNum, struct type* pType)
{
	struct expr _expr;

	retrieveChunk(chunkNum, &_expr);
	retrieveChunk(_expr.evalType, pType);
}

