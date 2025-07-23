/**
 * typecheck.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Typechecking stage
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <typecheck.h>
#include <ast.h>
#include <error.h>
#include <symtab.h>
#include <common.h>
#include <string.h>
#include <limits.h>

#define STDPARM_INTEGER 0x1
#define STDPARM_ENUM    0x2
#define STDPARM_REAL    0x4
#define STDPARM_CHAR    0x8

/*
; |----------------------------------------------------------------------------------|
; |          | Byte     | ShortInt | Word     | Integer  | Cardinal | LongInt | Real |
; |----------|----------|----------|----------|----------|----------|----------------|
; | Byte     | Byte     | Byte     | Word     | Integer  | Cardinal | LongInt | Real |
; | ShortInt | Byte     | ShortInt | LongInt  | Integer  | LongInt  | LongInt | Real |
; | Word     | Word     | LongInt  | Word     | Word     | Cardinal | LongInt | Real |
; | Integer  | Integer  | Integer  | Word     | Integer  | LongInt  | LongInt | Real |
; | Cardinal | Cardinal | Cardinal | Cardinal | Cardinal | Cardinal | Cardinal| Real |
; | LongInt  | LongInt  | LongInt  | LongInt  | LongInt  | Cardinal | LongInt | Real |
; | Real     | Real     | Real     | Real     | Real     | Real     | Real    | Real |
; |----------------------------------------------------------------------------------|
*/

static char typeConversions[7][7] = {
	{ TYPE_BYTE,     TYPE_BYTE,     TYPE_WORD,     TYPE_INTEGER,  TYPE_CARDINAL, TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_BYTE,     TYPE_SHORTINT, TYPE_LONGINT,  TYPE_INTEGER,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_WORD,     TYPE_LONGINT,  TYPE_WORD,     TYPE_WORD,     TYPE_CARDINAL, TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_INTEGER,  TYPE_INTEGER,  TYPE_WORD,     TYPE_INTEGER,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_REAL },
	{ TYPE_LONGINT,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_CARDINAL, TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL },
};

static void caseTypeCheck(char exprKind, CHUNKNUM subtype, CHUNKNUM labelChunk);
static char checkAbsSqrCall(CHUNKNUM argChunk, char routineCode);		// returns TYPE_*
static void checkArray(CHUNKNUM indexChunk, CHUNKNUM elemChunk);
static void checkArrayLiteral(struct type *pArrayType, struct expr *pLiteralExpr);
static void checkArraysSameType(struct type* pType1, struct type* pType2);
static void checkAssignment(struct type *pLeftType, struct type *pRightType,
	struct type *pResultType, CHUNKNUM exprRightChunk);
static void checkBoolOperand(struct type* pType);
static void checkDecIncCall(CHUNKNUM argChunk);
static void checkForwardVsFormalDeclaration(CHUNKNUM fwdParams, CHUNKNUM formalParams);
static void checkFuncProcCall(CHUNKNUM exprChunk, struct type* pRetnType);
static void checkIntegerBaseType(CHUNKNUM exprChunk);
static void checkPredSuccCall(CHUNKNUM argChunk, struct type* pRetnType);
static void checkReadReadlnCall(CHUNKNUM argChunk, char routineCode);
static void checkRelOpOperands(struct type* pType1, struct type* pType2);
static void checkStdParms(CHUNKNUM argChunk, char allowedParms);
static void checkStdRoutine(struct type* pType, CHUNKNUM argChunk, struct type* pRetnType);
static void checkWriteWritelnCall(CHUNKNUM argChunk, char routineCode);
static void expr_literal(struct expr* pExpr, struct type* pType);
static void expr_typecheck(CHUNKNUM chunkNum, CHUNKNUM recordSymtab, struct type* pType, char parentIsFuncCall);
static void getArrayType(CHUNKNUM exprChunk, struct type* pType);
static void hoistFuncCall(CHUNKNUM chunkNum);
static char integerOperands(char type1Kind, char type2Kind, short *pSize);
static char isAssignableToString(char rightKind, CHUNKNUM rightSubType);
static char isAssignmentCompatible(char leftKind, struct type *rightType);
static char isExprAFuncCall(CHUNKNUM exprChunk);
static char isExprATypeDeclaration(CHUNKNUM exprChunk);
static char isTypeOrdinal(char type);
static char isTypeNumeric(char type);
static char realOperands(char type1Kind, char type2Kind, short *pSize);
static void saveEvalType(CHUNKNUM chunkNum, struct expr* pExpr, struct type* pType);

static void caseTypeCheck(char exprKind, CHUNKNUM subtype, CHUNKNUM labelChunk)
{
	CHUNKNUM exprChunk;
	struct stmt _stmt;
	struct expr _expr;
	struct type _type;

	while (labelChunk) {
		retrieveChunk(labelChunk, &_stmt);
		currentLineNumber = _stmt.lineNumber;

		exprChunk = _stmt.expr;
		while (exprChunk) {
			retrieveChunk(exprChunk, &_expr);

			expr_typecheck(exprChunk, 0, &_type, 0);
			if (!(_type.flags & TYPE_FLAG_ISCONST)) {
				Error(errNotAConstantIdentifier);
			}
			if (exprKind == TYPE_ENUMERATION &&
				(_type.kind == TYPE_ENUMERATION || _type.kind == TYPE_ENUMERATION_VALUE)) {
				if (_type.subtype != subtype) {
					Error(errIncompatibleTypes);
				}
			}
			else if (_type.kind == TYPE_CHARACTER && exprKind == TYPE_CHARACTER) {
				// do nothing
			}
			else if (typeConversions[_type.kind-1][exprKind-1] == TYPE_VOID) {
				Error(errIncompatibleTypes);
			}

			exprChunk = _expr.right;
		}

		stmt_typecheck(_stmt.body);

		labelChunk = _stmt.next;
	}
}

static char checkAbsSqrCall(CHUNKNUM argChunk, char routineCode)
{
	struct expr _expr;
	struct type _type;

	// Needs to have the first parameter
	if (!argChunk) {
		Error(errWrongNumberOfParams);
		return TYPE_VOID;
	}

	// It can't have more than more parameter
	retrieveChunk(argChunk, &_expr);
	if (_expr.right) {
		Error(errWrongNumberOfParams);
		return TYPE_VOID;
	}

	// Look at the argument
	expr_typecheck(_expr.left, 0, &_type, 0);
	if (!isTypeInteger(_type.kind) && _type.kind != TYPE_REAL) {
		Error(errInvalidType);
		return TYPE_VOID;
	}

	// If it's Sqr, the return type is a long integer
	if (routineCode == rcSqr && _type.kind != TYPE_REAL) {
		return TYPE_LONGINT;	// Sqr always returns a long integer
	}

	return _type.kind;
}

static void checkArray(CHUNKNUM indexChunk, CHUNKNUM elemChunk)
{
	struct type indexType, elemType;

	retrieveChunk(indexChunk, &indexType);
	getBaseType(&indexType);
	if (!isTypeOrdinal(indexType.kind) && indexType.kind != TYPE_CHARACTER) {
		Error(errInvalidIndexType);
	}
	retrieveChunk(elemChunk, &elemType);
	getBaseType(&elemType);
	if (elemType.kind == TYPE_ARRAY) {
		checkArray(elemType.indextype, elemType.subtype);
	}
}

