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
static void icodeCompExpr(unsigned char oper, struct expr* pExpr);
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

static void icodeCompExpr(unsigned char oper, struct expr* pExpr)
{
	char leftKind, rightKind;

	leftKind = icodeExpr(pExpr->left, 1);
	rightKind = icodeExpr(pExpr->right, 1);

    if (leftKind == TYPE_ENUMERATION || leftKind == TYPE_ENUMERATION_VALUE) {
        leftKind = TYPE_WORD;
    }
    if (rightKind == TYPE_ENUMERATION || rightKind == TYPE_ENUMERATION_VALUE) {
        rightKind = TYPE_WORD;
    }

	// genTwo(LDA_IMMEDIATE, getExprTypeKind(_expr.left));
	// genTwo(LDX_IMMEDIATE, getExprTypeKind(_expr.right));
	icodeWriteBinary(oper, icodeOperShort(1, leftKind),
		icodeOperShort(2, rightKind));
	// if (_expr.kind == EXPR_DIV) {
	// 	genThreeAddr(JSR, RT_DIVIDE);
	// } else if (_expr.kind == EXPR_MOD) {
	// 	genThreeAddr(JSR, RT_MOD);
	// 	if (noStack) {
	// 		genThreeAddr(JSR, RT_POPEAX);
	// 	}
	// } else {
	// 	genTwo(LDY_IMMEDIATE, _expr.kind);
	// 	genThreeAddr(JSR, RT_COMP);
	// }
}

// Returns TYPE_* of expression
char icodeExpr(CHUNKNUM chunkNum, char isRead)
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
			icodeWriteBinary(IC_CCT,
				icodeOperShort(1, getExprTypeKind(_expr.left)),
				icodeOperShort(2, getExprTypeKind(_expr.right)));
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
		icodeWriteTrinary(call, icodeOperShort(1, getExprTypeKind(_expr.left)),
			icodeOperShort(2, getExprTypeKind(_expr.right)),
			icodeOperShort(3, resultType.kind));
		break;
	}

	case EXPR_EQ:	icodeCompExpr(IC_EQU, &_expr); resultType.kind=TYPE_BOOLEAN; break;
	case EXPR_LT:	icodeCompExpr(IC_LST, &_expr); resultType.kind=TYPE_BOOLEAN; break;
	case EXPR_LTE:	icodeCompExpr(IC_LSE, &_expr); resultType.kind=TYPE_BOOLEAN; break;
	case EXPR_GT:	icodeCompExpr(IC_GRT, &_expr); resultType.kind=TYPE_BOOLEAN; break;
	case EXPR_GTE:	icodeCompExpr(IC_GTE, &_expr); resultType.kind=TYPE_BOOLEAN; break;
	case EXPR_NE:	icodeCompExpr(IC_NEQ, &_expr); resultType.kind=TYPE_BOOLEAN; break;

	case EXPR_DIV:
		icodeExpr(_expr.left, 1);
		icodeExpr(_expr.right, 1);
		icodeWriteBinary(IC_DIV, icodeOperShort(1, getExprTypeKind(_expr.left)),
			icodeOperShort(2, getExprTypeKind(_expr.right)));
		resultType.kind = TYPE_REAL;
		break;

	case EXPR_MOD:
		icodeExpr(_expr.left, 1);
		icodeExpr(_expr.right, 1);
		resultType.kind = getExprTypeKind(_expr.left);
		icodeWriteBinary(IC_MOD, icodeOperShort(1, resultType.kind),
			icodeOperShort(2, getExprTypeKind(_expr.right)));
		break;

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
			icodeWriteUnary(IC_BWC, icodeOperShort(1, resultType.kind));
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
		icodeExpr(_expr.left, 0);
		icodeWriteBinary(IC_SET, icodeOperShort(1, leftType.kind),
			icodeOperShort(2, rightType.kind));
		resultType.kind = TYPE_VOID;
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
			icodeWriteUnary(IC_PSH, icodeOperWord(1, value.value.word));
		}
		else {
			char kind = rightType.kind;
			char isByRef = (rightType.flags & TYPE_FLAG_ISBYREF);
			char oper;
			if (isRead) {
				oper = isByRef ? IC_VVR : IC_VDR;
			} else {
				oper = isByRef ? IC_VVW : IC_VDW;
			}
			icodeVar(oper, kind, (unsigned char)sym.level, (unsigned char)sym.offset);
			if (isByRef && isRead) {
				icodeWriteUnary(IC_PSH, icodeOperMem(1));
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
			icodeExpr(_expr.left, 0);
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
		icodeWriteUnary(IC_AIX, icodeOperShort(1, rightType.kind));

		if (isRead) {
			icodeWriteUnary(IC_PSH, icodeOperMem(1));
			getExprType(_expr.left, &leftType);
			retrieveChunk(leftType.subtype, &leftType);
			getBaseType(&leftType);
			if (leftType.kind == TYPE_ARRAY) {
				retrieveChunk(leftType.subtype, &leftType);
			}
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
		if (exprLeft.kind != EXPR_NAME) {
			icodeExpr(_expr.left, 0);
			// Look up the record index
			if (sym.offset) {
				icodeWriteUnary(IC_PSH, icodeOperWord(1, sym.offset));
				icodeWriteTrinary(IC_ADD, icodeOperShort(1, TYPE_WORD),
					icodeOperShort(2, TYPE_WORD), icodeOperShort(3, TYPE_WORD));
			}
		}
		else {
			// Look up the field offset
			icodeExpr(_expr.left, 1);
			if (sym.offset) {
				icodeWriteUnary(IC_PSH, icodeOperWord(1, sym.offset));
				icodeWriteTrinary(IC_ADD, icodeOperShort(1, TYPE_WORD),
					icodeOperShort(2, TYPE_WORD), icodeOperShort(3, TYPE_WORD));
			}
		}

		if (isRead) {
			icodeWriteUnary(IC_PSH, icodeOperMem(1));
		}
		resultType.kind = getExprTypeKind(_expr.right);
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

    icodeWriteTrinary(instruction, icodeOperByte(1, leftType),
        icodeOperByte(2, rightType), icodeOperByte(3, resultType.kind));

    return resultType.kind;
}

