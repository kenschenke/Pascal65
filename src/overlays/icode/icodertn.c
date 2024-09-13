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

static char icodeAbsCall(CHUNKNUM argChunk);
static void icodeDecIncCall(TRoutineCode rc, CHUNKNUM argChunk);
static char icodeDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk);
static char icodeLibrarySubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk);
static void icodeOrdCall(CHUNKNUM argChunk);
static char icodePredSuccCall(TRoutineCode rc, CHUNKNUM argChunk);
static void icodeReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk);
static short icodeRoutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk,
	char *returnLabel, char isLibraryCall);
static void icodeRoutineCleanup(char *localVars, struct type* pDeclType,
	int numLocals, char isFunc, char isLibrary);
static void icodeRoutineDeclaration(CHUNKNUM chunkNum, struct decl* pDecl, struct type* pDeclType);
static void icodeRoundTruncCall(TRoutineCode rc, CHUNKNUM argChunk);
static char icodeSqrCall(CHUNKNUM argChunk);
static char icodeStdRoutineCall(TRoutineCode rc, CHUNKNUM argChunk);
static void icodeWriteWritelnCall(TRoutineCode rc, CHUNKNUM argChunk);

static char icodeAbsCall(CHUNKNUM argChunk)
{
	struct expr arg;
	struct type argType;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &argType);

	icodeExpr(arg.left, 1);
	icodeWriteUnaryShort(IC_ABS, argType.kind);

	return argType.kind;
}

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

	if (arg.right) {
		retrieveChunk(arg.right, &arg);
		icodeExpr(arg.left, 1);
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

	icodeExpr(varChunk, 0);	// push variable address onto stack

	icodeWriteBinaryShort(rc == rcInc ? IC_INC : IC_DEC,
		varType.kind, amountType);
}

static char icodeDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk)
{
	char returnLabel[15];
	short level;
	struct type rtnType;

	level = icodeRoutineCall(exprChunk, declChunk, pType, argChunk, returnLabel, 0);

	// Call the routine
	strcpy(enterLabel, "RTN");
	strcat(enterLabel, formatInt16(declChunk));
	strcat(enterLabel, "ENTER");
	icodeWriteTrinary(IC_JSR, icodeOperLabel(1, enterLabel),
		icodeOperShort(2, level), icodeOperShort(3, 0));

	icodeWriteUnaryLabel(IC_LOC, returnLabel);

	retrieveChunk(pType->subtype, &rtnType);
	return rtnType.kind;
}

static char icodeLibrarySubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk)
{
	struct type rtnType;
	short level;
	char localVars[MAX_LOCAL_VARS];
	int numLocal = 0;
	char returnLabel[15];

	memset(localVars, 0, sizeof(localVars));
	level = icodeRoutineCall(exprChunk, declChunk, pType, argChunk, returnLabel, 1);

	// Call the routine
	strcpy(enterLabel, "RTN");
	strcat(enterLabel, formatInt16(declChunk));
	strcat(enterLabel, "ENTER");
	icodeWriteTrinary(IC_JSR, icodeOperLabel(1, enterLabel),
		icodeOperShort(2, level), icodeOperBool(3, 1));

	icodeWriteUnaryLabel(IC_LOC, returnLabel);

	// Tear down the routine's stack frame and free parameters
	icodeRoutineCleanup(localVars, pType, numLocal,
		(pType->kind == TYPE_PROCEDURE) ? 0 : 1, 1);

	retrieveChunk(pType->subtype, &rtnType);
	return rtnType.kind;
}

static void icodeOrdCall(CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	icodeExpr(arg.left, 1);
}

static char icodePredSuccCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;
	struct type _type;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &_type);
	getBaseType(&_type);
	if (_type.kind == TYPE_ENUMERATION || _type.kind == TYPE_ENUMERATION_VALUE) {
		_type.kind = TYPE_WORD;
	}

	icodeExpr(arg.left, 1);
	icodeWriteUnaryShort(rc == rcPred ? IC_PRE : IC_SUC, _type.kind);

	return _type.kind;
}

static void icodeReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	char argValue, readBytes = 0;
	struct expr arg;
	struct type _type;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &_type);
	if (_type.kind == TYPE_FILE || _type.kind == TYPE_TEXT) {
		icodeExpr(arg.left, 1);
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
			if (_type.kind == TYPE_ARRAY || _type.kind == TYPE_RECORD) {
				icodeExpr(arg.left, 1);
				icodeWriteUnaryWord(IC_PSH, _type.size);
				icodeWriteUnaryShort(IC_INP, TYPE_HEAP_BYTES);
			} else {
				icodeExpr(arg.left, 0);
				icodeWriteUnaryWord(IC_PSH, _type.size);
				icodeWriteUnaryShort(IC_INP, TYPE_SCALAR_BYTES);
			}
		} else if (_type.kind == TYPE_ARRAY) {
			struct type subtype;
			retrieveChunk(_type.subtype, &subtype);
			// can only read into character arrays
			if (subtype.kind == TYPE_CHARACTER) {
				icodeExpr(arg.left, 0);
				icodeWriteUnaryShort(IC_INP, _type.kind);
			}
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

static void icodeRoundTruncCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	icodeExpr(arg.left, 1);
	icodeWriteMnemonic(rc == rcRound ? IC_ROU : IC_TRU);
}