static void checkArrayLiteral(struct type *pArrayType, struct expr *pLiteralExpr)
{
	int min, max, elems = 0;
	struct expr _expr;
	struct type elemType, exprType, resultType;
	CHUNKNUM exprChunkNum = pLiteralExpr->left;

	retrieveChunk(pArrayType->subtype, &elemType);

	while (exprChunkNum) {
		retrieveChunk(exprChunkNum, &_expr);

		if (elemType.kind == TYPE_ARRAY) {
			// If the array elements are arrays then
			// the literal must be an array literal.
			if (_expr.kind != EXPR_ARRAY_LITERAL) {
				Error(errInvalidConstant);
			}
			checkArrayLiteral(&elemType, &_expr);
		} else {
			retrieveChunk(_expr.evalType, &exprType);
			checkAssignment(&elemType, &exprType, &resultType, exprChunkNum);
		}

		elems++;
		exprChunkNum = _expr.right;
	}

	// Make sure the array literal does not have too many elements
	retrieveChunk(pArrayType->indextype, &resultType);
	retrieveChunk(resultType.min, &_expr);
	min = _expr.kind == EXPR_BYTE_LITERAL ? _expr.value.byte : _expr.value.integer;
	retrieveChunk(resultType.max, &_expr);
	max = _expr.kind == EXPR_BYTE_LITERAL ? _expr.value.byte : _expr.value.integer;
	if (elems > max-min+1) {
		Error(errIndexOutOfRange);
	}
}

static void checkArraysSameType(struct type* pType1, struct type* pType2)
{
	struct expr min1, min2, max1, max2;
	struct type subtype1, subtype2, indexType1, indexType2;

	retrieveChunk(pType1->subtype, &subtype1);
	retrieveChunk(pType2->subtype, &subtype2);
	getBaseType(&subtype1);
	getBaseType(&subtype2);

	if (subtype1.kind != subtype2.kind) {
		Error(errInvalidType);
	}

	retrieveChunk(pType1->indextype, &indexType1);
	retrieveChunk(pType2->indextype, &indexType2);

	retrieveChunk(indexType1.min, &min1);
	retrieveChunk(indexType2.min, &min2);
	retrieveChunk(indexType1.max, &max1);
	retrieveChunk(indexType2.max, &max2);

	if (min1.kind != min2.kind ||
		memcmp(&min1.value, &min2.value, sizeof(TDataValue))) {
		Error(errInvalidType);
	}

	if (max1.kind != max2.kind ||
		memcmp(&max1.value, &max2.value, sizeof(TDataValue))) {
		Error(errInvalidType);
	}

	getBaseType(&indexType1);
	getBaseType(&indexType2);
	if (indexType1.kind != indexType2.kind) {
		Error(errInvalidType);
	}
}

static void checkAssignment(struct type *pLeftType, struct type *pRightType,
	struct type *pResultType, CHUNKNUM exprRightChunk)
{
	struct expr exprRight;

	retrieveChunk(exprRightChunk, &exprRight);

	if (pLeftType->kind == TYPE_REAL &&
		(pRightType->kind == TYPE_REAL || isTypeInteger(pRightType->kind))) {
		pResultType->kind = TYPE_REAL;
		pResultType->size = sizeof(FLOAT);
	}
	else if (pLeftType->kind == TYPE_CHARACTER && pRightType->kind == TYPE_CHARACTER) {
		pResultType->kind = TYPE_CHARACTER;
		pResultType->size = sizeof(char);
	}
	else if (pLeftType->kind == TYPE_BOOLEAN && pRightType->kind == TYPE_BOOLEAN) {
		pResultType->kind = TYPE_BOOLEAN;
		pResultType->size = sizeof(char);
	}
	else if (pLeftType->kind == TYPE_STRING_VAR) {
		if (!isAssignableToString(pRightType->kind, pRightType->subtype)) {
			Error(errIncompatibleAssignment);
			pResultType->kind = TYPE_VOID;
			return;
		}
		pResultType->kind = pLeftType->kind;
		pResultType->size = 2;
	}
	else if (isAssignmentCompatible(pLeftType->kind, pRightType)) {
		pResultType->kind = pLeftType->kind;
		pResultType->size = GET_TYPE_SIZE(getTypeMask(pLeftType->kind));
	}
	else if (pLeftType->kind == TYPE_ENUMERATION &&
		(pRightType->kind == TYPE_ENUMERATION || pRightType->kind == TYPE_ENUMERATION_VALUE)) {
		if (pLeftType->subtype != pRightType->subtype) {
			Error(errIncompatibleAssignment);
		}
		pResultType->kind = TYPE_VOID;
	}
	else if (pLeftType->kind == TYPE_POINTER) {
		struct type subtype, rtype;
		struct symbol sym;
	
		if (exprRight.kind == EXPR_BYTE_LITERAL ||
			exprRight.kind == EXPR_WORD_LITERAL) {
			// assignment okay
		} else {
			char subscript = 0;  // non-zero if address of array subscript
			retrieveChunk(pLeftType->subtype, &subtype);
			retrieveChunk(exprRight.left, &exprRight);
			if (exprRight.kind == EXPR_SUBSCRIPT) {
				retrieveChunk(exprRight.left, &exprRight);
				subscript = 1;
			}
			retrieveChunk(exprRight.node, &sym);
			retrieveChunk(sym.type, &rtype);
			getBaseType(&subtype);
			while (rtype.kind == TYPE_FUNCTION || rtype.kind == TYPE_ROUTINE_POINTER) {
				retrieveChunk(rtype.subtype, &rtype);
			}
			if (rtype.kind == TYPE_ARRAY && subscript) {
				retrieveChunk(rtype.subtype, &rtype);
			}
			if (rtype.kind == TYPE_POINTER) {
				// assignment okay
			}
			else if (subtype.kind != rtype.kind) {
				Error(errIncompatibleAssignment);
				pResultType->kind = TYPE_VOID;
			}
		}
	}
	else if (pLeftType->kind == TYPE_ROUTINE_POINTER) {
		struct expr _expr;
		char name[CHUNK_LEN+1];
		struct symbol sym;
		struct decl _decl;
		struct type leftSubtype, rightSubtype;
		if (pRightType->kind != TYPE_ROUTINE_ADDRESS) {
			Error(errIncompatibleAssignment);
		}
		retrieveChunk(exprRight.left, &_expr);
		memset(name, 0, sizeof(name));
		retrieveChunk(_expr.name, name);
		scope_lookup(name, &sym);
		retrieveChunk(sym.decl, &_decl);
		if (_decl.isLibrary) {
			Error(errIncompatibleAssignment);
		}
		retrieveChunk(pLeftType->subtype, &leftSubtype);
		retrieveChunk(sym.type, &rightSubtype);
		// Make sure the pointers point to a routine of the same type
		checkForwardVsFormalDeclaration(leftSubtype.paramsFields, rightSubtype.paramsFields);
	}
	else {
		Error(errIncompatibleAssignment);
		pResultType->kind = TYPE_VOID;
	}
}

static void checkBoolOperand(struct type* pType)
{
	if (pType->kind != TYPE_BOOLEAN) {
		Error(errIncompatibleTypes);
	}
}

