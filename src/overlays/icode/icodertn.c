/**
 * icodertn.c
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
#include <misc.h>
#include <symtab.h>
#include <codegen.h>
#include <string.h>
#include <int16.h>
#include <libcommon.h>
#include <asm.h>

static 	char name[CHUNK_LEN + 1], enterLabel[15];

static void icodeDecIncCall(TRoutineCode rc, CHUNKNUM argChunk);
static char icodeDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk, char isRtnPtr, struct symbol *pSym);
static char icodeLibrarySubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk, char isRtnPtr, struct symbol *pSym);
static void icodeReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk);
static short icodeRoutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk,
	char *returnLabel, char isLibraryCall, char isRtnPtr, struct symbol *pSym);
static void icodeRoutineCleanup(char *localVars, struct type* pDeclType,
	int numLocals, char isFunc, char isLibrary);
static void icodeRoutineDeclaration(CHUNKNUM chunkNum, struct decl* pDecl, struct type* pDeclType);
static char icodeStdRoutineCall(TRoutineCode rc, CHUNKNUM argChunk);
static void icodeWriteWritelnCall(TRoutineCode rc, CHUNKNUM argChunk);

static void icodeDecIncCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	char amountType;
	CHUNKNUM varChunk;
	struct expr arg, varExpr;
	struct type amtType, varType;

	retrieveChunk(argChunk, &arg);
	varChunk = arg.left;

	retrieveChunk(varChunk, &varExpr);
	retrieveChunk(varExpr.evalType, &varType);
	if (varType.kind == TYPE_CHARACTER) {
		varType.kind = TYPE_SHORTINT;
	}
	if (varType.kind == TYPE_ENUMERATION) {
		varType.kind = TYPE_INTEGER;
	}

	icodeExprRead(varChunk);	// push variable value onto stack

	if (arg.right) {
		retrieveChunk(arg.right, &arg);
		icodeExprRead(arg.left);
		retrieveChunk(arg.left, &arg);
		retrieveChunk(arg.evalType, &amtType);
		amountType = amtType.kind;
	} else {
		icodeWriteUnaryShort(IC_PSH, 1);
		amountType = TYPE_BYTE;
	}

	if (varType.kind == TYPE_POINTER) {
		struct type subtype;
		// The increment amount needs to be multiplied by the
		// size of the pointer's data type.
		retrieveChunk(varType.subtype, &subtype);
		icodeWriteUnary(IC_PSH, icodeOperInt(1, subtype.size));
		icodeWriteTrinaryShort(IC_MUL, amountType, TYPE_INTEGER, amountType);
	}

	icodeWriteTrinaryShort(rc == rcInc ? IC_ADD : IC_SUB,
		varType.kind, amountType, varType.kind);

	icodeExpr(varChunk, 0);	// push variable address onto stack
	icodeWriteBinaryShort(IC_SET, varType.kind, varType.kind);
}

static char icodeDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk, char isRtnPtr, struct symbol *pSym)
{
	char returnLabel[15];
	short level;
	struct type rtnType;

	level = icodeRoutineCall(exprChunk, declChunk, pType, argChunk, returnLabel, 0, isRtnPtr, pSym);

	// Call the routine
	if (isRtnPtr) {
		icodeWriteMnemonic(IC_JRP);
		// icodeWriteBinaryShort(IC_JRP, level, 0);
	} else {
		icodeFormatLabel(enterLabel, "RTNENTER", declChunk);
		icodeWriteTrinary(IC_JSR, icodeOperLabel(1, enterLabel),
			icodeOperShort(2, level), icodeOperShort(3, 0));
	}

	icodeWriteUnaryLabel(IC_LOC, returnLabel);

	retrieveChunk(pType->subtype, &rtnType);
	return rtnType.kind;
}

static char icodeLibrarySubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk, char isRtnPtr, struct symbol *pSym)
{
	struct type rtnType;
	short level;
	char localVars[MAX_LOCAL_VARS];
	int numLocal = 0;
	char returnLabel[15];

	memset(localVars, 0, sizeof(localVars));
	level = icodeRoutineCall(exprChunk, declChunk, pType, argChunk, returnLabel, 1, isRtnPtr, pSym);

	// Call the routine
	if (isRtnPtr) {
		icodeWriteMnemonic(IC_JRP);
		// icodeWriteBinaryShort(IC_JRP, level, 1);
	} else {
		icodeFormatLabel(enterLabel, "RTNENTER", declChunk);
		icodeWriteTrinary(IC_JSR, icodeOperLabel(1, enterLabel),
			icodeOperShort(2, level), icodeOperBool(3, 1));
	}

	icodeWriteUnaryLabel(IC_LOC, returnLabel);

	// Tear down the routine's stack frame and free parameters
	icodeRoutineCleanup(localVars, pType, numLocal,
		(pType->kind == TYPE_PROCEDURE) ? 0 : 1, 1);

	retrieveChunk(pType->subtype, &rtnType);
	return rtnType.kind;
}

static void icodeReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	char argValue, readBytes = 0;
	struct expr arg;
	struct type _type;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &_type);
	if (_type.kind == TYPE_FILE || _type.kind == TYPE_TEXT) {
		icodeExprRead(arg.left);
		argValue = FH_FILENUM;
		argChunk = arg.right;
		readBytes = _type.kind == TYPE_FILE ? 1 : 0;
	} else {
		argValue = FH_STDIO;
	}

	icodeWriteBinaryShort(IC_SFH, argValue, 1);

	while (argChunk) {
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &_type);

		if (readBytes) {
			icodeExpr(arg.left,
				(_type.kind == TYPE_ARRAY || _type.kind == TYPE_RECORD) ? 1 : 0);
			icodeWriteUnaryWord(IC_PSH, _type.size);
			icodeWriteUnaryShort(IC_INP,
				(_type.kind == TYPE_ARRAY || _type.kind == TYPE_RECORD) ?
					TYPE_HEAP_BYTES : TYPE_SCALAR_BYTES);
		} else {
			icodeExpr(arg.left, 0);
			icodeWriteUnaryShort(IC_INP, _type.kind);
		}

		argChunk = arg.right;
	}

	if (rc == rcReadln) {
		icodeWriteMnemonic(IC_CNL);
	}

	icodeWriteBinaryShort(IC_SFH, 0, 1);
}

static short icodeRoutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk,
	char *returnLabel, char isLibraryCall, char isRtnPtr, struct symbol *pSym)
{
	char stringObjHeaps = 0;
	CHUNKNUM paramChunk = pType->paramsFields;
	struct expr _expr;
	struct decl _decl;
	struct param_list param;
	struct type argType, paramType;
	struct symbol sym;

	retrieveChunk(declChunk, &_decl);
	retrieveChunk(_decl.node, &sym);

	// Set up the stack frame
	icodeFormatLabel(returnLabel, "RTNRETURN", exprChunk);
	if (isRtnPtr) {
		icodeVar(IC_VDR, TYPE_ROUTINE_POINTER, (unsigned char)pSym->level, (unsigned char)pSym->offset);
		icodeWriteUnaryLabel(IC_PPF, returnLabel);
	} else {
		// If a library routine (level 0), force nesting level to 2
		if (sym.level == 0)
			sym.level = 2;
		icodeWriteBinary(IC_PUF, icodeOperShort(1, sym.level),
			icodeOperLabel(2, returnLabel));
	}

	// Push the arguments onto the stack
	while (argChunk) {
		retrieveChunk(argChunk, &_expr);
		retrieveChunk(_expr.evalType, &argType);
		retrieveChunk(paramChunk, &param);
		retrieveChunk(param.type, &paramType);

		if (paramType.kind == TYPE_DECLARED) {
			struct symbol sym;
			char flags = paramType.flags;
			memset(name, 0, sizeof(name));
			retrieveChunk(paramType.name, name);
			scope_lookup(name, &sym);
			retrieveChunk(sym.type, &paramType);
			paramType.flags = flags;
		}

		if ((paramType.kind == TYPE_RECORD || paramType.kind == TYPE_ARRAY) &&
			(!(paramType.flags & TYPE_FLAG_ISBYREF))) {
			// Allocate a second heap and make a copy of the variable
			icodeExprRead(_expr.left);
			icodeWriteUnaryWord(IC_CPY, paramType.size);
		}
		else if (paramType.kind == TYPE_STRING_VAR &&
		 (!(paramType.flags & TYPE_FLAG_ISBYREF))) {
			// Convert the parameter into a string object
			// Allocate a second heap and make a copy of the string
			icodeExprRead(_expr.left);
			icodeWriteUnaryShort(IC_SCV, argType.kind);
		}
		else if (paramType.flags & TYPE_FLAG_ISBYREF) {
			icodeExpr(_expr.left, 0);
		}
		else {
			icodeExprRead(_expr.left);
			if (isLibraryCall && isTypeInteger(paramType.kind) &&
				argType.kind != paramType.kind) {
					// The argument being passed is an integer and a
					// different type than the expected parameter.
					// See if it needs to be sign-extended.
					char argMask, paramMask;
					argMask = getTypeMask(argType.kind);
					paramMask = getTypeMask(paramType.kind);
					if (GET_TYPE_SIZE(paramMask) > GET_TYPE_SIZE(argMask))
						// If the parameter type expected is larger than the
						// argument being passed, sign-extend it up.
						icodeWriteBinaryShort(IC_CVI, argType.kind, paramType.kind);
			}
		}

		argChunk = _expr.right;
		paramChunk = param.next;
	}

	if (isRtnPtr) {
		icodeVar(IC_VDR, TYPE_ROUTINE_POINTER, (unsigned char)pSym->level, (unsigned char)pSym->offset);
		// icodeWriteUnaryShort(IC_PSH, TYPE_ADDRESS);
	} else {
		// Activate the new stack frame
		icodeWriteUnaryShort(IC_ASF, sym.level);
	}

	return sym.level;
}

static void icodeRoutineCleanup(char *localVars, struct type* pDeclType,
	int numLocals, char isFunc, char isLibrary)
{
	CHUNKNUM paramChunk;
	struct param_list param;
	struct type paramType;
	int offset = -1;

	paramChunk = pDeclType->paramsFields;
	while (paramChunk) {
		retrieveChunk(paramChunk, &param);
		++offset;

		retrieveChunk(param.type, &paramType);

		if (paramType.kind == TYPE_DECLARED) {
			struct symbol sym;
			char flags = paramType.flags;
			memset(name, 0, sizeof(name));
			retrieveChunk(paramType.name, name);
			scope_lookup(name, &sym);
			retrieveChunk(sym.type, &paramType);
			paramType.flags = flags;
		}

		if ((paramType.kind == TYPE_RECORD || paramType.kind == TYPE_ARRAY ||
			paramType.kind == TYPE_STRING_VAR) &&
			(!(paramType.flags & TYPE_FLAG_ISBYREF))) {
				localVars[numLocals] = 1;
		}
		else {
			localVars[numLocals] = 0;
		}
		++numLocals;

		paramChunk = param.next;
	}

	if (numLocals) {
		int i;
		for (i = numLocals - 1; i >= 0; --i) {
			ICODE_MNE instruction;
			if (localVars[i] == 1) {
				instruction = IC_DEL;
			} else if (localVars[i] == 2) {
				instruction = IC_DEF;
			} else {
				instruction = IC_POP;
			}
			icodeWriteMnemonic(instruction);
		}
	}

	icodeWriteBinaryShort(IC_POF, isFunc, isLibrary);
}

static void icodeRoutineDeclaration(CHUNKNUM chunkNum, struct decl* pDecl, struct type* pDeclType)
{
	char localVars[MAX_LOCAL_VARS];
	char name[CHUNK_LEN + 1], startLabel[15];
	struct stmt _stmt;
	struct type _type;
	int numLocals, numHeap = 0;

	if (pDeclType->flags & TYPE_FLAG_ISFORWARD) {
		return;
	}

	memset(localVars, 0, sizeof(localVars));
	retrieveChunk(pDecl->code, &_stmt);

	icodeRoutineDeclarations(_stmt.decl);

	if (pDecl->unitSymtab) {
		scope_enter_symtab(pDecl->unitSymtab);
	}

	memset(name, 0, sizeof(name));
	retrieveChunk(pDecl->name, name);
	icodeFormatLabel(startLabel, "RTNENTER", chunkNum);
	icodeWriteUnaryLabel(IC_LOC, startLabel);

	// Push the local variables onto the stack
	numLocals = icodeVariableDeclarations(_stmt.decl, localVars);

	icodeStmts(_stmt.body);

	if (pDecl->unitSymtab) {
		scope_exit();
	}

	// Tear down the routine's stack frame and free local variables

	retrieveChunk(pDecl->type, &_type);
	icodeRoutineCleanup(localVars, pDeclType, numLocals,
		_type.kind == TYPE_PROCEDURE ? 0 : 1, 0);
}

void icodeRoutineDeclarations(CHUNKNUM chunkNum)
{
	struct decl _decl;
	struct type _type;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		scope_enter_symtab(_decl.symtab);

		if (_decl.kind == DECL_TYPE) {
			retrieveChunk(_decl.type, &_type);
			if (_type.kind == TYPE_FUNCTION || _type.kind == TYPE_PROCEDURE) {
				icodeRoutineDeclaration(chunkNum, &_decl, &_type);
			}
		}

		scope_exit();
		chunkNum = _decl.next;
	}

}

char icodeSubroutineCall(CHUNKNUM chunkNum)
{
	char isRtnPtr = 0;
	struct decl _decl;
	struct expr _expr, rtnExpr;
	struct symbol sym;
	struct type rtnType, subtype;

	retrieveChunk(chunkNum, &_expr);
	retrieveChunk(_expr.left, &rtnExpr);
	retrieveChunk(rtnExpr.node, &sym);
	retrieveChunk(sym.type, &rtnType);
	memcpy(&subtype, &rtnType, sizeof(struct type));
	getBaseType(&subtype);
	if (subtype.kind == TYPE_ROUTINE_POINTER) {
		isRtnPtr = 1;
	}
	if (sym.decl) {
		retrieveChunk(sym.decl, &_decl);
	} else {
		_decl.isLibrary = 0;
	}
	if (_decl.isLibrary) {
		return icodeLibrarySubroutineCall(chunkNum, sym.decl, &rtnType, _expr.right, isRtnPtr, &sym);
	}
	else if (rtnType.flags & TYPE_FLAG_ISSTD) {
		return icodeStdRoutineCall(rtnType.routineCode, _expr.right);
	}
	else {
		return icodeDeclaredSubroutineCall(chunkNum, sym.decl, &rtnType, _expr.right, isRtnPtr, &sym);
	}
}

static char icodeStdRoutineCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;
	struct type argType;

	switch (rc) {
	case rcRead:
	case rcReadln:
		icodeReadReadlnCall(rc, argChunk);
        return TYPE_VOID;

	case rcWrite:
	case rcWriteln:
	case rcWriteStr:
		icodeWriteWritelnCall(rc, argChunk);
        return rc == rcWriteStr ? TYPE_STRING_OBJ : TYPE_VOID;

	case rcAbs:
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &argType);
		icodeExprRead(arg.left);
		icodeWriteUnaryShort(IC_ABS, argType.kind);
		return argType.kind;

	case rcSqr:
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &argType);
		icodeExprRead(arg.left);
		icodeWriteUnaryShort(IC_SQR, argType.kind);
		return argType.kind == TYPE_REAL ? TYPE_REAL : TYPE_LONGINT;

	case rcRound:
	case rcTrunc:
		retrieveChunk(argChunk, &arg);
		icodeExprRead(arg.left);
		icodeWriteMnemonic(rc == rcRound ? IC_ROU : IC_TRU);
		return TYPE_INTEGER;

	case rcPred:
	case rcSucc:
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &argType);
		getBaseType(&argType);
		if (argType.kind == TYPE_ENUMERATION || argType.kind == TYPE_ENUMERATION_VALUE) {
			argType.kind = TYPE_WORD;
		}
		icodeExprRead(arg.left);
		icodeWriteUnaryShort(rc == rcPred ? IC_PRE : IC_SUC, argType.kind);
		return argType.kind;

	case rcOrd:
		retrieveChunk(argChunk, &arg);
		icodeExprRead(arg.left);
		return TYPE_INTEGER;

	case rcDec:
	case rcInc:
		icodeDecIncCall(rc, argChunk);
		break;
	}

    return TYPE_VOID;
}

static void icodeWriteWritelnCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	char writeBytes = 0;
    char valType, argValue;
	struct expr arg;
	struct type _type;

	if (rc == rcWriteStr) {
		argValue = FH_STRING;
	} else {
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &_type);
		if (_type.kind == TYPE_FILE || _type.kind == TYPE_TEXT) {
			icodeExprRead(arg.left);
			argValue = FH_FILENUM;
			argChunk = arg.right;
			writeBytes = _type.kind == TYPE_FILE ? 1 : 0;
		} else {
			argValue = FH_STDIO;
		}
	}

	icodeWriteBinaryShort(IC_SFH, argValue, 0);

	while (argChunk) {
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &_type);

		if (writeBytes) {
			icodeExprRead(arg.left);
			icodeWriteUnaryWord(IC_PSH, _type.size);
			icodeWriteUnaryShort(IC_OUT,
				(_type.kind == TYPE_ARRAY || _type.kind == TYPE_RECORD) ?
				TYPE_HEAP_BYTES : TYPE_SCALAR_BYTES);
		} else if (_type.kind != TYPE_RECORD) {
			valType = icodeExprRead(arg.left);
			if (arg.width) {
                icodeExprRead(arg.width);
			} else {
                icodeWriteUnaryShort(IC_PSH, 0);
			}
            if (arg.precision) {
                icodeExprRead(arg.precision);
            } else {
                icodeWriteUnaryShort(IC_PSH, 0xff);
            }
            icodeWriteUnary(IC_OUT, icodeOperByte(1,
				_type.kind == TYPE_ARRAY ? valType : _type.kind));
		}

		argChunk = arg.right;
	}

	if (rc == rcWriteln) {
        icodeWriteMnemonic(IC_ONL);
	}

	if (rc == rcWriteStr) {
		icodeWriteMnemonic(IC_FSO);
	}

	icodeWriteBinaryShort(IC_SFH, 0, 0);
}
