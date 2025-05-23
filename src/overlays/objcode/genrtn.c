/**
 * genrtn.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Generate routines and routine calls in object code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>

#include <codegen.h>
#include <asm.h>
#include <ast.h>
#include <symtab.h>
#include <common.h>
#include <int16.h>

#include <string.h>

static 	char name[CHUNK_LEN + 1], enterLabel[15];

static void genAbsCall(CHUNKNUM argChunk);
static void genDecIncCall(TRoutineCode routineCode, CHUNKNUM argChunk);
static void genDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk);
static void genLibrarySubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk);
static void genOrdCall(CHUNKNUM argChunk);
static void genPredSuccCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genRoundTruncCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genRoutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk, char *returnLabel);
static void genRoutineCleanup(short *heapOffsets, int numHeap, struct type* pDeclType, int numLocals);
static void genRoutineDeclaration(CHUNKNUM chunkNum, struct decl* pDecl, struct type* pDeclType);
static void genSqrCall(CHUNKNUM argChunk);
static void genStdRoutineCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genWriteWritelnCall(TRoutineCode rc, CHUNKNUM argChunk);

#define PARAM_BYREF1_SIZEL 1
#define PARAM_BYREF1_SIZEH 3
static unsigned char paramByRef1[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_HEAPALLOC), WORD_HIGH(RT_HEAPALLOC),
	PHA,
	TXA,
	PHA,
};

#define PARAM_BYREF2_SIZEL 21
#define PARAM_BYREF2_SIZEH 23
static unsigned char paramByRef2[] = {
	LDY_IMMEDIATE, 0,
	LDA_ZPINDIRECT, ZP_PTR1L,
	STA_ZEROPAGE, ZP_PTR2L,
	INY,
	LDA_ZPINDIRECT, ZP_PTR1L,
	STA_ZEROPAGE, ZP_PTR2H,
	PLA,
	STA_ZEROPAGE, ZP_PTR1H,
	PLA,
	STA_ZEROPAGE, ZP_PTR1L,
	JSR, WORD_LOW(RT_PUSHADDRSTACK), WORD_HIGH(RT_PUSHADDRSTACK),
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_MEMCOPY), WORD_HIGH(RT_MEMCOPY),
};

#define ACTIVATE_FRAME_LEVEL 10
static unsigned char activateFrame[] = {
	PLA,
	STA_ZEROPAGE, ZP_STACKFRAMEH,
	PLA,
	STA_ZEROPAGE, ZP_STACKFRAMEL,
	LDA_ZEROPAGE, ZP_NESTINGLEVEL,
	PHA,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_NESTINGLEVEL,
};

static void genAbsCall(CHUNKNUM argChunk)
{
	struct expr arg;
	struct type argType;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &argType);

	genExpr(arg.left, 1, 0);
	genTwo(LDA_IMMEDIATE, argType.kind);
	genThreeAddr(JSR, RT_ABS);
}

#if 0
static void genDecIncCall(TRoutineCode rc, CHUNKNUM argChunk)
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
		genExpr(arg.left, 1, 0);
		retrieveChunk(arg.left, &arg);
		retrieveChunk(arg.evalType, &amtType);
		amountType = amtType.kind;
	} else {
		genTwo(LDA_IMMEDIATE, 1);
		genThreeAddr(JSR, RT_PUSHBYTESTACK);
		amountType = TYPE_BYTE;
	}

	genExpr(varChunk, 0, 1);	// leaves variable address in ptr1

	genTwo(LDA_IMMEDIATE, varType.kind);
	genTwo(LDY_IMMEDIATE, amountType);

	genThreeAddr(JSR, rc == rcInc ? RT_INCREMENT : RT_DECREMENT);
}
#endif

static void genDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk)
{
	char returnLabel[15];

	genRoutineCall(exprChunk, declChunk, pType, argChunk, returnLabel);

	// Call the routine
	strcpy(enterLabel, "RTNENTER");
	strcat(enterLabel, formatInt16(declChunk));
	linkAddressLookup(enterLabel, codeOffset + 1, LINKADDR_BOTH);
	genThreeAddr(JMP, 0);

	linkAddressSet(returnLabel, codeOffset);

	if (pType->kind == TYPE_PROCEDURE) {
		// Clean the un-used return value off the stack
		genThreeAddr(JSR, RT_INCSP4);
	}

	genOne(PLA);
	genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);
}

static void genLibrarySubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk)
{
	CHUNKNUM paramChunk;
	struct param_list param;
	struct type paramType;
	short heapOffsets[MAX_LOCAL_HEAPS];
	int numHeap = 0, offset = -1;
	char returnLabel[15];

	genRoutineCall(exprChunk, declChunk, pType, argChunk, returnLabel);

	// Call the routine
	strcpy(enterLabel, "RTNENTER");
	strcat(enterLabel, formatInt16(declChunk));
	linkAddressLookup(enterLabel, codeOffset + 1, LINKADDR_BOTH);
	genThreeAddr(JSR, 0);

	linkAddressSet(returnLabel, codeOffset);

	paramChunk = pType->paramsFields;
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

		if ((paramType.kind == TYPE_RECORD || paramType.kind == TYPE_ARRAY) &&
			(!(paramType.flags & TYPE_FLAG_ISBYREF))) {
			heapOffsets[numHeap++] = offset;
		}

		paramChunk = param.next;
	}

	// Tear down the routine's stack frame and free parameters

	genRoutineCleanup(heapOffsets, numHeap, pType, 0);

	genThreeAddr(JSR, RT_INCSP4);	// Pop the return address of the stack

	if (pType->kind == TYPE_PROCEDURE) {
		// Clean the un-used return value off the stack
		genThreeAddr(JSR, RT_INCSP4);
	}

	genOne(PLA);
	genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);
}

static void genOrdCall(CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0);
}

static void genPredSuccCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;
	struct type _type;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &_type);
	getBaseType(&_type);
	if (_type.kind == TYPE_ENUMERATION || _type.kind == TYPE_ENUMERATION_VALUE) {
		_type.kind = TYPE_WORD;
	}

	genExpr(arg.left, 1, 0);
	if (_type.kind == TYPE_ENUMERATION_VALUE) {
		_type.kind = TYPE_WORD;
	}
	genTwo(LDA_IMMEDIATE, _type.kind);
	genThreeAddr(JSR, rc == rcPred ? RT_PRED : RT_SUCC);
}

static void genReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;
	struct type _type;

	while (argChunk) {
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &_type);

		switch (_type.kind) {
		case TYPE_CHARACTER:
		case TYPE_BYTE:
		case TYPE_SHORTINT:
			genThreeAddr(JSR, _type.kind == TYPE_CHARACTER ? RT_READCHARFROMINPUT : RT_READINTFROMINPUT);
			genThreeAddr(JSR, RT_PUSHBYTESTACK);
			genExpr(arg.left, 0, 0);
			genThreeAddr(JSR, RT_STOREINTSTACK);
			break;

		case TYPE_INTEGER:
		case TYPE_WORD:
			genThreeAddr(JSR, RT_READINTFROMINPUT);
			genThreeAddr(JSR, RT_PUSHINTSTACK);
			genExpr(arg.left, 0, 0);
			genThreeAddr(JSR, RT_STOREINTSTACK);
			break;
		
		case TYPE_CARDINAL:
		case TYPE_LONGINT:
			genThreeAddr(JSR, RT_READINTFROMINPUT);
			genThreeAddr(JSR, RT_PUSHEAX);
			genExpr(arg.left, 0, 0);
			genThreeAddr(JSR, RT_STOREINT32STACK);
			break;

		case TYPE_REAL:
			genThreeAddr(JSR, RT_READFLOATFROMINPUT);
			genThreeAddr(JSR, RT_PUSHREALSTACK);
			genExpr(arg.left, 0, 0);
			genThreeAddr(JSR, RT_STOREREALSTACK);
			break;

		case TYPE_ARRAY: {
			struct type subtype;
			struct expr leftExpr;
			struct symbol node;
			retrieveChunk(_type.subtype, &subtype);
			if (subtype.kind != TYPE_CHARACTER) {
				break;  // can only read into character arrays
			}
			retrieveChunk(arg.left, &leftExpr);
			retrieveChunk(leftExpr.node, &node);
			genTwo(LDA_IMMEDIATE, node.level);
			genTwo(LDX_IMMEDIATE, node.offset);
			genThreeAddr(JSR, RT_READCHARARRAYFROMINPUT);
			break;
		}

		case TYPE_STRING_VAR: {
			struct expr leftExpr;
			struct symbol node;
			retrieveChunk(arg.left, &leftExpr);
			retrieveChunk(leftExpr.node, &node);
			genTwo(LDA_IMMEDIATE, node.level);
			genTwo(LDX_IMMEDIATE, node.offset);
			genThreeAddr(JSR, RT_READSTRINGFROMINPUT);
			break;
		}
		}

		argChunk = arg.right;
	}

	if (rc == rcReadln) {
		genThreeAddr(JSR, RT_CLEARINPUTBUF);
	}
}

static void genRoundTruncCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0);
	genThreeAddr(JSR, RT_POPTOREAL);
	if (rc == rcRound) {
		genTwo(LDA_IMMEDIATE, 0);	// Round to 0 decimal places
		genThreeAddr(JSR, RT_PRECRD);
	}
	genThreeAddr(JSR, RT_FLOATTOINT16);
	genThreeAddr(JSR, RT_PUSHFROMINTOP1);
}

static void genRoutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk, char *returnLabel)
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
	strcpy(returnLabel, "RTNRETURN");
	strcat(returnLabel, formatInt16(exprChunk));
	linkAddressLookup(returnLabel, codeOffset + 1, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(returnLabel, codeOffset + 1, LINKADDR_HIGH);
	genTwo(LDX_IMMEDIATE, 0);
	genTwo(LDY_IMMEDIATE, (unsigned char)sym.level);
	genThreeAddr(JSR, RT_PUSHSTACKFRAMEHEADER);
	// Save the new stack frame pointer
	genOne(PHA);
	genOne(TXA);
	genOne(PHA);

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
			paramByRef1[PARAM_BYREF1_SIZEL] = WORD_LOW(paramType.size);
			paramByRef1[PARAM_BYREF1_SIZEH] = WORD_HIGH(paramType.size);
			writeCodeBuf(paramByRef1, 10);
			genExpr(_expr.left, 0, 1);
			paramByRef2[PARAM_BYREF2_SIZEL] = WORD_LOW(paramType.size);
			paramByRef2[PARAM_BYREF2_SIZEH] = WORD_HIGH(paramType.size);
			writeCodeBuf(paramByRef2, 27);
		}
		else if (paramType.kind == TYPE_STRING_VAR &&
		 (!(paramType.flags & TYPE_FLAG_ISBYREF))) {
			// Convert the parameter into a string object
			// Allocate a second heap and make a copy of the string
			genExpr(_expr.left, argType.kind == TYPE_ARRAY ? 1 : 1, 1);
			if (argType.kind == TYPE_STRING_OBJ) {
				++stringObjHeaps;
				writeCodeBuf(exprFreeString1, EXPR_FREE_STRING1_LEN);
			}
			genTwo(LDY_IMMEDIATE, argType.kind);
			genThreeAddr(JSR, RT_CONVERTSTRING);
			genThreeAddr(JSR, RT_PUSHEAX);
		}
		else if (paramType.flags & TYPE_FLAG_ISBYREF) {
			genExpr(_expr.left, 0, 1);
			genThreeAddr(JSR, RT_PUSHADDRSTACK);
		}
		else {
			genExpr(_expr.left, 1, 0);
		}

		argChunk = _expr.right;
		paramChunk = param.next;
	}

	// Free string objects passed as arguments
	while (stringObjHeaps) {
		genOne(PLA);
		genOne(TAX);
		genOne(PLA);
		genThreeAddr(JSR, RT_HEAPFREE);
		--stringObjHeaps;
	}

	// Activate the new stack frame
	activateFrame[ACTIVATE_FRAME_LEVEL] = sym.level;
	writeCodeBuf(activateFrame, 13);
}

static void genRoutineCleanup(short *heapOffsets, int numHeap, struct type* pDeclType,
	int numLocals)
{
	CHUNKNUM paramChunk;
	struct param_list param;
	struct type paramType;
	int offset = -1;

	paramChunk = pDeclType->paramsFields;
	while (paramChunk) {
		retrieveChunk(paramChunk, &param);
		++numLocals;
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
			heapOffsets[numHeap++] = offset;
		}

		paramChunk = param.next;
	}

	heapOffsets[numHeap] = -1;
	if (heapOffsets[0] >= 0) {
		genFreeVariableHeaps(heapOffsets);
	}

	if (numLocals) {
		// Pop local variables and parameters off the stack
		genTwo(LDX_IMMEDIATE, WORD_LOW(numLocals));
		genOne(TXA);
		genOne(PHA);	// Store the current number on the stack
		genThreeAddr(JSR, RT_INCSP4);
		genOne(PLA);
		genOne(TAX);
		genOne(DEX);
		genTwo(BNE, 0xf6);	// negative 10
	}

	// Restore the caller's stack frame base pointer
	genThreeAddr(JSR, RT_POPEAX);
	genTwo(STA_ZEROPAGE, ZP_STACKFRAMEL);
	genTwo(STX_ZEROPAGE, ZP_STACKFRAMEH);

	genThreeAddr(JSR, RT_INCSP4);	// Pop the static link off the stack
}

static void genRoutineDeclaration(CHUNKNUM chunkNum, struct decl* pDecl, struct type* pDeclType)
{
	short heapOffsets[MAX_LOCAL_HEAPS];
	char name[CHUNK_LEN + 1], startLabel[15];
	struct stmt _stmt;
	int numLocals, numHeap = 0;

	if (pDeclType->flags & TYPE_FLAG_ISFORWARD) {
		return;
	}

	retrieveChunk(pDecl->code, &_stmt);

	genRoutineDeclarations(_stmt.decl);

	if (pDecl->unitSymtab) {
		scope_enter_symtab(pDecl->unitSymtab);
	}

	memset(name, 0, sizeof(name));
	retrieveChunk(pDecl->name, name);
	strcpy(startLabel, "RTNENTER");
	strcat(startLabel, formatInt16(chunkNum));
	linkAddressSet(startLabel, codeOffset);

	// Push the local variables onto the stack
	numLocals = genVariableDeclarations(_stmt.decl, heapOffsets);

	genStmts(_stmt.body);

	if (pDecl->unitSymtab) {
		scope_exit();
	}

	// Count of the number of heap offsets already declared
	while (heapOffsets[numHeap] >= 0) {
		numHeap++;
	}

	// Tear down the routine's stack frame and free local variables

	genRoutineCleanup(heapOffsets, numHeap, pDeclType, numLocals);

	// Return from the routine
	genThreeAddr(JMP, RT_RETURNFROMROUTINE);
}

void genRoutineDeclarations(CHUNKNUM chunkNum)
{
	struct decl _decl;
	struct type _type;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		scope_enter_symtab(_decl.symtab);

		if (_decl.kind == DECL_TYPE) {
			retrieveChunk(_decl.type, &_type);
			if (_type.kind == TYPE_FUNCTION || _type.kind == TYPE_PROCEDURE) {
				genRoutineDeclaration(chunkNum, &_decl, &_type);
				// _decl.symtab!
			}
		}

		scope_exit();
		chunkNum = _decl.next;
	}

}

static void genSqrCall(CHUNKNUM argChunk)
{
	struct expr arg;
	struct type argType;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &argType);

	genExpr(arg.left, 1, 0);
	genTwo(LDA_IMMEDIATE, argType.kind);
	genThreeAddr(JSR, RT_SQR);
}

void genSubroutineCall(CHUNKNUM chunkNum)
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
		genLibrarySubroutineCall(chunkNum, sym.decl, &rtnType, _expr.right);
	}
	else if (rtnType.flags & TYPE_FLAG_ISSTD) {
		genStdRoutineCall(rtnType.routineCode, _expr.right);
	}
	else {
		genDeclaredSubroutineCall(chunkNum, sym.decl, &rtnType, _expr.right);
	}
}

static void genStdRoutineCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	switch (rc) {
	case rcRead:
	case rcReadln:
		genReadReadlnCall(rc, argChunk);
		break;

	case rcWrite:
	case rcWriteln:
	case rcWriteStr:
		genWriteWritelnCall(rc, argChunk);
		break;

	case rcAbs:
		genAbsCall(argChunk);
		break;

	case rcSqr:
		genSqrCall(argChunk);
		break;

	case rcRound:
	case rcTrunc:
		genRoundTruncCall(rc, argChunk);
		break;

	case rcPred:
	case rcSucc:
		genPredSuccCall(rc, argChunk);
		break;

	case rcOrd:
		genOrdCall(argChunk);
		break;

	case rcDec:
	case rcInc:
		// genDecIncCall(rc, argChunk);
		break;
	}
}

static void genWriteWritelnCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;
	struct type _type;

	genTwo(LDA_IMMEDIATE, rc == rcWriteStr ? FH_STRING : FH_STDIO);
	genThreeAddr(JSR, RT_SETFH);
	genOne(PHA);	// push previous FH to stack

	if (rc == rcWriteStr) {
		genThreeAddr(JSR, RT_RESETSTRBUFFER);
	}

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
			genExpr(arg.left, 1, 0);
			if (arg.width) {
				genExpr(arg.width, 1, 1);
				genOne(TAX);
			} else {
				genTwo(LDX_IMMEDIATE, 0);
			}
			genTwo(LDA_IMMEDIATE, _type.kind);
			genThreeAddr(JSR, RT_WRITEVALUE);
			break;

		case TYPE_REAL:
			genExpr(arg.left, 1, 0);
			genThreeAddr(JSR, RT_POPTOREAL);
			if (arg.precision) {
				genExpr(arg.precision, 1, 1);
			}
			else {
				genTwo(LDA_IMMEDIATE, 0xff);
			}
			genThreeAddr(JSR, RT_FPOUT);
			if (arg.width) {
				genOne(PHA);	// Preserve the value width
				genExpr(arg.width, 1, 1);
				genOne(TAY);	// Save field width in Y for a sec
				genOne(PLA);	// Pull value width from stack
				genOne(TAX);	// Value width in X
				genOne(TYA);	// Field width in A
				genThreeAddr(JSR, RT_LEFTPAD);
			}
			genTwo(LDA_IMMEDIATE, ZP_FPBUF);
			genTwo(LDX_IMMEDIATE, 0);
			genThreeAddr(JSR, RT_PRINTZ);
			break;

		case TYPE_STRING_LITERAL:
			genExpr(arg.left, 1, 0);
			if (arg.width) {
				genExpr(arg.width, 1, 1);
			} else {
				genTwo(LDA_IMMEDIATE, 0);
			}
			genThreeAddr(JSR, RT_WRITESTRLITERAL);
			break;

		case TYPE_STRING_VAR:
		case TYPE_STRING_OBJ:
			genExpr(arg.left, 1, 0);
			if (isStringFunc(arg.left)) {
				genThreeAddr(JSR, RT_POPEAX);
			}
			if (_type.kind == TYPE_STRING_OBJ) {
				writeCodeBuf(exprFreeString1, EXPR_FREE_STRING1_LEN);
			}
			genThreeAddr(JSR, RT_PUSHEAX);
			if (arg.width) {
				genExpr(arg.width, 1, 1);
				genOne(TAX);
			} else {
				genTwo(LDX_IMMEDIATE, 0);
			}
			genTwo(LDA_IMMEDIATE, _type.kind);
			genThreeAddr(JSR, RT_WRITEVALUE);
			if (_type.kind == TYPE_STRING_OBJ) {
				genOne(PLA);
				genOne(TAX);
				genOne(PLA);
				genThreeAddr(JSR, RT_HEAPFREE);
			}
			break;

		case TYPE_ARRAY: {
			struct type subtype;
			struct expr leftExpr;
			// struct symbol node;
			retrieveChunk(_type.subtype, &subtype);
			if (subtype.kind != TYPE_CHARACTER) {
				break;  // can only write character arrays
			}
			retrieveChunk(arg.left, &leftExpr);
			// retrieveChunk(leftExpr.node, &node);
			if (arg.width) {
				genExpr(arg.width, 1, 1);
			} else {
				genTwo(LDA_IMMEDIATE, 0);
				genOne(TAX);
			}
			genThreeAddr(JSR, RT_PUSHAX);
			// If the argument is an array in an array, it needs to be
			// resolved one layer deeper.
			genExpr(arg.left,
				leftExpr.kind == EXPR_NAME ? 1 : 0, 1);
			genThreeAddr(JSR, RT_WRITECHARARRAY);
			break;
		}
		}

		argChunk = arg.right;
	}

	if (rc == rcWriteln) {
		genTwo(LDA_IMMEDIATE, 13);	// carriage return
		genThreeAddr(JSR, CHROUT);
	}

	genOne(PLA);
	genThreeAddr(JSR, RT_SETFH);

	if (rc == rcWriteStr) {
		genThreeAddr(JSR, RT_GETSTRBUFFER);
		genThreeAddr(JSR, RT_PUSHEAX);
	}
}