static void checkDecIncCall(CHUNKNUM argChunk)
{
	struct expr _expr;
	struct type _type;

	// Needs to have the first parameter
	if (!argChunk) {
		Error(errWrongNumberOfParams);
		return;
	}

	// Look at the first argument.
	// It must be an integer, character, pointer, or enumeration
	retrieveChunk(argChunk, &_expr);
	expr_typecheck(_expr.left, 0, &_type, 0);
	if (!isTypeInteger(_type.kind) && _type.kind != TYPE_CHARACTER &&
		_type.kind != TYPE_ENUMERATION && _type.kind != TYPE_POINTER) {
		Error(errInvalidType);
		return;
	}

	// The argument must be a variable and not constant
	if (_type.flags & TYPE_FLAG_ISCONST) {
		Error(errInvalidType);
		return;
	}

	// If there is a second argument, it must be an integer
	if (_expr.right) {
		retrieveChunk(_expr.right, &_expr);
		expr_typecheck(_expr.left, 0, &_type, 0);
		if (!isTypeInteger(_type.kind)) {
			Error(errInvalidType);
			return;
		}

		// It can't have a third argument
		if (_expr.right) {
			Error(errWrongNumberOfParams);
		}
	}
}

static void checkIntegerBaseType(CHUNKNUM exprChunk)
{
	struct type _type;

	if (!exprChunk) {
		return;
	}

	expr_typecheck(exprChunk, 0, &_type, 0);
	getBaseType(&_type);
	if (_type.kind != TYPE_INTEGER) {
		Error(errIncompatibleTypes);
	}
}

static void checkForwardVsFormalDeclaration(CHUNKNUM fwdParams, CHUNKNUM formalParams)
{
	struct param_list fwdParam, formalParam;
	struct type fwdType, formalType;

	while (fwdParams && formalParams) {
		retrieveChunk(fwdParams, &fwdParam);
		retrieveChunk(formalParams, &formalParam);

		retrieveChunk(fwdParam.type, &fwdType);
		retrieveChunk(formalParam.type, &formalType);

		getBaseType(&fwdType);
		getBaseType(&formalType);

		if (fwdType.kind != formalType.kind) {
			Error(errIncompatibleTypes);
		}
		else if (fwdType.kind == TYPE_ENUMERATION) {
			if (fwdType.subtype != formalType.subtype) {
				Error(errIncompatibleTypes);
			}
		}
		else if (fwdType.kind == TYPE_ARRAY) {
			struct type fwdIndex, formalIndex;
			struct type fwdElement, formalElement;
			struct expr fwdMin, fwdMax, formalMin, formalMax;

			retrieveChunk(fwdType.subtype, &fwdElement);
			retrieveChunk(formalType.subtype, &formalElement);
			getBaseType(&fwdElement);
			getBaseType(&formalElement);
			if (fwdElement.kind != formalElement.kind) {
				Error(errIncompatibleTypes);
			}

			retrieveChunk(fwdType.indextype, &fwdIndex);
			retrieveChunk(formalType.indextype, &formalIndex);

			retrieveChunk(fwdIndex.min, &fwdMin);
			retrieveChunk(fwdIndex.max, &fwdMax);
			retrieveChunk(formalIndex.min, &formalMin);
			retrieveChunk(formalIndex.max, &formalMax);

			if (fwdMin.kind != formalMin.kind ||
				memcmp(&fwdMin.value, &formalMin.value, sizeof(TDataValue))) {
				Error(errIncompatibleTypes);
			}

			if (fwdMax.kind != formalMax.kind ||
				memcmp(&fwdMax.value, &formalMax.value, sizeof(TDataValue))) {
				Error(errIncompatibleTypes);
			}

			getBaseType(&fwdIndex);
			getBaseType(&formalIndex);
			if (fwdIndex.subtype != formalIndex.subtype) {
				Error(errIncompatibleTypes);
			}
		}

		fwdParams = fwdParam.next;
		formalParams = formalParam.next;
	}

	if (fwdParams != formalParams) {
		Error(errWrongNumberOfParams);
	}
}

static void checkFuncProcCall(CHUNKNUM exprChunk, struct type* pRetnType)
{
	char name[CHUNK_LEN + 1];
	struct expr _expr, exprArg, exprName, exprLeft;
	struct symbol sym;
	struct type _type, paramType, argType;
	struct param_list param;
	CHUNKNUM paramChunk, argChunk;

	memset(pRetnType, 0, sizeof(struct type));

	retrieveChunk(exprChunk, &_expr);
	retrieveChunk(_expr.left, &exprName);
	retrieveChunk(exprName.name, name);
	if (!scope_lookup(name, &sym)) {
		Error(errUndefinedIdentifier);
		pRetnType->kind = TYPE_VOID;
	}

	// If the symbol is the function's return value then look up the
	// symbol in the parent scope because the function's symbol is needed.
	retrieveChunk(sym.type, &_type);
	getBaseType(&_type);
	if (_type.flags & TYPE_FLAG_ISRETVAL) {
		if (!scope_lookup_parent(name, &sym)) {
			Error(errUndefinedIdentifier);
			pRetnType->kind = TYPE_VOID;
		}
		retrieveChunk(sym.type, &_type);
	}

	if (_type.kind == TYPE_ROUTINE_POINTER) {
		// Pointer to routine
		retrieveChunk(_type.subtype, &_type);
	}

	if (_type.kind != TYPE_FUNCTION && _type.kind != TYPE_PROCEDURE) {
		Error(errInvalidExpression);
		pRetnType->kind = TYPE_VOID;
	}

	if (_type.flags & TYPE_FLAG_ISSTD) {
		checkStdRoutine(&_type, _expr.right, pRetnType);
		return;
	}

	paramChunk = _type.paramsFields;
	argChunk = _expr.right;
	while (paramChunk && argChunk) {
		retrieveChunk(paramChunk, &param);
		retrieveChunk(argChunk, &exprArg);
		retrieveChunk(param.type, &paramType);
		getBaseType(&paramType);

		expr_typecheck(argChunk, 0, &argType, 0);

		if (paramType.kind == TYPE_ENUMERATION
			&& (argType.kind == TYPE_ENUMERATION || argType.kind == TYPE_ENUMERATION_VALUE))
		{
			if (paramType.subtype != argType.subtype) {
				Error(errInvalidType);
			}
		}
		else if (paramType.kind == TYPE_RECORD && argType.kind == TYPE_RECORD) {
			if (paramType.paramsFields != argType.paramsFields) {
				Error(errInvalidType);
			}
		}
		else if (paramType.kind == TYPE_ARRAY && argType.kind == TYPE_ARRAY) {
			checkArraysSameType(&paramType, &argType);
		}
		else if (isTypeInteger(paramType.kind)) {
			if (typeConversions[argType.kind-1][paramType.kind-1] == TYPE_VOID) {
				Error(errInvalidType);
			}
		}
		else if (paramType.kind == TYPE_STRING_VAR) {
			if ((paramType.flags & TYPE_FLAG_ISBYREF) && 
				argType.kind != TYPE_STRING_VAR) {
				Error(errInvalidType);
			}
			else if (!isAssignableToString(argType.kind, argType.subtype)) {
				Error(errInvalidType);
			}
		}
		else if (paramType.kind == TYPE_FILE) {
			if (argType.kind == TYPE_TEXT) {
				// okay
			} else if (argType.kind == TYPE_FILE) {
				if (paramType.subtype && argType.subtype != paramType.subtype) {
					Error(errInvalidType);
				}
			} else {
				Error(errInvalidType);
			}
			if (!(paramType.flags & TYPE_FLAG_ISBYREF)) {
				Error(errInvalidType);
			}
		}
		else if (paramType.kind == TYPE_POINTER && argType.kind == TYPE_ADDRESS) {
			struct type paramSubType, argSubType;

			retrieveChunk(paramType.subtype, &paramSubType);
			retrieveChunk(argType.subtype, &argSubType);
			if (paramSubType.kind != argSubType.kind) {
				Error(errIncompatibleTypes);
			}
		}
		else if (paramType.kind == TYPE_ROUTINE_POINTER && argType.kind == TYPE_ROUTINE_ADDRESS) {
			struct type paramSubType, argSubType;
			struct symbol sym;

			retrieveChunk(exprArg.left, &exprLeft);
			retrieveChunk(exprLeft.left, &exprLeft);
			retrieveChunk(exprLeft.node, &sym);
			retrieveChunk(sym.type, &argSubType);
			retrieveChunk(paramType.subtype, &paramSubType);
			checkForwardVsFormalDeclaration(paramSubType.paramsFields, argSubType.paramsFields);
		}
		else if (paramType.kind != argType.kind) {
			Error(errInvalidType);
		}
		if (paramType.flags & TYPE_FLAG_ISBYREF) {
			retrieveChunk(exprArg.left, &exprLeft);
			if (argType.kind == TYPE_TEXT && paramType.kind == TYPE_FILE) {
				// okay
			}
			else if (argType.kind != paramType.kind) {
				Error(errInvalidVarParm);
			}
			if (exprLeft.kind != EXPR_SUBSCRIPT &&
				exprLeft.kind != EXPR_NAME &&
				exprLeft.kind != EXPR_FIELD &&
				exprLeft.kind != EXPR_POINTER) {
				Error(errInvalidVarParm);
			}
			else if (argType.flags & TYPE_FLAG_ISCONST) {
				Error(errInvalidVarParm);
			}
		}

		paramChunk = param.next;
		argChunk = exprArg.right;
	}

	if (paramChunk || argChunk) {
		Error(errWrongNumberOfParams);
	}

	if (_type.subtype) {
		retrieveChunk(_type.subtype, &_type);
		pRetnType->kind = _type.kind;
		pRetnType->subtype = _type.subtype;
		if (_type.name) {
			pRetnType->name = _type.name;
		}
	} else {
		pRetnType->kind = 0;
		pRetnType->subtype = 0;
		pRetnType->name = 0;
	}
}

