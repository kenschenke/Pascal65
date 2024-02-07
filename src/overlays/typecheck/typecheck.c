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

static long intRanges[] = {
	SCHAR_MAX,
	SHRT_MAX,
	LONG_MAX,
};

/*
; |----------------------------------------------------------------------------------|
; |          | Byte     | ShortInt | Word     | Integer  | Cardinal | LongInt | Real |
; |----------|----------|----------|----------|----------|----------|----------------|
; | Byte     | Byte     | Integer  | Word     | Integer  | Cardinal | LongInt | Real |
; | ShortInt | Integer  | ShortInt | LongInt  | Integer  | LongInt  | LongInt | Real |
; | Word     | Word     | Word     | Word     | LongInt  | Cardinal | LongInt | Real |
; | Integer  | Integer  | Integer  | LongInt  | Integer  | LongInt  | LongInt | Real |
; | Cardinal | Cardinal | Cardinal | Cardinal | Cardinal | Cardinal |    -    | Real |
; | LongInt  | LongInt  | LongInt  | LongInt  | LongInt  |    -     | LongInt | Real |
; | Real     | Real     | Real     | Real     | Real     | Real     | Real    | Real |
; |----------------------------------------------------------------------------------|
*/

static char typeConversions[7][7] = {
	{ TYPE_BYTE,     TYPE_INTEGER,  TYPE_WORD,     TYPE_INTEGER,  TYPE_CARDINAL, TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_INTEGER,  TYPE_SHORTINT, TYPE_LONGINT,  TYPE_INTEGER,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_WORD,     TYPE_WORD,     TYPE_WORD,     TYPE_LONGINT,  TYPE_CARDINAL, TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_INTEGER,  TYPE_INTEGER,  TYPE_LONGINT,  TYPE_INTEGER,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_VOID,     TYPE_REAL },
	{ TYPE_LONGINT,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_VOID,     TYPE_LONGINT,  TYPE_REAL },
	{ TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL },
};

static void caseTypeCheck(char exprKind, CHUNKNUM subtype, CHUNKNUM labelChunk);
static char checkAbsSqrCall(CHUNKNUM argChunk, char routineCode);		// returns TYPE_*
static void checkArraysSameType(struct type* pType1, struct type* pType2);
static void checkBoolOperand(struct type* pType);
static void checkForwardVsFormalDeclaration(CHUNKNUM fwdParams, CHUNKNUM formalParams);
static void checkFuncProcCall(CHUNKNUM exprChunk, struct type* pRetnType);
static void checkIntegerBaseType(CHUNKNUM exprChunk);
static void checkPredSuccCall(CHUNKNUM argChunk, struct type* pRetnType);
static void checkReadReadlnCall(CHUNKNUM argChunk);
static void checkRelOpOperands(struct type* pType1, struct type* pType2);
static void checkStdParms(CHUNKNUM argChunk, char allowedParms);
static void checkStdRoutine(struct type* pType, CHUNKNUM argChunk, struct type* pRetnType);
static void checkWriteWritelnCall(CHUNKNUM argChunk);
static void expr_typecheck(CHUNKNUM chunkNum, CHUNKNUM recordSymtab, struct type* pType, char parentIsFuncCall);
static void getArrayType(CHUNKNUM exprChunk, struct type* pType);
static void hoistFuncCall(CHUNKNUM chunkNum);
static char integerOperands(char type1Kind, char type2Kind, short *pSize);
static char isAssignmentCompatible(char leftKind, struct type *rightType,
	struct expr *rightExpr);
static char isExprAFuncCall(CHUNKNUM exprChunk);
static char isExprATypeDeclaration(CHUNKNUM exprChunk);
static char isTypeOrdinal(char type);
static char isTypeNumeric(char type);
static char realOperands(char type1Kind, char type2Kind, short *pSize);

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

