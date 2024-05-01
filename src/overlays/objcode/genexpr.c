/**
 * genexpr.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Generate expressions in object code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <string.h>

#include <codegen.h>
#include <asm.h>
#include <ast.h>
#include <common.h>

static void genIntOrRealMath(struct expr* pExpr, char noStack);
static void getExprType(CHUNKNUM chunkNum, struct type* pType);
static char getExprTypeKind(CHUNKNUM chunkNum);

#define EXPR_AND_OR_CODE 8
static unsigned char exprAndOr[] = {
	JSR, WORD_LOW(RT_POPTOINTOP2), WORD_HIGH(RT_POPTOINTOP2),
	JSR, WORD_LOW(RT_POPTOINTOP1), WORD_HIGH(RT_POPTOINTOP1),
	LDA_ZEROPAGE, ZP_INTOP1L,
	0, ZP_INTOP2L,
	STA_ZEROPAGE, ZP_INTOP1L,
	JSR, WORD_LOW(RT_PUSHBYTESTACK), WORD_HIGH(RT_PUSHBYTESTACK),
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

// These instructions push A/X to the stack,
// leaving both intact.  Y is destroyed.
unsigned char exprFreeString1[] = {
	TAY,		// Preserve A
	PHA,		// Push A
	TXA,
	PHA,		// Push X
	TYA,		// Restore A
};

// isRead is non-zero when this expression appears on the right
// side of an assignment and the data value being read needs
// to be on the top of the stack.
// 
// No stack is non-zero when the results of the operation
// should not be placed onto the runtime stack.  They are instead
// loaded in A.
void genExpr(CHUNKNUM chunkNum, char isRead, char noStack)
{
	char name[CHUNK_LEN + 1];
	struct expr _expr, exprLeft, exprRight;
	struct symbol sym;
	struct type leftType, rightType, resultType;

	retrieveChunk(chunkNum, &_expr);

	switch (_expr.kind) {
	case EXPR_ADD:
		if (isConcatOperand(_expr.left) && isConcatOperand(_expr.right)) {
			genExpr(_expr.left, 1, 1);
			// Save first string
			genOne(PHA);
			genOne(TXA);
			genOne(PHA);
			genExpr(_expr.right, 1, 1);
			genTwo(STA_ZEROPAGE, ZP_PTR2L);
			genTwo(STX_ZEROPAGE, ZP_PTR2H);
			// Store first string in ptr1
			genOne(PLA);
			genTwo(STA_ZEROPAGE, ZP_PTR1H);
			genOne(PLA);
			genTwo(STA_ZEROPAGE, ZP_PTR1L);
			genTwo(LDA_IMMEDIATE, getExprTypeKind(_expr.left));
			genTwo(LDX_IMMEDIATE, getExprTypeKind(_expr.right));
			genThreeAddr(JSR, RT_CONCATSTRING);
			if (!noStack) {
				genThreeAddr(JSR, RT_PUSHEAX);
			}
		} else {
			genIntOrRealMath(&_expr, noStack);
		}
		break;

	case EXPR_SUB:
	case EXPR_MUL:
		genIntOrRealMath(&_expr, noStack);
		break;

	case EXPR_CALL:
		genSubroutineCall(chunkNum);
		if (noStack) {
			genThreeAddr(JSR, RT_POPEAX);
		}
		break;

	case EXPR_DIVINT:
	case EXPR_BITWISE_AND:
	case EXPR_BITWISE_OR:
	case EXPR_BITWISE_LSHIFT:
	case EXPR_BITWISE_RSHIFT: {
		unsigned short call = RT_BITWISEOR;

		if (_expr.kind == EXPR_DIVINT) {
			call = RT_DIVINT;
		} else if (_expr.kind == EXPR_BITWISE_AND) {
			call = RT_BITWISEAND;
		} else if (_expr.kind == EXPR_BITWISE_LSHIFT) {
			call = RT_BITWISELSHIFT;
		} else if (_expr.kind == EXPR_BITWISE_RSHIFT) {
			call = RT_BITWISERSHIFT;
		}

		retrieveChunk(_expr.evalType, &resultType);

		genExpr(_expr.left, 1, 0);
		genExpr(_expr.right, 1, 0);
		genTwo(LDA_IMMEDIATE, getExprTypeKind(_expr.left));
		genTwo(LDX_IMMEDIATE, getExprTypeKind(_expr.right));
		genTwo(LDY_IMMEDIATE, resultType.kind);
		genThreeAddr(JSR, call);
		if (noStack) {
			genThreeAddr(JSR, RT_POPEAX);
		}
		break;
	}

	case EXPR_BITWISE_COMPLEMENT:
		genExpr(_expr.left, 1, 0);
		genTwo(LDA_IMMEDIATE, getExprTypeKind(_expr.left));
		genThreeAddr(JSR, RT_BITWISEINVERT);
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
	case EXPR_DIV:
	case EXPR_MOD:
		genExpr(_expr.left, 1, 0);
		genExpr(_expr.right, 1, 0);
		genTwo(LDA_IMMEDIATE, getExprTypeKind(_expr.left));
		genTwo(LDX_IMMEDIATE, getExprTypeKind(_expr.right));
		if (_expr.kind == EXPR_DIV) {
			genThreeAddr(JSR, RT_DIVIDE);
		} else if (_expr.kind == EXPR_MOD) {
			genThreeAddr(JSR, RT_MOD);
			if (noStack) {
				genThreeAddr(JSR, RT_POPEAX);
			}
		} else {
			genTwo(LDY_IMMEDIATE, _expr.kind);
			genThreeAddr(JSR, RT_COMP);
		}
		break;

	case EXPR_AND:
	case EXPR_OR:
		genExpr(_expr.left, 1, 0);
		genExpr(_expr.right, 1, 0);
		exprAndOr[EXPR_AND_OR_CODE] =
			(_expr.kind == EXPR_AND ? AND_ZEROPAGE : ORA_ZEROPAGE);
		writeCodeBuf(exprAndOr, 15);
		break;

	case EXPR_NOT:
		genExpr(_expr.left, 1, 0);
		genTwo(AND_IMMEDIATE, 1);
		genTwo(EOR_IMMEDIATE, 1);
		genThreeAddr(JSR, RT_PUSHBYTESTACK);
		break;

	case EXPR_ASSIGN:
		// The left expression will always be an address in ptr1.
		// The assignment will be carried out using the store* routines.

		// The right side will always leave the assigned value on the stack.

		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);
		getBaseType(&leftType);
		getBaseType(&rightType);

		if (leftType.kind == TYPE_STRING_VAR) {
			// Address to variable's storage on stack in left in ptr1
			char isRightStringObj = 0;
			genTwo(LDA_IMMEDIATE, rightType.kind);
			genThreeAddr(JSR, RT_PUSHAX);
			genExpr(_expr.left, 0, 1);
			genTwo(LDA_ZEROPAGE, ZP_PTR1L);
			genTwo(LDX_ZEROPAGE, ZP_PTR1H);
			genThreeAddr(JSR, RT_PUSHAX);
			genExpr(_expr.right, 1, 
				isStringFunc(_expr.right) ? 0 : 1);  // works for string func
			if (isStringConcat(_expr.right) || isStringFunc(_expr.right)) {
				// The right side is a string concatentation which leaves
				// a string object on the stack.  Save the pointer so it can
				// be freed after the assignment.
				isRightStringObj = 1;
				writeCodeBuf(exprFreeString1, EXPR_FREE_STRING1_LEN);
			}
			if (isStringFunc(_expr.right)) {
				genThreeAddr(JSR, RT_POPEAX);
			}
			genThreeAddr(JSR, RT_ASSIGNSTRING);
			if (isRightStringObj) {
				// Pull the string object pointer back off the stack and free it.
				genOne(PLA);
				genOne(TAX);
				genOne(PLA);
				genThreeAddr(JSR, RT_HEAPFREE);
			}
			break;
		}
		
		genExpr(_expr.right, 1, 0);
		genExpr(_expr.left, 0, 0);		// push the variable's address next
		genTwo(LDA_IMMEDIATE, rightType.kind);
		genTwo(LDX_IMMEDIATE, leftType.kind);
		genThreeAddr(JSR, RT_ASSIGN);
		break;

	case EXPR_BOOLEAN_LITERAL:
		genBoolValueA(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHBYTESTACK);
		}
		break;
	
	case EXPR_BYTE_LITERAL:
		genShortValueA(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHBYTESTACK);
		}
		break;

	case EXPR_WORD_LITERAL:
		genIntValueAX(chunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHINTSTACK);
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
			genThreeAddr(JSR, RT_PUSHBYTESTACK);
		}
		break;

	case EXPR_NAME:
		memset(name, 0, sizeof(name));
		retrieveChunk(_expr.name, name);
		if (scope_lookup_parent(name, &sym)) {
			retrieveChunk(sym.type, &rightType);
		} else {
			rightType.flags = 0;
		}
		if (!rightType.flags) {
			scope_lookup(name, &sym);
			retrieveChunk(sym.type, &rightType);
		}
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
				genThreeAddr(JSR, RT_PUSHINTSTACK);
			}
		}
		else {
			genTwo(LDA_IMMEDIATE, (unsigned char)(sym.level));
			genTwo(LDX_IMMEDIATE, (unsigned char)(sym.offset));
			genThreeAddr(JSR, RT_CALCSTACKOFFSET);
		}
		if (rightType.flags & TYPE_FLAG_ISBYREF) {
			writeCodeBuf(nameIsByRef, 13);
		}
		if (isRead) {
			if (rightType.kind == TYPE_LONGINT || rightType.kind == TYPE_CARDINAL) {
				genThreeAddr(JSR, RT_READINT32STACK);
				if (_expr.neg) {
					genTwo(LDY_IMMEDIATE, rightType.kind);
					genThreeAddr(JSR, RT_NEGATE);
				}
				if (!noStack) {
					genThreeAddr(JSR, RT_PUSHEAX);
				}
			} else if (rightType.kind == TYPE_INTEGER || rightType.kind == TYPE_WORD || rightType.kind == TYPE_ENUMERATION) {
				genThreeAddr(JSR, RT_READINTSTACK);
				if (_expr.neg) {
					genTwo(LDY_IMMEDIATE, rightType.kind);
					genThreeAddr(JSR, RT_NEGATE);
				}
				if (!noStack) {
					genThreeAddr(JSR, RT_PUSHINTSTACK);
				}
			}
			else if (rightType.kind == TYPE_REAL) {
				genThreeAddr(JSR, RT_READREALSTACK);
				if (_expr.neg) {
					genTwo(LDY_IMMEDIATE, rightType.kind);
					genThreeAddr(JSR, RT_NEGATE);
				}
				if (!noStack) {
					genThreeAddr(JSR, RT_PUSHEAX);
				}
			}
			else if (rightType.kind == TYPE_BOOLEAN || rightType.kind == TYPE_CHARACTER ||
				rightType.kind == TYPE_SHORTINT || rightType.kind == TYPE_BYTE) {
				genThreeAddr(JSR, RT_READBYTESTACK);
				if (_expr.neg) {
					genTwo(LDY_IMMEDIATE, rightType.kind);
					genThreeAddr(JSR, RT_NEGATE);
				}
				if (!noStack) {
					genThreeAddr(JSR, RT_PUSHBYTESTACK);
				}
			}
			else if (rightType.kind == TYPE_STRING_VAR ||
				rightType.kind == TYPE_ARRAY) {
				genThreeAddr(JSR, RT_READINTSTACK);
			}
		}
		break;

	case EXPR_ARG:
		break;

	case EXPR_SUBSCRIPT:
		// First, look up the left expression.  If it's also a subscript or a field,
		// it needs to be processed first.
		retrieveChunk(_expr.left, &exprLeft);
		retrieveChunk(exprLeft.evalType, &leftType);
		getBaseType(&leftType);
		if (leftType.kind == TYPE_STRING_VAR) {
			if (isRead) {
				genExpr(_expr.right, 1, 0);
				genExpr(_expr.left, 1, 1);
				genThreeAddr(JSR, RT_STRINGSUBSCRIPTREAD);
				genThreeAddr(JSR, RT_PUSHBYTESTACK);
			} else {
				genExpr(_expr.left, 1, 1);
				genOne(PHA);
				genOne(TXA);
				genOne(PHA);
				genExpr(_expr.right, 1, 1);
				genOne(TAY);
				genOne(PLA);
				genOne(TAX);
				genOne(PLA);
				genThreeAddr(JSR, RT_STRINGSUBSCRIPTCALC);
			}
			break;
		}

		if (exprLeft.kind != EXPR_NAME) {
			genExpr(_expr.left, 0, 0);
			// Look up the array index
			genTwo(LDA_ZEROPAGE, ZP_PTR1L);
			genOne(PHA);
			genTwo(LDA_ZEROPAGE, ZP_PTR1H);
			genOne(PHA);
			genExpr(_expr.right, 1, 1);
			genThreeAddr(JSR, RT_PUSHAX);
			genOne(PLA);
			genOne(TAX);
			genOne(PLA);
		}
		else {
			// Look up the array index
			genExpr(_expr.right, 1, 1);
			genThreeAddr(JSR, RT_PUSHAX);
			// Put the address of the array variable into ptr1
			genExpr(_expr.left, 0, 1);
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

		if (isRead) {
			getExprType(_expr.left, &leftType);
			retrieveChunk(leftType.subtype, &leftType);
			getBaseType(&leftType);
			if (leftType.kind == TYPE_BOOLEAN || leftType.kind == TYPE_CHARACTER ||
				leftType.kind == TYPE_BYTE || leftType.kind == TYPE_SHORTINT) {
				genThreeAddr(JSR, RT_READBYTESTACK);
				genThreeAddr(JSR, RT_PUSHBYTESTACK);
			}
			else if (leftType.kind == TYPE_REAL) {
				genThreeAddr(JSR, RT_READREALSTACK);
				genThreeAddr(JSR, RT_PUSHREALSTACK);
			}
			else if (leftType.kind == TYPE_CARDINAL || leftType.kind == TYPE_LONGINT) {
				genThreeAddr(JSR, RT_READINT32STACK);
				genThreeAddr(JSR, RT_PUSHEAX);
			}
			else {
				genThreeAddr(JSR, RT_READINTSTACK);
				genThreeAddr(JSR, RT_PUSHINTSTACK);
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
			genExpr(_expr.left, 0, 0);
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
			genExpr(_expr.left, 0, 1);
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

		if (isRead) {
			char rightKind = getExprTypeKind(_expr.right);
			if (rightKind == TYPE_BOOLEAN || rightKind == TYPE_CHARACTER) {
				genThreeAddr(JSR, RT_READBYTESTACK);
				genThreeAddr(JSR, RT_PUSHBYTESTACK);
			}
			else if (rightKind == TYPE_REAL) {
				genThreeAddr(JSR, RT_READREALSTACK);
				genThreeAddr(JSR, RT_PUSHREALSTACK);
			}
			else if (rightKind == TYPE_CARDINAL || rightKind == TYPE_LONGINT) {
				genThreeAddr(JSR, RT_READINT32STACK);
				genThreeAddr(JSR, RT_PUSHEAX);
			}
			else {
				genThreeAddr(JSR, RT_READINTSTACK);
				genThreeAddr(JSR, RT_PUSHINTSTACK);
			}
		}
		break;

	case EXPR_STRING_LITERAL:
		genStringValueAX(_expr.value.stringChunkNum);
		if (!noStack) {
			genThreeAddr(JSR, RT_PUSHINTSTACK);
		}
		break;
	}
}

static void genIntOrRealMath(struct expr* pExpr, char noStack)
{
	struct type resultType;

	retrieveChunk(pExpr->evalType, &resultType);

	genExpr(pExpr->left, 1, 0);
	genExpr(pExpr->right, 1, 0);
	genTwo(LDA_IMMEDIATE, getExprTypeKind(pExpr->left));
	genTwo(LDX_IMMEDIATE, getExprTypeKind(pExpr->right));
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

static char getExprTypeKind(CHUNKNUM chunkNum)
{
	struct type _type;

	getExprType(chunkNum, &_type);
	return _type.kind;
}
