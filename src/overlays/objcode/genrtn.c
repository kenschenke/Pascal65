#include <stdio.h>

#include <codegen.h>
#include <asm.h>
#include <ast.h>
#include <symtab.h>
#include <common.h>
#include <int16.h>

#include <string.h>

static 	char name[CHUNK_LEN + 1], enterLabel[15], returnLabel[15];

static void genAbsCall(CHUNKNUM argChunk);
static void genDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk);
static void genLibrarySubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk);
static void genOrdCall(CHUNKNUM argChunk);
static void genPredSuccCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genRoundTruncCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genRoutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk);
static void genRoutineCleanup(short *heapOffsets, int numHeap, struct type* pDeclType, int numLocals);
static void genRoutineDeclaration(CHUNKNUM chunkNum, struct decl* pDecl, struct type* pDeclType);
static void genSqrCall(CHUNKNUM argChunk);
static void genStdRoutineCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genWriteWritelnCall(TRoutineCode rc, CHUNKNUM argChunk);

#define PARAM_BYREF1_SIZEL 1
#define PARAM_BYREF1_SIZEH 3
#define PARAM_BYREF1_ALLOC 5
static unsigned char paramByRef1[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, 0, 0,
	PHA,
	TXA,
	PHA,
};

#define PARAM_BYREF2_SIZEL 21
#define PARAM_BYREF2_SIZEH 23
#define PARAM_BYREF2_MEMCOPY 25
#define PARAM_BYREF2_PUSHADDR 18
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
	JSR, 0, 0,
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, 0, 0,
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

	genExpr(arg.left, 1, 0, 0);
	genTwo(LDA_IMMEDIATE, argType.kind);
	genRuntimeCall(rtAbs);
}

static void genDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk)
{
	genRoutineCall(exprChunk, declChunk, pType, argChunk);

	// Call the routine
	strcpy(enterLabel, "RTN");
	strcat(enterLabel, formatInt16(declChunk));
	strcat(enterLabel, "ENTER");
	linkAddressLookup(enterLabel, codeOffset + 1, 0, LINKADDR_BOTH);
	genThreeAddr(JMP, 0);

	linkAddressSet(returnLabel, codeOffset);

	if (pType->kind == TYPE_PROCEDURE) {
		// Clean the un-used return value off the stack
		genRuntimeCall(rtIncSp4);
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

	genRoutineCall(exprChunk, declChunk, pType, argChunk);

	// Call the routine
	strcpy(enterLabel, "RTN");
	strcat(enterLabel, formatInt16(declChunk));
	strcat(enterLabel, "ENTER");
	linkAddressLookup(enterLabel, codeOffset + 1, 0, LINKADDR_BOTH);
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

	genRuntimeCall(rtIncSp4);	// Pop the return address of the stack

	if (pType->kind == TYPE_PROCEDURE) {
		// Clean the un-used return value off the stack
		genRuntimeCall(rtIncSp4);
	}

	genOne(PLA);
	genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);
}

static void genOrdCall(CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0, 0);
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

	genExpr(arg.left, 1, 0, 0);
	if (_type.kind == TYPE_ENUMERATION_VALUE) {
		_type.kind = TYPE_WORD;
	}
	genTwo(LDA_IMMEDIATE, _type.kind);
	genRuntimeCall(rc == rcPred ? rtPred : rtSucc);
}

static void genReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;
	struct type _type;

	while (argChunk) {
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &_type);

		switch (_type.kind) {
		case TYPE_BYTE:
		case TYPE_SHORTINT:
			genRuntimeCall(rtReadIntFromInput);
			genRuntimeCall(rtPushByte);
			genExpr(arg.left, 0, 0, 0);
			genRuntimeCall(rtStoreInt);
			break;

		case TYPE_INTEGER:
		case TYPE_WORD:
			genRuntimeCall(rtReadIntFromInput);
			genRuntimeCall(rtPushInt);
			genExpr(arg.left, 0, 0, 0);
			genRuntimeCall(rtStoreInt);
			break;
		
		case TYPE_CARDINAL:
		case TYPE_LONGINT:
			genRuntimeCall(rtReadIntFromInput);
			genRuntimeCall(rtPushEax);
			genExpr(arg.left, 0, 0, 0);
			genRuntimeCall(rtStoreInt32);
			break;

		case TYPE_REAL:
			genRuntimeCall(rtReadFloatFromInput);
			genRuntimeCall(rtPushReal);
			genExpr(arg.left, 0, 0, 0);
			genRuntimeCall(rtStoreReal);
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
			genRuntimeCall(rtReadCharArrayFromInput);
			break;
		}
		}

		argChunk = arg.right;
	}

	if (rc == rcReadln) {
		genRuntimeCall(rtClearInputBuf);
	}
}

static void genRoundTruncCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0, 0);
	genRuntimeCall(rtPopToReal);
	if (rc == rcRound) {
		genTwo(LDA_IMMEDIATE, 0);	// Round to 0 decimal places
		genRuntimeCall(rtPrecRd);
	}
	genRuntimeCall(rtFloatToInt16);
	genRuntimeCall(rtPushIntOp1);
}