static void checkBoolOperand(struct type* pType)
{
	if (pType->kind != TYPE_BOOLEAN) {
		Error(errIncompatibleTypes);
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
	if (_type.flags & TYPE_FLAG_ISRETVAL) {
		if (!scope_lookup_parent(name, &sym)) {
			Error(errUndefinedIdentifier);
			pRetnType->kind = TYPE_VOID;
		}
		retrieveChunk(sym.type, &_type);
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
		else if (paramType.kind != argType.kind) {
			Error(errInvalidType);
		}
		if (paramType.flags & TYPE_FLAG_ISBYREF) {
			retrieveChunk(exprArg.left, &exprLeft);
			if (exprLeft.kind != EXPR_NAME && exprLeft.kind != EXPR_FIELD) {
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

static void checkReadReadlnCall(CHUNKNUM argChunk)
{
	char name[CHUNK_LEN + 1];
	struct expr _expr, exprLeft;
	struct symbol sym;
	struct type _type, subtype;

	while (argChunk)
	{
		retrieveChunk(argChunk, &_expr);
		argChunk = _expr.right;
		retrieveChunk(_expr.left, &exprLeft);
		if (exprLeft.kind != EXPR_NAME) {
			Error(errInvalidVarParm);
			continue;
		}

		retrieveChunk(exprLeft.name, name);
		if (!scope_lookup(name, &sym)) {
			Error(errUndefinedIdentifier);
			continue;
		}

		retrieveChunk(sym.type, &_type);
		getBaseType(&_type);
		switch (_type.kind) {
		case TYPE_ARRAY:
			retrieveChunk(_type.subtype, &subtype);
			getBaseType(&subtype);
			if (subtype.kind != TYPE_CHARACTER) {
				Error(errIncompatibleTypes);
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

		default:
			Error(errIncompatibleTypes);
			break;
		}
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
		checkReadReadlnCall(argChunk);
		pRetnType->kind = TYPE_VOID;
		break;

	case rcWrite:
	case rcWriteln:
		checkWriteWritelnCall(argChunk);
		pRetnType->kind = TYPE_VOID;
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

	default:
		pRetnType->kind = TYPE_VOID;
		break;
	}
}

static void checkWriteWritelnCall(CHUNKNUM argChunk)
{
	struct expr _expr, exprLeft;
	struct type _type, subtype;

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
			if (subtype.kind != TYPE_CHARACTER) {
				Error(errIncompatibleTypes);
			}
			checkIntegerBaseType(exprLeft.width);
			checkIntegerBaseType(exprLeft.precision);
		} else if (_type.kind == TYPE_REAL ||
			_type.kind == TYPE_CHARACTER ||
			_type.kind == TYPE_BOOLEAN ||
			isTypeInteger(_type.kind)) {
			checkIntegerBaseType(exprLeft.width);
			checkIntegerBaseType(exprLeft.precision);
		} else if (_type.kind != TYPE_STRING_LITERAL &&
			_type.kind != TYPE_STRING_VAR &&
			_type.kind != TYPE_STRING_OBJ) {
			Error(errIncompatibleTypes);
		}

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

	// If both operands are integers and one or both operands are signed,
	// the result must be one size higher than the largest operand.
	if (isTypeInteger(type1Kind) && isTypeInteger(type2Kind)) {
		char leftMask = getTypeMask(type1Kind);
		char rightMask = getTypeMask(type2Kind);
		char resultMask = getTypeMask(resultKind);
		char leftSize = GET_TYPE_SIZE(leftMask);
		char rightSize = GET_TYPE_SIZE(rightMask);
		if ((IS_TYPE_SIGNED(leftMask) || IS_TYPE_SIGNED(rightMask)) && !IS_TYPE_SIGNED(resultKind)) {
			if (resultKind == TYPE_BYTE) {
				resultKind = TYPE_INTEGER;
			} else if (resultKind == TYPE_WORD) {
				resultKind = TYPE_LONGINT;
			}
		}
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
			// an integer, enum, or character.
			// Only do the check if this is a variable and the type
			// is an anonymous type (defined inline) or this declaration
			// is the array type (Type section).
			if (((_decl.kind == DECL_VARIABLE && _type.name == 0) || _decl.kind == DECL_TYPE) && _type.kind == TYPE_ARRAY) {
				retrieveChunk(_type.indextype, &_type);
				getBaseType(&_type);
				if (!isTypeOrdinal(_type.kind) && _type.kind != TYPE_CHARACTER) {
					Error(errInvalidIndexType);
				}
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
	if (_expr.kind == EXPR_SUBSCRIPT) {
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

	expr_typecheck(_expr.left, recordSymtab, &leftType, _expr.kind == EXPR_CALL ? 1 : 0);
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
		pType->kind = TYPE_BOOLEAN;
		pType->flags = TYPE_FLAG_ISCONST;
		pType->size = sizeof(char);
		break;

	case EXPR_BYTE_LITERAL:
		pType->kind = (!_expr.neg && _expr.value.byte > SCHAR_MAX) ? TYPE_BYTE : TYPE_SHORTINT;
		pType->flags = TYPE_FLAG_ISCONST;
		if (_expr.neg && _expr.value.byte > SCHAR_MAX) {
			pType->kind = TYPE_INTEGER;
			pType->size = sizeof(short);
			_expr.kind = EXPR_WORD_LITERAL;
		} else {
			pType->size = sizeof(char);
		}
		break;

	case EXPR_WORD_LITERAL:
		pType->kind = (!_expr.neg && _expr.value.word > SHRT_MAX) ? TYPE_WORD : TYPE_INTEGER;
		if (_expr.neg && _expr.value.word >= SHRT_MAX) {
			pType->kind = TYPE_LONGINT;
			pType->size = sizeof(long);
			_expr.kind = EXPR_DWORD_LITERAL;
		} else {
			pType->size = sizeof(short);
		}
		pType->flags = TYPE_FLAG_ISCONST;
		break;

	case EXPR_DWORD_LITERAL:
		pType->kind = _expr.value.cardinal > LONG_MAX ? TYPE_CARDINAL : TYPE_LONGINT;
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

	case EXPR_ADD:
		if (isConcatOperand(_expr.left) && isConcatOperand(_expr.right)) {
			pType->kind = TYPE_STRING_OBJ;
			pType->size = 2;
		} else {
			pType->kind = realOperands(leftType.kind, rightType.kind, &pType->size);
		}
		break;

	case EXPR_SUB:
	case EXPR_MUL:
		pType->kind = realOperands(leftType.kind, rightType.kind, &pType->size);
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

	case EXPR_NOT:
		checkBoolOperand(&leftType);
		pType->kind = TYPE_BOOLEAN;
		pType->size = sizeof(char);
		break;

	case EXPR_ASSIGN: {
		struct expr exprRight;
		retrieveChunk(_expr.right, &exprRight);
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

		if (leftType.kind == TYPE_REAL &&
			(rightType.kind == TYPE_REAL || isTypeInteger(rightType.kind))) {
			pType->kind = TYPE_REAL;
			pType->size = sizeof(FLOAT);
		}
		else if (leftType.kind == TYPE_CHARACTER && rightType.kind == TYPE_CHARACTER) {
			pType->kind = TYPE_CHARACTER;
			pType->size = sizeof(char);
		}
		else if (leftType.kind == TYPE_BOOLEAN && rightType.kind == TYPE_BOOLEAN) {
			pType->kind = TYPE_BOOLEAN;
			pType->size = sizeof(char);
		}
		else if (leftType.kind == TYPE_STRING_VAR) {
			if (rightType.kind == TYPE_ARRAY) {
				retrieveChunk(rightType.subtype, &rightType);
				if (rightType.kind != TYPE_CHARACTER) {
					Error(errIncompatibleAssignment);
					pType->kind = TYPE_VOID;
					break;
				}
			}
			else if (rightType.kind != TYPE_STRING_VAR &&
				rightType.kind != TYPE_STRING_LITERAL &&
				rightType.kind != TYPE_STRING_OBJ) {
				Error(errIncompatibleAssignment);
				pType->kind = TYPE_VOID;
				break;
			}
			pType->kind = leftType.kind;
			pType->size = 2;
		}
		else if (isAssignmentCompatible(leftType.kind, &rightType, &exprRight)) {
			pType->kind = leftType.kind;
			pType->size = GET_TYPE_SIZE(getTypeMask(leftType.kind));
		}
		else if (leftType.kind == TYPE_ENUMERATION &&
			(rightType.kind == TYPE_ENUMERATION || rightType.kind == TYPE_ENUMERATION_VALUE)) {
			if (leftType.subtype != rightType.subtype) {
				Error(errIncompatibleAssignment);
			}
			pType->kind = TYPE_VOID;
		}
		else {
			Error(errIncompatibleAssignment);
			pType->kind = TYPE_VOID;
		}
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
			}
			pType->kind = TYPE_CHARACTER;
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

	default:
		Error(errInvalidType);
		pType->kind = TYPE_VOID;
	}

	if (_expr.evalType) {
		freeChunk(_expr.evalType);
	}
	allocChunk(&_expr.evalType);
	storeChunk(_expr.evalType, pType);
	storeChunk(chunkNum, &_expr);
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

static char isAssignmentCompatible(char leftKind, struct type *rightType,
	struct expr *rightExpr)
{
	char rightKind = rightType->kind;
	char leftMask = getTypeMask(leftKind);
	char rightMask = getTypeMask(rightKind);

	if (leftKind == rightKind) {
		return 1;
	}

	if (!isTypeInteger(leftKind) || !isTypeInteger(rightKind)) {
		return 0;
	}

	// If the left is unsigned, the right cannot be signed
	// unless it's a constant and between zero and the maximum
	// signed value for that type.
	if (!IS_TYPE_SIGNED(leftMask) && IS_TYPE_SIGNED(rightMask)) {
		if (!(rightType->flags & TYPE_FLAG_ISCONST) ||
			GET_TYPE_SIZE(rightMask) > GET_TYPE_SIZE(leftMask) ||
			(rightExpr->neg || rightExpr->value.longInt > intRanges[GET_TYPE_SIZE(rightMask)/2])) {
				return 0;
			}
	}

	// If the left is signed and the right is unsigned, the left
	// must be a larger data type.
	if (IS_TYPE_SIGNED(leftMask) && !IS_TYPE_SIGNED(rightMask) &&
		GET_TYPE_SIZE(leftMask) <= GET_TYPE_SIZE(rightMask)) {
			return 0;
	}

	// The left must be equal to or larger in size than the right.
	return GET_TYPE_SIZE(leftMask) >= GET_TYPE_SIZE(rightMask) ? 1 : 0;
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