static void checkPredSuccCall(CHUNKNUM argChunk, struct type* pRetnType)
{
	char name[CHUNK_LEN + 1];
	struct expr _expr;
	struct type _type;
	struct symbol sym;

	// Needs to have the first parameter
	if (!argChunk) {
		Error(errWrongNumberOfParams);
		pRetnType->kind = TYPE_VOID;
		return;
	}

	// It can't have more than more parameter
	retrieveChunk(argChunk, &_expr);
	if (_expr.right) {
		Error(errWrongNumberOfParams);
		pRetnType->kind = TYPE_VOID;
		return;
	}

	// Look at the argument
	retrieveChunk(_expr.left, &_expr);
	if (_expr.kind == EXPR_WORD_LITERAL) {
		pRetnType->kind = TYPE_INTEGER;
		return;
	}
	if (_expr.kind == EXPR_CHARACTER_LITERAL) {
		pRetnType->kind = TYPE_CHARACTER;
		return;
	}
	if (_expr.kind != EXPR_NAME) {
		Error(errInvalidType);
		pRetnType->kind = TYPE_VOID;
		return;
	}
	retrieveChunk(_expr.name, name);
	if (!scope_lookup(name, &sym)) {
		Error(errUndefinedIdentifier);
		pRetnType->kind = TYPE_VOID;
		return;
	}
	retrieveChunk(sym.type, &_type);
	getBaseType(&_type);

	if (isTypeInteger(_type.kind) || _type.kind == TYPE_CHARACTER) {
		pRetnType->kind = _type.kind;
		return;
	}
	if (_type.kind == TYPE_ENUMERATION || _type.kind == TYPE_ENUMERATION_VALUE) {
		pRetnType->kind = TYPE_ENUMERATION;
		pRetnType->flags = TYPE_FLAG_ISCONST;
		pRetnType->subtype = _type.subtype;
		return;
	}

	Error(errIncompatibleTypes);
	pRetnType->kind = TYPE_VOID;
}

static void checkReadReadlnCall(CHUNKNUM argChunk, char routineCode)
{
	char first = 1, subscript = 0;
	char name[CHUNK_LEN + 1];
	struct expr _expr, exprLeft;
	struct symbol sym;
	struct type _type, subtype, fileSubtype;

	fileSubtype.kind = 0;

	while (argChunk)
	{
		retrieveChunk(argChunk, &_expr);
		retrieveChunk(_expr.left, &exprLeft);

		expr_typecheck(_expr.left, 0, &_type, 0);
		getBaseType(&_type);
		if (_expr.evalType) {
			freeChunk(_expr.evalType);
		}
		allocChunk(&_expr.evalType);
		storeChunk(_expr.evalType, &_type);
		storeChunk(argChunk, &_expr);

		if (exprLeft.kind == EXPR_SUBSCRIPT) {
			retrieveChunk(exprLeft.left, &exprLeft);
			subscript = 1;
		}
		if (exprLeft.kind == EXPR_POINTER) {
			retrieveChunk(exprLeft.left, &exprLeft);
		}
		if (exprLeft.kind != EXPR_NAME) {
			Error(errInvalidVarParm);
			argChunk = _expr.right;
			continue;
		}

		retrieveChunk(exprLeft.name, name);
		if (!scope_lookup(name, &sym)) {
			Error(errUndefinedIdentifier);
			argChunk = _expr.right;
			continue;
		}

		retrieveChunk(sym.type, &_type);
		if (subscript) {
			retrieveChunk(_type.subtype, &_type);
		}
		getBaseType(&_type);
		if (subscript) {
			retrieveChunk(_type.subtype, &_type);
		}
		switch (_type.kind) {
		case TYPE_ARRAY:
			retrieveChunk(_type.subtype, &subtype);
			getBaseType(&subtype);
			if (fileSubtype.kind == 0) {
				if (subtype.kind != TYPE_CHARACTER) {
					Error(errIncompatibleTypes);
				}
			} else {
				checkArraysSameType(&_type, &fileSubtype);
			}
			break;

		case TYPE_BOOLEAN:
		case TYPE_CHARACTER:
		case TYPE_BYTE:
		case TYPE_SHORTINT:
		case TYPE_INTEGER:
		case TYPE_WORD:
		case TYPE_CARDINAL:
		case TYPE_LONGINT:
		case TYPE_STRING_VAR:
		case TYPE_REAL:
			if (_type.flags & TYPE_FLAG_ISCONST) {
				Error(errIncompatibleTypes);
			}
			break;

		case TYPE_FILE:
			if (!first) {
				Error(errIncompatibleTypes);
			}
			if (routineCode != rcRead) {
				Error(errIncompatibleTypes);
			}
			if (_type.subtype) {
				retrieveChunk(_type.subtype, &fileSubtype);
				getBaseType(&fileSubtype);
			}
			break;

		case TYPE_TEXT:
			if (!first) {
				Error(errIncompatibleTypes);
			}
			break;
		
		case TYPE_RECORD:
			break;

		default:
			Error(errIncompatibleTypes);
			break;
		}

		if (!first && fileSubtype.kind && fileSubtype.kind != TYPE_ARRAY) {
			if (!isAssignmentCompatible(fileSubtype.kind, &_type)) {
				Error(errIncompatibleTypes);
			}
		}

		first = 0;
		argChunk = _expr.right;
	}
}