static short icodeRoutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk,
	char *returnLabel, char isLibraryCall)
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
	strcpy(returnLabel, "RTN");
	strcat(returnLabel, formatInt16(exprChunk));
	strcat(returnLabel, "RETURN");
	icodeWriteBinary(IC_PUF, icodeOperShort(1, sym.level),
		icodeOperLabel(2, returnLabel));

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
			icodeExpr(_expr.left, 1);
			icodeWriteUnaryWord(IC_CPY, paramType.size);
		}
		else if (paramType.kind == TYPE_STRING_VAR &&
		 (!(paramType.flags & TYPE_FLAG_ISBYREF))) {
			// Convert the parameter into a string object
			// Allocate a second heap and make a copy of the string
			icodeExpr(_expr.left, argType.kind == TYPE_ARRAY ? 1 : 1);
			icodeWriteUnaryShort(IC_SCV, argType.kind);
		}
		else if (paramType.flags & TYPE_FLAG_ISBYREF) {
			icodeExpr(_expr.left, 0);
		}
		else {
			icodeExpr(_expr.left, 1);
			if (isLibraryCall && isTypeInteger(paramType.kind)) {
				icodeWriteBinaryShort(IC_CVI, argType.kind, paramType.kind);
			}
		}

		argChunk = _expr.right;
		paramChunk = param.next;
	}

	// Activate the new stack frame
	icodeWriteUnaryShort(IC_ASF, sym.level);

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
	strcpy(startLabel, "RTN");
	strcat(startLabel, formatInt16(chunkNum));
	strcat(startLabel, "ENTER");
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

static char icodeSqrCall(CHUNKNUM argChunk)
{
	struct expr arg;
	struct type argType;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &argType);

	icodeExpr(arg.left, 1);
	icodeWriteUnaryShort(IC_SQR, argType.kind);

	return argType.kind == TYPE_REAL ? TYPE_REAL : TYPE_LONGINT;
}

char icodeSubroutineCall(CHUNKNUM chunkNum)
{
	struct decl _decl;
	struct expr _expr, rtnExpr;
	struct symbol sym;
	struct type rtnType;

	retrieveChunk(chunkNum, &_expr);
	retrieveChunk(_expr.left, &rtnExpr);
	retrieveChunk(rtnExpr.node, &sym);
	retrieveChunk(sym.type, &rtnType);
	if (sym.decl) {
		retrieveChunk(sym.decl, &_decl);
	} else {
		_decl.isLibrary = 0;
	}
	if (_decl.isLibrary) {
		return icodeLibrarySubroutineCall(chunkNum, sym.decl, &rtnType, _expr.right);
	}
	else if (rtnType.flags & TYPE_FLAG_ISSTD) {
		return icodeStdRoutineCall(rtnType.routineCode, _expr.right);
	}
	else {
		return icodeDeclaredSubroutineCall(chunkNum, sym.decl, &rtnType, _expr.right);
	}
}

static char icodeStdRoutineCall(TRoutineCode rc, CHUNKNUM argChunk)
{
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
		return icodeAbsCall(argChunk);

	case rcSqr:
		return icodeSqrCall(argChunk);

	case rcRound:
	case rcTrunc:
		icodeRoundTruncCall(rc, argChunk);
		return TYPE_INTEGER;

	case rcPred:
	case rcSucc:
		return icodePredSuccCall(rc, argChunk);

	case rcOrd:
		icodeOrdCall(argChunk);
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
			icodeExpr(arg.left, 1);
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

		switch (_type.kind) {
		case TYPE_BOOLEAN:
		case TYPE_CHARACTER:
		case TYPE_BYTE:
		case TYPE_SHORTINT:
		case TYPE_INTEGER:
		case TYPE_WORD:
		case TYPE_LONGINT:
		case TYPE_CARDINAL:
		case TYPE_STRING_LITERAL:
        case TYPE_REAL:
		case TYPE_STRING_VAR:
		case TYPE_STRING_OBJ:
			if (writeBytes) {
				icodeExpr(arg.left, 1);
				icodeWriteUnaryWord(IC_PSH, _type.size);
				icodeWriteUnaryShort(IC_OUT, TYPE_SCALAR_BYTES);
				break;
			}
			valType = icodeExpr(arg.left, 1);
			if (arg.width) {
                icodeExpr(arg.width, 1);
			} else {
                icodeWriteUnaryShort(IC_PSH, 0);
			}
            if (arg.precision) {
                icodeExpr(arg.precision, 1);
            } else {
                icodeWriteUnaryShort(IC_PSH, 0xff);
            }
            icodeWriteUnary(IC_OUT, icodeOperByte(1, valType));
			break;

		case TYPE_ARRAY:
			if (writeBytes) {
				icodeExpr(arg.left, 1);
				icodeWriteUnaryWord(IC_PSH, _type.size);
				icodeWriteUnaryShort(IC_OUT, TYPE_HEAP_BYTES);
			} else {
				struct type subtype;
				struct expr leftExpr;
				// struct symbol node;
				retrieveChunk(_type.subtype, &subtype);
				if (subtype.kind != TYPE_CHARACTER) {
					break;  // can only write character arrays
				}
				retrieveChunk(arg.left, &leftExpr);
				valType = icodeExpr(arg.left, 1);
				if (arg.width) {
					icodeExpr(arg.width, 1);
				} else {
					icodeWriteUnaryShort(IC_PSH, 0);
				}
				icodeWriteUnaryShort(IC_PSH, 0xff);
				icodeWriteUnary(IC_OUT, icodeOperByte(1, valType));
			}
			break;
		
		case TYPE_RECORD:
			if (writeBytes) {
				icodeExpr(arg.left, 1);
				icodeWriteUnaryWord(IC_PSH, _type.size);
				icodeWriteUnaryShort(IC_OUT, TYPE_HEAP_BYTES);
			}
			break;
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