static void genRoutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk)
{
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
	linkAddressLookup(returnLabel, codeOffset + 1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(returnLabel, codeOffset + 1, 0, LINKADDR_HIGH);
	genTwo(LDX_IMMEDIATE, 0);
	genTwo(LDY_IMMEDIATE, (unsigned char)sym.level);
	genRuntimeCall(rtPushStackFrameHeader);
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
			setRuntimeRef(rtHeapAlloc, codeOffset + PARAM_BYREF1_ALLOC);
			writeCodeBuf(paramByRef1, 10);
			genExpr(_expr.left, 0, 1, 0);
			paramByRef2[PARAM_BYREF2_SIZEL] = WORD_LOW(paramType.size);
			paramByRef2[PARAM_BYREF2_SIZEH] = WORD_HIGH(paramType.size);
			setRuntimeRef(rtMemCopy, codeOffset + PARAM_BYREF2_MEMCOPY);
			setRuntimeRef(rtPushAddrStack, codeOffset + PARAM_BYREF2_PUSHADDR);
			writeCodeBuf(paramByRef2, 27);
		}
		else if (paramType.flags & TYPE_FLAG_ISBYREF) {
			genExpr(_expr.left, 0, 1, 0);
			genRuntimeCall(rtPushAddrStack);
		}
		else {
			genExpr(_expr.left, 1, 0, 0);
		}

		argChunk = _expr.right;
		paramChunk = param.next;
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

		if ((paramType.kind == TYPE_RECORD || paramType.kind == TYPE_ARRAY) &&
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
		genRuntimeCall(rtIncSp4);
		genOne(PLA);
		genOne(TAX);
		genOne(DEX);
		genTwo(BNE, 0xf6);	// negative 10
	}

	// Restore the caller's stack frame base pointer
	genRuntimeCall(rtPopEax);
	genTwo(STA_ZEROPAGE, ZP_STACKFRAMEL);
	genTwo(STX_ZEROPAGE, ZP_STACKFRAMEH);

	genRuntimeCall(rtIncSp4);	// Pop the static link off the stack
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
	strcpy(startLabel, "RTN");
	strcat(startLabel, formatInt16(chunkNum));
	strcat(startLabel, "ENTER");
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
	setRuntimeRef(rtReturnFromRoutine, codeOffset + 1);
	genThreeAddr(JMP, 0);
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

	genExpr(arg.left, 1, 0, 0);
	genTwo(LDA_IMMEDIATE, argType.kind);
	genRuntimeCall(rtSqr);
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
	}
}

static void genWriteWritelnCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;
	struct type _type;

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
			genExpr(arg.left, 1, 0, 0);
			if (arg.width) {
				genExpr(arg.width, 1, 1, 0);
				genOne(TAX);
			} else {
				genTwo(LDX_IMMEDIATE, 0);
			}
			genTwo(LDA_IMMEDIATE, _type.kind);
			genRuntimeCall(rtWriteValue);
			break;

		case TYPE_REAL:
			genExpr(arg.left, 1, 0, 0);
			genRuntimeCall(rtPopToReal);
			if (arg.precision) {
				genExpr(arg.precision, 1, 1, 0);
			}
			else {
				genTwo(LDA_IMMEDIATE, 0xff);
			}
			genRuntimeCall(rtFpOut);
			if (arg.width) {
				genOne(PHA);	// Preserve the value width
				genExpr(arg.width, 1, 1, 0);
				genOne(TAY);	// Save field width in Y for a sec
				genOne(PLA);	// Pull value width from stack
				genOne(TAX);	// Value width in X
				genOne(TYA);	// Field width in A
				genRuntimeCall(rtLeftPad);
			}
			genTwo(LDA_IMMEDIATE, ZP_FPBUF);
			genTwo(LDX_IMMEDIATE, 0);
			genRuntimeCall(rtPrintz);
			break;

		case TYPE_STRING:
			genExpr(arg.left, 1, 0, 0);
			genRuntimeCall(rtPopEax);
			genRuntimeCall(rtPrintz);
			break;

		case TYPE_ARRAY: {
			struct type subtype;
			struct expr leftExpr;
			struct symbol node;
			retrieveChunk(_type.subtype, &subtype);
			if (subtype.kind != TYPE_CHARACTER) {
				break;  // can only write character arrays
			}
			retrieveChunk(arg.left, &leftExpr);
			retrieveChunk(leftExpr.node, &node);
			if (arg.width) {
				genExpr(arg.width, 1, 1, 0);
			} else {
				genTwo(LDA_IMMEDIATE, 0);
				genOne(TAX);
			}
			genRuntimeCall(rtPushAx);
			genTwo(LDA_IMMEDIATE, node.level);
			genTwo(LDX_IMMEDIATE, node.offset);
			genRuntimeCall(rtWriteCharArray);
			break;
		}
		}

		argChunk = arg.right;
	}

	if (rc == rcWriteln) {
		genTwo(LDA_IMMEDIATE, 13);	// carriage return
		genThreeAddr(JSR, CHROUT);
	}
}