static void checkRelOpOperands(struct type* pType1, struct type* pType2)
{
	struct type type1, type2;

	memcpy(&type1, pType1, sizeof(struct type));
	memcpy(&type2, pType2, sizeof(struct type));

	if (pType1->kind == TYPE_BOOLEAN && pType2->kind == TYPE_BOOLEAN) {
		return;
	}

	if (pType1->kind == TYPE_CHARACTER && pType2->kind == TYPE_CHARACTER) {
		return;
	}

	getBaseType(&type1);
	getBaseType(&type2);
	if ((type1.kind == TYPE_ENUMERATION || type1.kind == TYPE_ENUMERATION_VALUE) &&
		(type2.kind == TYPE_ENUMERATION || type2.kind == TYPE_ENUMERATION_VALUE)) {
		if (type1.subtype != type2.subtype) {
			Error(errIncompatibleTypes);
		}
		return;
	}

	if (type1.kind == TYPE_POINTER || type2.kind == TYPE_POINTER) {
		if (type1.kind == TYPE_POINTER || type1.kind == TYPE_ADDRESS) {
			retrieveChunk(type1.subtype, &type1);
		}
		if (type2.kind == TYPE_POINTER || type2.kind == TYPE_ADDRESS) {
			retrieveChunk(type2.subtype, &type2);
		}
		if (type1.kind != type2.kind) {
			Error(errIncompatibleTypes);
		}
		return;
	}

	if (!isTypeNumeric(pType1->kind) || !isTypeNumeric(pType2->kind)) {
		Error(errIncompatibleTypes);
	}
}

static void checkStdParms(CHUNKNUM argChunk, char allowedParms)
{
	struct expr _expr;
	struct type _type;

	retrieveChunk(argChunk, &_expr);
	// There should be one parameter
	if (_expr.right) {
		Error(errWrongNumberOfParams);
	}

	expr_typecheck(_expr.left, 0, &_type, 0);
	getBaseType(&_type);

	if ((allowedParms & STDPARM_CHAR && _type.kind == TYPE_CHARACTER) ||
		(allowedParms & STDPARM_ENUM && (_type.kind == TYPE_ENUMERATION || _type.kind == TYPE_ENUMERATION_VALUE)) ||
		(allowedParms & STDPARM_INTEGER && isTypeInteger(_type.kind)) ||
		(allowedParms & STDPARM_REAL && _type.kind == TYPE_REAL)) {
		// All good
	}
	else {
		Error(errIncompatibleTypes);
	}
}

static void checkStdRoutine(struct type* pType, CHUNKNUM argChunk, struct type* pRetnType)
{
	memset(pRetnType, 0, sizeof(struct type));

	switch (pType->routineCode) {
	case rcRead:
	case rcReadln:
		checkReadReadlnCall(argChunk, pType->routineCode);
		pRetnType->kind = TYPE_VOID;
		break;

	case rcWrite:
	case rcWriteln:
	case rcWriteStr:
		checkWriteWritelnCall(argChunk, pType->routineCode);
		pRetnType->kind = pType->routineCode == rcWriteStr ?
			TYPE_STRING_OBJ : TYPE_VOID;
		break;

	case rcAbs:
	case rcSqr:
		pRetnType->kind = checkAbsSqrCall(argChunk, pType->routineCode);
		break;

	case rcPred:
	case rcSucc:
		checkPredSuccCall(argChunk, pRetnType);
		break;

	case rcOrd:
		checkStdParms(argChunk, STDPARM_CHAR | STDPARM_ENUM | STDPARM_INTEGER);
		pRetnType->kind = TYPE_INTEGER;
		break;

	case rcRound:
	case rcTrunc:
		checkStdParms(argChunk, STDPARM_REAL);
		pRetnType->kind = TYPE_INTEGER;
		break;

	case rcDec:
	case rcInc:
		checkDecIncCall(argChunk);
		break;

	default:
		pRetnType->kind = TYPE_VOID;
		break;
	}
}

static void checkWriteWritelnCall(CHUNKNUM argChunk, char routineCode)
{
	char first = 1;
	struct expr _expr, exprLeft;
	struct type _type, subtype, fileSubtype;

	fileSubtype.kind = 0;

	while (argChunk)
	{
		retrieveChunk(argChunk, &_expr);
		retrieveChunk(_expr.left, &exprLeft);

		expr_typecheck(_expr.left, 0, &_type, 0);
		getBaseType(&_type);
		if (_expr.evalType) {
			freeChunk(_expr.evalType);
		}
		allocChunk(&_expr.evalType);
		storeChunk(_expr.evalType, &_type);
		storeChunk(argChunk, &_expr);

		if (_type.kind == TYPE_ARRAY) {
			retrieveChunk(_type.subtype, &subtype);
			getBaseType(&subtype);
			if (fileSubtype.kind == 0) {
				if (subtype.kind != TYPE_CHARACTER) {
					Error(errIncompatibleTypes);
				}
				checkIntegerBaseType(exprLeft.width);
				checkIntegerBaseType(exprLeft.precision);
			} else {
				checkArraysSameType(&_type, &fileSubtype);
			}
		} else if (_type.kind == TYPE_RECORD) {
			retrieveChunk(_type.subtype, &subtype);
			if (subtype.symtab != fileSubtype.symtab) {
				Error(errIncompatibleTypes);
			}
		} else if (_type.kind == TYPE_REAL ||
			_type.kind == TYPE_CHARACTER ||
			_type.kind == TYPE_BOOLEAN ||
			isTypeInteger(_type.kind)) {
			checkIntegerBaseType(exprLeft.width);
			checkIntegerBaseType(exprLeft.precision);
		} else if (_type.kind == TYPE_TEXT) {
			if (!first) {
				Error(errIncompatibleTypes);
			}
			if (routineCode == rcWriteStr) {
				Error(errIncompatibleTypes);
			}
		} else if (_type.kind == TYPE_FILE) {
			if (!first) {
				Error(errIncompatibleTypes);
			}
			if (routineCode != rcWrite) {
				Error(errIncompatibleTypes);
			}
			if (_type.subtype) {
				retrieveChunk(_type.subtype, &fileSubtype);
				getBaseType(&fileSubtype);
			}
		} else if (_type.kind != TYPE_STRING_LITERAL &&
			_type.kind != TYPE_STRING_VAR &&
			_type.kind != TYPE_STRING_OBJ) {
			Error(errIncompatibleTypes);
		}

		if (!first && fileSubtype.kind && fileSubtype.kind != TYPE_ARRAY && fileSubtype.kind != TYPE_RECORD) {
			if (!isAssignmentCompatible(fileSubtype.kind, &_type)) {
				Error(errIncompatibleTypes);
			}
		}

		first = 0;
		argChunk = _expr.right;
	}
}

static char integerOperands(char type1Kind, char type2Kind, short *pSize)
{
	char resultKind;

	if (!isTypeInteger(type1Kind) || !isTypeInteger(type2Kind)) {
		Error(errIncompatibleTypes);
	}

	resultKind = typeConversions[type1Kind-1][type2Kind-1];
	if (resultKind == TYPE_VOID) {
		Error(errIncompatibleTypes);
	}

	*pSize = GET_TYPE_SIZE(getTypeMask(resultKind));

	return resultKind;
}

static char realOperands(char type1Kind, char type2Kind, short *pSize)
{
	char resultKind;

	if (type1Kind < TYPE_BYTE || type1Kind > TYPE_REAL ||
		type2Kind < TYPE_BYTE || type2Kind > TYPE_REAL) {
		Error(errIncompatibleTypes);
		return TYPE_VOID;
	}

	resultKind = typeConversions[type1Kind-1][type2Kind-1];
	if (resultKind == TYPE_VOID) {
		Error(errIncompatibleTypes);
	}

	if (resultKind == TYPE_REAL) {
		*pSize = 4;
	} else  {
		*pSize = GET_TYPE_SIZE(getTypeMask(resultKind));
	}

	return resultKind;
}

