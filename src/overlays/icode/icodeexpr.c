/**
 * icodeexpr.c
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
#include <ast.h>
#include <string.h>
#include <common.h>

static void getExprType(CHUNKNUM chunkNum, struct type* pType);
static char getExprTypeKind(CHUNKNUM chunkNum);
static char icodeCompExpr(struct expr* pExpr);
static char icodeExprPvt(CHUNKNUM chunkNum, char isRead, char isDeref);
static char icodeIntOrRealMath(struct expr* pExpr);

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

static char icodeCompExpr(struct expr* pExpr)
{
	unsigned char oper;
	char leftKind, rightKind;

	switch (pExpr->kind) {
	case EXPR_EQ:	oper = IC_EQU; break;
	case EXPR_LT:	oper = IC_LST; break;
	case EXPR_LTE:	oper = IC_LSE; break;
	case EXPR_GT:	oper = IC_GRT; break;
	case EXPR_GTE:	oper = IC_GTE; break;
	case EXPR_NE:	oper = IC_NEQ; break;
	}

	leftKind = icodeExpr(pExpr->left, 1);
	rightKind = icodeExpr(pExpr->right, 1);

    if (leftKind == TYPE_ENUMERATION || leftKind == TYPE_ENUMERATION_VALUE) {
        leftKind = TYPE_WORD;
    }
    if (rightKind == TYPE_ENUMERATION || rightKind == TYPE_ENUMERATION_VALUE) {
        rightKind = TYPE_WORD;
    }

	icodeWriteBinaryShort(oper, leftKind, rightKind);

	return TYPE_BOOLEAN;
}

char icodeExpr(CHUNKNUM chunkNum, char isRead)
{
	return icodeExprPvt(chunkNum, isRead, 1);
}

// Returns TYPE_* of expression
static char icodeExprPvt(CHUNKNUM chunkNum, char isRead, char isDeref)
{
	char name[CHUNK_LEN + 1];
	struct expr _expr, exprLeft, exprRight;
	struct symbol sym;
	struct type leftType, rightType, resultType;

	retrieveChunk(chunkNum, &_expr);

	switch (_expr.kind) {
	case EXPR_ADD:
		if (isConcatOperand(_expr.left) && isConcatOperand(_expr.right)) {
			icodeExpr(_expr.left, 1);
			icodeExpr(_expr.right, 1);
			icodeWriteBinaryShort(IC_CCT, getExprTypeKind(_expr.left),
				getExprTypeKind(_expr.right));
			resultType.kind = TYPE_STRING_OBJ;
		} else {
			resultType.kind = icodeIntOrRealMath(&_expr);
		}
		break;

	case EXPR_SUB:
	case EXPR_MUL:
		resultType.kind = icodeIntOrRealMath(&_expr);
		break;

	case EXPR_CALL:
		resultType.kind = icodeSubroutineCall(chunkNum);
		break;

	case EXPR_DIVINT:
	case EXPR_BITWISE_AND:
	case EXPR_BITWISE_OR:
	case EXPR_BITWISE_LSHIFT:
	case EXPR_BITWISE_RSHIFT: {
		unsigned short call = IC_BWO;

		if (_expr.kind == EXPR_DIVINT) {
			call = IC_DVI;
		} else if (_expr.kind == EXPR_BITWISE_AND) {
			call = IC_BWA;
		} else if (_expr.kind == EXPR_BITWISE_LSHIFT) {
			call = IC_BSL;
		} else if (_expr.kind == EXPR_BITWISE_RSHIFT) {
			call = IC_BSR;
		}

		retrieveChunk(_expr.evalType, &resultType);

		icodeExpr(_expr.left, 1);
		icodeExpr(_expr.right, 1);
		icodeWriteTrinaryShort(call, getExprTypeKind(_expr.left),
			getExprTypeKind(_expr.right), resultType.kind);
		break;
	}

	case EXPR_EQ:
	case EXPR_LT:
	case EXPR_LTE:
	case EXPR_GT:
	case EXPR_GTE:
	case EXPR_NE:
		resultType.kind = icodeCompExpr(&_expr);
		break;

	case EXPR_DIV:
	case EXPR_MOD: {
		char kind = getExprTypeKind(_expr.left);
		icodeExpr(_expr.left, 1);
		icodeExpr(_expr.right, 1);
		icodeWriteBinaryShort(_expr.kind == EXPR_DIV ? IC_DIV : IC_MOD,
			kind, getExprTypeKind(_expr.right));
		resultType.kind = _expr.kind == EXPR_DIV ? TYPE_REAL : kind;
		break;
	}

	case EXPR_AND:
	case EXPR_OR:
		icodeExpr(_expr.left, 1);
		icodeExpr(_expr.right, 1);
		icodeWriteMnemonic(_expr.kind == EXPR_AND ? IC_AND : IC_ORA);
		break;

	case EXPR_NOT:
		icodeExpr(_expr.left, 1);
		resultType.kind = getExprTypeKind(_expr.left);
		if (resultType.kind == TYPE_BOOLEAN) {
			icodeWriteMnemonic(IC_NOT);
		} else {
			icodeWriteUnaryShort(IC_BWC, resultType.kind);
		}
		break;

	case EXPR_ASSIGN:
		// The left expression will always be an address in ptr1.
		// The assignment will be carried out using the store* routines.

		// The right side will always leave the assigned value on the stack.

		getExprType(_expr.left, &leftType);
		getExprType(_expr.right, &rightType);
		getBaseType(&leftType);
		getBaseType(&rightType);

		icodeExpr(_expr.right, 1);
		icodeExprPvt(_expr.left, 0, exprLeft.kind == TYPE_POINTER ? 1 : 0);
		icodeWriteBinaryShort(IC_SET, leftType.kind, rightType.kind);
		resultType.kind = TYPE_VOID;
		break;
	
	case EXPR_POINTER:
		getExprType(_expr.left, &leftType);
		retrieveChunk(leftType.subtype, &leftType);
		getBaseType(&leftType);
		icodeExprPvt(_expr.left, 1, 0);
		if (isRead && (leftType.kind == TYPE_ARRAY ||
			leftType.kind == TYPE_RECORD ||
			leftType.kind == TYPE_STRING_OBJ ||
			leftType.kind == TYPE_STRING_VAR)) {
			icodeWriteUnaryShort(IC_MEM, leftType.kind);
		}
		else if (isDeref) {
			icodeWriteUnaryShort(IC_MEM, leftType.kind);
			resultType.kind = leftType.kind;
		}
		break;
	
	case EXPR_ADDRESS_OF:
		icodeExprPvt(_expr.left, 0, 0);
		resultType.kind = TYPE_ADDRESS;
		break;

	case EXPR_BOOLEAN_LITERAL:
		resultType.kind = icodeBoolValue(chunkNum);
		break;
	
	case EXPR_BYTE_LITERAL:
		resultType.kind = icodeShortValue(chunkNum);
		break;

	case EXPR_WORD_LITERAL:
		resultType.kind = icodeWordValue(chunkNum);
		break;

	case EXPR_DWORD_LITERAL:
		resultType.kind = icodeDWordValue(chunkNum);
		break;

	case EXPR_REAL_LITERAL:
		icodeRealValue(_expr.value.stringChunkNum);
		resultType.kind = TYPE_REAL;
		break;

	case EXPR_CHARACTER_LITERAL:
		resultType.kind = icodeCharValue(chunkNum);
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
			icodeWriteMnemonic(IC_PSH);
			icodeWriteMnemonic(IC_RET);
		}
		else if (rightType.kind == TYPE_ENUMERATION_VALUE) {
			struct decl _decl;
			struct expr value;
			retrieveChunk(sym.decl, &_decl);
			retrieveChunk(_decl.value, &value);
			icodeWriteUnaryWord(IC_PSH, value.value.word);
		}
		else {
			struct type subtype;
			char kind = rightType.kind;
			char isByRef, oper;
			if (rightType.subtype && rightType.kind == TYPE_POINTER) {
				retrieveChunk(rightType.subtype, &subtype);
			} else {
				subtype.flags = rightType.flags;
			}
			isByRef = (subtype.flags & TYPE_FLAG_ISBYREF);
			if (isRead) {
				oper = isByRef ? IC_VVR : IC_VDR;
			} else {
				oper = isByRef ? IC_VVW : IC_VDW;
			}
			icodeVar(oper, kind, (unsigned char)sym.level, (unsigned char)sym.offset);
			if (isByRef && isRead) {
				icodeWriteUnaryShort(IC_MEM, kind);
			}
			resultType.kind = rightType.kind;
		}
		resultType.kind = rightType.kind;
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
				icodeExpr(_expr.right, 1);
				icodeExpr(_expr.left, 1);
				icodeWriteMnemonic(IC_SSR);
			} else {
				icodeExpr(_expr.left, 1);
				icodeExpr(_expr.right, 1);
				icodeWriteMnemonic(IC_SSW);
			}
			break;
		}

		if (exprLeft.kind != EXPR_NAME) {
			icodeExprPvt(_expr.left, 0, isDeref);
			if (!isRead && exprLeft.kind == EXPR_POINTER) {
				icodeWriteUnaryShort(IC_MEM, TYPE_ADDRESS);
			}
			icodeExpr(_expr.right, 1);
		}
		else {
			// Look up the array index
			icodeExpr(_expr.left, 1);
			// Put the address of the array variable into ptr1
			icodeExpr(_expr.right, 1);
		}

		retrieveChunk(_expr.right, &exprRight);
		retrieveChunk(exprRight.evalType, &rightType);
		icodeWriteUnaryShort(IC_AIX, rightType.kind);

		if (isRead) {
			getExprType(_expr.left, &leftType);
			retrieveChunk(leftType.subtype, &leftType);
			getBaseType(&leftType);
			if (leftType.kind == TYPE_ARRAY) {
				retrieveChunk(leftType.subtype, &leftType);
			}
			icodeWriteUnaryShort(IC_MEM, leftType.kind);
			resultType.kind = leftType.kind;
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
		// Look up the field offset
		if (exprLeft.kind == EXPR_POINTER) {
			retrieveChunk(exprLeft.left, &exprLeft);
		}
		if (exprLeft.kind != EXPR_NAME) {
			icodeExpr(_expr.left, 0);
		}
		else {
			icodeExpr(_expr.left, 1);
		}
		if (sym.offset) {
			icodeWriteUnaryWord(IC_PSH, sym.offset);
			icodeWriteTrinaryShort(IC_ADD, TYPE_WORD, TYPE_WORD, TYPE_WORD);
		}

		resultType.kind = getExprTypeKind(_expr.right);
		if (isRead) {
			icodeWriteUnaryShort(IC_MEM, resultType.kind);
		}
		break;

	case EXPR_STRING_LITERAL:
		icodeStringValue(_expr.value.stringChunkNum);
        resultType.kind = TYPE_STRING_LITERAL;
		break;
	}

    return resultType.kind;
}

static char icodeIntOrRealMath(struct expr* pExpr)
{
    char leftType, rightType;
    unsigned char instruction;
	struct type resultType;

	retrieveChunk(pExpr->evalType, &resultType);

	leftType = icodeExpr(pExpr->left, 1);
	rightType = icodeExpr(pExpr->right, 1);
	switch (pExpr->kind) {
		case EXPR_ADD:
            instruction = IC_ADD;
			break;

		case EXPR_SUB:
            instruction = IC_SUB;
			break;

		case EXPR_MUL:
            instruction = IC_MUL;
			break;
	}

	if (pExpr->kind != EXPR_MUL) {
		if (leftType == TYPE_POINTER) {
			struct expr _expr;
			struct type _type;
			retrieveChunk(pExpr->left, &_expr);
			retrieveChunk(_expr.evalType, &_type);
			retrieveChunk(_type.subtype, &_type);
			icodeWriteUnary(IC_PSH, icodeOperInt(1, _type.size));
			icodeWriteTrinaryShort(IC_MUL, rightType, TYPE_INTEGER, rightType);
		}
	}

    icodeWriteTrinary(instruction, icodeOperByte(1, leftType),
        icodeOperByte(2, rightType), icodeOperByte(3, resultType.kind));

    return resultType.kind;
}