void decl_typecheck(CHUNKNUM chunkNum)
{
	struct decl _decl;
	struct type _type;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		currentLineNumber = _decl.lineNumber;

		if (_decl.value) {
			expr_typecheck(_decl.value, 0, &_type, 0);
			if (_decl.kind == DECL_VARIABLE) {
				struct type varType, resultType;

				retrieveChunk(_decl.type, &varType);
				if (varType.kind == TYPE_ARRAY) {
					struct expr _expr;
					retrieveChunk(_decl.value, &_expr);
					if (_expr.kind != EXPR_ARRAY_LITERAL) {
						Error(errInvalidConstant);
					}
					checkArrayLiteral(&varType, &_expr);
				} else {
					if (!(_type.flags & TYPE_FLAG_ISCONST)) {
						Error(errInvalidConstant);
					}

					checkAssignment(&varType, &_type, &resultType, _decl.value);
				}
			}
			// check type.kind to _decl.symbol.type
		}

		if (_decl.code) {
			if (_decl.symtab) {
				scope_enter_symtab(_decl.symtab);
			}
			stmt_typecheck(_decl.code);
			if (_decl.symtab) {
				scope_exit();
			}
		}

		if (_decl.type) {
			struct type _type;
			retrieveChunk(_decl.type, &_type);

			// If this is an array make sure the index type is
			// an integer, enum, or character and the element type is not a string.
			// Only do the check if this is a variable and the type
			// is an anonymous type (defined inline) or this declaration
			// is the array type (Type section).
			if (((_decl.kind == DECL_VARIABLE && _type.name == 0) || _decl.kind == DECL_TYPE) && _type.kind == TYPE_ARRAY) {
				checkArray(_type.indextype, _type.subtype);
			}

			// If this is a function or procedure, check for a forward declaration and make
			// sure the forward declaration matches the formal declaration.
			if ((_type.kind == TYPE_FUNCTION || _type.kind == TYPE_PROCEDURE) &&
				!(_type.flags & TYPE_FLAG_ISFORWARD)) {
				char name[CHUNK_LEN + 1];
				struct symbol sym;
				struct decl otherProc;
				struct type otherType;

				memset(name, 0, sizeof(name));
				retrieveChunk(_decl.name, name);
				scope_lookup(name, &sym);
				retrieveChunk(sym.decl, &otherProc);
				retrieveChunk(otherProc.type, &otherType);
				checkForwardVsFormalDeclaration(otherType.paramsFields, _type.paramsFields);
			}
		}

		chunkNum = _decl.next;
	}
}

static void getArrayType(CHUNKNUM exprChunk, struct type* pType)
{
	struct expr _expr;

	retrieveChunk(exprChunk, &_expr);
	if (_expr.kind == EXPR_SUBSCRIPT || _expr.kind == EXPR_POINTER) {
		getArrayType(_expr.left, pType);
		retrieveChunk(pType->subtype, pType);
	}
	else if (_expr.kind == EXPR_NAME) {
		struct symbol sym;
		char name[CHUNK_LEN + 1];

		retrieveChunk(_expr.name, name);
		if (!scope_lookup(name, &sym)) {
			Error(errUndefinedIdentifier);
			pType->kind = TYPE_VOID;
		}

		retrieveChunk(sym.type, pType);
	}
	else if (_expr.kind == EXPR_FIELD) {
		expr_typecheck(exprChunk, 0, pType, 0);
	}
	else {
		Error(errUndefinedIdentifier);
		pType->kind = TYPE_VOID;
	}
}

static void expr_literal(struct expr* pExpr, struct type* pType)
{
	switch (pExpr->kind) {
	case EXPR_BOOLEAN_LITERAL:
		pType->kind = TYPE_BOOLEAN;
		pType->flags = TYPE_FLAG_ISCONST;
		pType->size = sizeof(char);
		break;

	case EXPR_BYTE_LITERAL:
		pType->kind = (!pExpr->neg && pExpr->value.byte > SCHAR_MAX) ? TYPE_BYTE : TYPE_SHORTINT;
		pType->flags = TYPE_FLAG_ISCONST;
		if (pExpr->neg && pExpr->value.byte > SCHAR_MAX) {
			pType->kind = TYPE_INTEGER;
			pType->size = sizeof(short);
			pExpr->kind = EXPR_WORD_LITERAL;
		} else {
			pType->size = sizeof(char);
		}
		break;

	case EXPR_WORD_LITERAL:
		pType->kind = (!pExpr->neg && pExpr->value.word > SHRT_MAX) ? TYPE_WORD : TYPE_INTEGER;
		if (pExpr->neg && pExpr->value.word >= SHRT_MAX) {
			pType->kind = TYPE_LONGINT;
			pType->size = sizeof(long);
			pExpr->kind = EXPR_DWORD_LITERAL;
		} else {
			pType->size = sizeof(short);
		}
		pType->flags = TYPE_FLAG_ISCONST;
		break;

	case EXPR_DWORD_LITERAL:
		pType->kind = (!pExpr->neg && pExpr->value.cardinal > LONG_MAX) ? TYPE_CARDINAL : TYPE_LONGINT;
		pType->flags = TYPE_FLAG_ISCONST;
		pType->size = sizeof(long);
		break;

	case EXPR_STRING_LITERAL:
		pType->kind = TYPE_STRING_LITERAL;
		pType->flags = TYPE_FLAG_ISCONST;
		pType->size = sizeof(char*);
		break;

	case EXPR_CHARACTER_LITERAL:
		pType->kind = TYPE_CHARACTER;
		pType->flags = TYPE_FLAG_ISCONST;
		pType->size = sizeof(char);
		break;

	case EXPR_REAL_LITERAL:
		pType->kind = TYPE_REAL;
		pType->flags = TYPE_FLAG_ISCONST;
		pType->size = sizeof(FLOAT);
		break;
	}
}

static void expr_typecheck(CHUNKNUM chunkNum, CHUNKNUM recordSymtab, struct type* pType, char parentIsFuncCall)
{
	struct expr _expr;
	struct type leftType, rightType;
	struct symbol sym;

	memset(pType, 0, sizeof(struct type));

	if (!chunkNum) {
		pType->kind = TYPE_VOID;
		return;
	}

	retrieveChunk(chunkNum, &_expr);

	if (_expr.kind == EXPR_ARRAY_LITERAL) {
		chunkNum = _expr.left;
		while (chunkNum) {
			retrieveChunk(chunkNum, &_expr);
			memset(&leftType, 0, sizeof(struct type));
			if (_expr.kind == EXPR_ARRAY_LITERAL) {
				expr_typecheck(chunkNum, recordSymtab, &leftType, 0);
			} else {
				expr_literal(&_expr, &leftType);
				saveEvalType(chunkNum, &_expr, &leftType);
			}
			chunkNum = _expr.right;
		}
		return;
	}

	expr_typecheck(_expr.left, recordSymtab, &leftType,
		(_expr.kind == EXPR_CALL || _expr.kind == EXPR_ADDRESS_OF) ? 1 : 0);
	if (_expr.kind == EXPR_ARG) {
		memcpy(pType, &leftType, sizeof(struct type));
		if (_expr.evalType) {
			freeChunk(_expr.evalType);
		}
		allocChunk(&_expr.evalType);
		storeChunk(_expr.evalType, pType);
		storeChunk(chunkNum, &_expr);
		return;
	}
	expr_typecheck(_expr.right, recordSymtab, &rightType, _expr.kind == EXPR_CALL ? 1 : 0);
	
	switch (_expr.kind) {
	case EXPR_BOOLEAN_LITERAL:
	case EXPR_BYTE_LITERAL:
	case EXPR_WORD_LITERAL:
	case EXPR_DWORD_LITERAL:
	case EXPR_STRING_LITERAL:
	case EXPR_CHARACTER_LITERAL:
	case EXPR_REAL_LITERAL:
		expr_literal(&_expr, pType);
		break;

	case EXPR_ADD:
		if (isConcatOperand(_expr.left) && isConcatOperand(_expr.right)) {
			pType->kind = TYPE_STRING_OBJ;
			pType->size = 2;
		} else if (leftType.kind == TYPE_POINTER) {
			if (!isTypeInteger(rightType.kind)) {
				Error(errIncompatibleTypes);
				pType->kind = TYPE_VOID;
			} else {
				pType->kind = TYPE_ADDRESS;
			}
		} else {
			pType->kind = realOperands(leftType.kind, rightType.kind, &pType->size);
		}
		break;

	case EXPR_SUB:
	case EXPR_MUL:
		if (leftType.kind == TYPE_POINTER) {
			if (_expr.kind != EXPR_SUB || !isTypeInteger(rightType.kind)) {
				Error(errIncompatibleTypes);
				pType->kind = TYPE_VOID;
			} else {
				pType->kind = TYPE_ADDRESS;
			}
		} else {
			pType->kind = realOperands(leftType.kind, rightType.kind, &pType->size);
		}
		break;

	case EXPR_DIV:
		pType->kind = TYPE_REAL;
		pType->size = sizeof(FLOAT);
		break;

	case EXPR_DIVINT:
	case EXPR_MOD:
		pType->kind = integerOperands(leftType.kind, rightType.kind, &pType->size);
		break;

	case EXPR_LT:
	case EXPR_LTE:
	case EXPR_GT:
	case EXPR_GTE:
	case EXPR_NE:
	case EXPR_EQ:
		checkRelOpOperands(&leftType, &rightType);
		pType->kind = TYPE_BOOLEAN;
		pType->size = sizeof(char);
		break;

	case EXPR_OR:
	case EXPR_AND:
		checkBoolOperand(&leftType);
		checkBoolOperand(&rightType);
		pType->kind = TYPE_BOOLEAN;
		pType->size = sizeof(char);
		break;

	case EXPR_BITWISE_AND:
	case EXPR_BITWISE_OR:
		pType->kind = typeConversions[leftType.kind-1][rightType.kind-1];
		if (pType->kind == TYPE_VOID) {
			Error(errIncompatibleTypes);
		} else {
			pType->size = GET_TYPE_SIZE(getTypeMask(pType->kind));
		}
		break;

	case EXPR_BITWISE_LSHIFT:
	case EXPR_BITWISE_RSHIFT:
		if (!isTypeInteger(leftType.kind) || !isTypeInteger(rightType.kind)) {
			Error(errInvalidType);
			pType->kind = TYPE_VOID;
			break;
		}
		pType->kind = leftType.kind;
		pType->size = leftType.size;
		break;

	case EXPR_NOT:
		if (leftType.kind == TYPE_BOOLEAN) {
			// Logical not
			pType->kind = TYPE_BOOLEAN;
			pType->size = sizeof(char);
		} else if (isTypeInteger(leftType.kind)) {
			// Bitwise complement
			pType->kind = leftType.kind;
			pType->size = leftType.size;
		} else {
			Error(errIncompatibleTypes);
		}
		break;

	case EXPR_ASSIGN: {
		if (isExprATypeDeclaration(_expr.left)) {
			Error(errInvalidIdentifierUsage);
			pType->kind = TYPE_VOID;
			break;
		}

		if (isExprAFuncCall(_expr.left)) {
			Error(errInvalidIdentifierUsage);
			pType->kind = TYPE_VOID;
			break;
		}

		if (leftType.flags & TYPE_FLAG_ISCONST || leftType.kind == TYPE_ENUMERATION_VALUE) {
			Error(errIncompatibleAssignment);
			pType->kind = TYPE_VOID;
			break;
		}
		getBaseType(&leftType);
		getBaseType(&rightType);

		checkAssignment(&leftType, &rightType, pType, _expr.right);
		break;
	}

	case EXPR_NAME:
		// Look up the node
		if (!_expr.node) {
			Error(errUndefinedIdentifier);
			break;
		}
		retrieveChunk(_expr.node, &sym);
		retrieveChunk(sym.type, &leftType);
		if (leftType.subtype == 0) {
			leftType.subtype = sym.type;
		}
		pType->kind = leftType.kind;
		pType->flags = leftType.flags; // | TYPE_FLAG_ISCONST;
		pType->subtype = leftType.subtype;
		pType->paramsFields = leftType.paramsFields;
		pType->size = leftType.size;
		if (leftType.kind == TYPE_ARRAY) {
			pType->indextype = leftType.indextype;
		}
		if (leftType.kind == TYPE_FUNCTION && !parentIsFuncCall) {
			hoistFuncCall(chunkNum);
			checkFuncProcCall(chunkNum, pType);
			retrieveChunk(chunkNum, &_expr);
		}
		break;

	case EXPR_CALL:
		checkFuncProcCall(chunkNum, pType);
		break;

	case EXPR_ARG:
		pType->kind = TYPE_VOID;
		break;

	case EXPR_SUBSCRIPT: {
		struct type arrayType, indexType, elemType;
		getArrayType(_expr.left, &arrayType);
		getBaseType(&arrayType);
		if (arrayType.kind == TYPE_STRING_VAR) {
			struct expr rightExpr;
			struct type subscriptType;
			retrieveChunk(_expr.right, &rightExpr);
			retrieveChunk(rightExpr.evalType, &subscriptType);
			getBaseType(&subscriptType);
			if (!isTypeInteger(subscriptType.kind)) {
				Error(errInvalidIndexType);
				pType->kind = TYPE_VOID;
			} else {
				pType->kind = TYPE_CHARACTER;
			}
			break;
		}
		else if (arrayType.kind != TYPE_ARRAY) {
			Error(errInvalidType);
			pType->kind = TYPE_VOID;
			break;
		}
		retrieveChunk(arrayType.subtype, &elemType);
		getBaseType(&elemType);
		retrieveChunk(arrayType.indextype, &indexType);
		getBaseType(&indexType);
		if (indexType.kind == TYPE_ENUMERATION &&
			(rightType.kind == TYPE_ENUMERATION || rightType.kind == TYPE_ENUMERATION_VALUE)) {
			if (indexType.subtype != rightType.subtype) {
				Error(errInvalidIndexType);
			}
		}
		else if (rightType.kind != indexType.kind) {
			if (isTypeInteger(rightType.kind) && isTypeInteger(indexType.kind)) {
				if (typeConversions[rightType.kind-1][indexType.kind-1] == TYPE_VOID) {
					Error(errInvalidIndexType);
				}
			} else {
				Error(errInvalidIndexType);
			}
		}
		pType->kind = elemType.kind;
		pType->flags = elemType.flags & TYPE_FLAG_ISCONST;
		pType->subtype = elemType.subtype;
		pType->size = elemType.size;
		pType->symtab = elemType.symtab;
		break;
	}

	case EXPR_FIELD:
		if (isExprATypeDeclaration(_expr.left)) {
			Error(errInvalidIdentifierUsage);
			pType->kind = TYPE_VOID;
			break;
		}
		// Grab the symbol table from the left child
		if (_expr.node == 0) {
			struct expr exprLeft;
			retrieveChunk(_expr.left, &exprLeft);
			while (1) {
				if (exprLeft.kind == EXPR_FIELD || exprLeft.kind == EXPR_SUBSCRIPT) {
					retrieveChunk(exprLeft.left, &exprLeft);
					continue;
				}
				if (!exprLeft.node && exprLeft.kind == EXPR_POINTER) {
					retrieveChunk(exprLeft.left, &exprLeft);
				}
				retrieveChunk(exprLeft.node, &sym);
				retrieveChunk(sym.type, &rightType);
				expr_typecheck(_expr.right, rightType.symtab, pType, 0);
				pType->symtab = rightType.symtab;
				break;
			}
		}
		else {
			retrieveChunk(_expr.node, &sym);
			retrieveChunk(sym.type, &rightType);
			expr_typecheck(_expr.right, rightType.symtab, pType, 0);
			pType->symtab = rightType.symtab;
		}
		break;

	case EXPR_ARRAY_LITERAL:
		// Do nothing here. This is checked in decl_typecheck.
		break;
	
	case EXPR_ADDRESS_OF:
		if (leftType.kind == TYPE_PROCEDURE || leftType.kind == TYPE_FUNCTION) {
			pType->kind = TYPE_ROUTINE_ADDRESS;
		} else {
			pType->kind = TYPE_ADDRESS;
		}
		pType->subtype = typeCreate(leftType.kind, 0, 0, 0);
		break;
	
	case EXPR_POINTER:
		if (_expr.evalType) {
			retrieveChunk(_expr.evalType, &leftType);
		} else {
			struct expr leftExpr;
			retrieveChunk(_expr.left, &leftExpr);
			retrieveChunk(leftExpr.evalType, &leftType);
		}
		if (leftType.subtype)
			retrieveChunk(leftType.subtype, &leftType);
		pType->kind = leftType.kind;
		pType->name = leftType.name;
		break;

	default:
		Error(errInvalidType);
		pType->kind = TYPE_VOID;
	}

	saveEvalType(chunkNum, &_expr, pType);
}

// This function takes a bare EXPR_NAME node and replaces it
// with an EXPR_CALL node in the AST.
static void hoistFuncCall(CHUNKNUM chunkNum)
{
	struct expr _expr;
	CHUNKNUM newNameChunk;

	allocChunk(&newNameChunk);
	retrieveChunk(chunkNum, &_expr);
	storeChunk(newNameChunk, &_expr);

	_expr.kind = EXPR_CALL;
	_expr.left = newNameChunk;
	_expr.right = 0;
	_expr.node = 0;
	storeChunk(chunkNum, &_expr);
}

static char isAssignableToString(char rightKind, CHUNKNUM rightSubType)
{
	struct type rightType;

	if (rightKind == TYPE_ARRAY) {
		retrieveChunk(rightSubType, &rightType);
		if (rightType.kind == TYPE_CHARACTER) {
			return 1;
		}
	}
	else if (rightKind == TYPE_STRING_VAR ||
		rightKind == TYPE_STRING_LITERAL ||
		rightKind == TYPE_STRING_OBJ ||
		rightKind == TYPE_CHARACTER) {
			return 1;
	}

	return 0;
}

static char isAssignmentCompatible(char leftKind, struct type *rightType)
{
	char rightKind = rightType->kind;
	char leftMask = getTypeMask(leftKind);
	char rightMask = getTypeMask(rightKind);

	if (leftKind == rightKind) {
		return 1;
	}

	return (isTypeInteger(leftKind) && isTypeInteger(rightKind)) ? 1 : 0;
}

static char isExprAFuncCall(CHUNKNUM exprChunk)
{
	struct expr _expr;

	retrieveChunk(exprChunk, &_expr);

	return _expr.kind == EXPR_CALL;
}

static char isExprATypeDeclaration(CHUNKNUM exprChunk)
{
	char name[CHUNK_LEN + 1];
	struct expr _expr;
	struct symbol sym;
	struct decl _decl;

	retrieveChunk(exprChunk, &_expr);
	if (_expr.kind != EXPR_NAME) {
		return 0;
	}

	memset(name, 0, sizeof(name));
	retrieveChunk(_expr.name, name);

	if (!scope_lookup(name, &sym) ||
		!sym.decl) {
		return 0;
	}

	retrieveChunk(sym.decl, &_decl);
	return _decl.kind == DECL_TYPE ? 1 : 0;
}

static char isTypeOrdinal(char type)
{
	return isTypeInteger(type) || type == TYPE_ENUMERATION ? 1 : 0;
}

static char isTypeNumeric(char type)
{
	return (type == TYPE_INTEGER ||
		type == TYPE_SHORTINT ||
		type == TYPE_BYTE ||
		type == TYPE_INTEGER ||
		type == TYPE_WORD ||
		type == TYPE_LONGINT ||
		type == TYPE_CARDINAL ||
		type == TYPE_REAL) ? 1 : 0;
}

static void saveEvalType(CHUNKNUM chunkNum, struct expr* pExpr, struct type* pType)
{
	if (pExpr->evalType) {
		freeChunk(pExpr->evalType);
	}
	allocChunk(&pExpr->evalType);
	storeChunk(pExpr->evalType, pType);
	storeChunk(chunkNum, pExpr);
}

void stmt_typecheck(CHUNKNUM chunkNum)
{
	struct stmt _stmt;
	struct type _type;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_stmt);
		currentLineNumber = _stmt.lineNumber;

		switch (_stmt.kind) {
		case STMT_EXPR:
			expr_typecheck(_stmt.expr, 0, &_type, 0);
			break;

		case STMT_IF_ELSE:
			expr_typecheck(_stmt.expr, 0, &_type, 0);
			if (_type.kind != TYPE_BOOLEAN) {
				Error(errInvalidType);
			}
			stmt_typecheck(_stmt.body);
			stmt_typecheck(_stmt.else_body);
			break;

		case STMT_FOR:
			expr_typecheck(_stmt.init_expr, 0, &_type, 0);
			if (!isTypeInteger(_type.kind)) {
				Error(errInvalidType);
			}
			expr_typecheck(_stmt.to_expr, 0, &_type, 0);
			if (!isTypeInteger(_type.kind)) {
				Error(errInvalidType);
			}
			stmt_typecheck(_stmt.body);
			break;

		case STMT_WHILE:
		case STMT_REPEAT:
			expr_typecheck(_stmt.expr, 0, &_type, 0);
			if (_type.kind != TYPE_BOOLEAN) {
				Error(errInvalidType);
			}
			stmt_typecheck(_stmt.body);
			break;

		case STMT_CASE:
			expr_typecheck(_stmt.expr, 0, &_type, 0);
			if (!isTypeInteger(_type.kind) &&
				_type.kind != TYPE_CHARACTER &&
				_type.kind != TYPE_ENUMERATION) {
				Error(errIncompatibleTypes);
			}
			caseTypeCheck(_type.kind, _type.subtype, _stmt.body);
			break;

		case STMT_BLOCK:
			stmt_typecheck(_stmt.body);
			decl_typecheck(_stmt.decl);
			break;
		}

		chunkNum = _stmt.next;
	}
}

void typecheck_units(void)
{
	struct unit _unit;
	CHUNKNUM chunkNum = units;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);
		decl_typecheck(_unit.astRoot);

		chunkNum = _unit.next;
	}
}
