#include <stdio.h>

#include <codegen.h>
#include <asm.h>
#include <ast.h>
#include <symtab.h>
#include <common.h>
#include <real.h>

#include <string.h>

static 	char name[CHUNK_LEN + 1], enterLabel[15], returnLabel[15];

static void genAbsCall(CHUNKNUM argChunk);
static void genChrCall(CHUNKNUM argChunk);
static void genDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk);
static void genOddCall(CHUNKNUM argChunk);
static void genOrdCall(CHUNKNUM argChunk);
static void genPredSuccCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk);
static void genRoundTruncCall(TRoutineCode rc, CHUNKNUM argChunk);
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

#define PRED_SUCC_JSR 12
static unsigned char predSuccCode[] = {
	JSR, WORD_LOW(RT_POPTOINTOP1), WORD_HIGH(RT_POPTOINTOP1),
	LDA_IMMEDIATE, 1,
	STA_ZEROPAGE, ZP_INTOP2L,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_INTOP2H,
	JSR, 0, 0,
	JSR, WORD_LOW(RT_PUSHINTOP1), WORD_HIGH(RT_PUSHINTOP1),
};

static void genAbsCall(CHUNKNUM argChunk)
{
	struct expr arg;
	struct type argType;

	retrieveChunk(argChunk, &arg);
	retrieveChunk(arg.evalType, &argType);

	if (argType.kind == TYPE_INTEGER) {
		genExpr(arg.left, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOINTOP1);
		genThreeAddr(JSR, RT_ABSINT16);
		genThreeAddr(JSR, RT_PUSHINTOP1);
	}
	else {
		genExpr(arg.left, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOREAL);
		genThreeAddr(JSR, RT_FLOATABS);
		genThreeAddr(JSR, RT_PUSHREAL);
	}
}

static void genChrCall(CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0, 0);
	genThreeAddr(JSR, RT_POPTOINTOP1);
	genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
	genThreeAddr(JSR, RT_PUSHBYTE);
}

static void genDeclaredSubroutineCall(CHUNKNUM exprChunk, CHUNKNUM declChunk, struct type* pType, CHUNKNUM argChunk)
{
	CHUNKNUM localChunk, paramChunk = pType->paramsFields;
	struct expr _expr, exprLeft;
	struct decl _decl, localDecl;
	struct stmt _stmt;
	struct param_list param;
	struct type argType, paramType, localType;
	struct symbol sym;

	retrieveChunk(declChunk, &_decl);
	retrieveChunk(_decl.node, &sym);

	// Set up the stack frame
	sprintf(returnLabel, "RTN%04xRETURN", exprChunk);
	linkAddressLookup(returnLabel, codeOffset + 1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(returnLabel, codeOffset + 1, 0, LINKADDR_HIGH);
	genTwo(LDX_IMMEDIATE, 0);
	genTwo(LDY_IMMEDIATE, (unsigned char)sym.level);
	genThreeAddr(JSR, RT_PUSHSTACKFRAMEHEADER);
	// Save the new stack frame pointer
	genOne(PHA);
	genOne(TXA);
	genOne(PHA);

	// Set up the routine's local variables

	retrieveChunk(declChunk, &_decl);
	retrieveChunk(_decl.code, &_stmt);
	localChunk = _stmt.decl;
	while (localChunk) {
		retrieveChunk(localChunk, &localDecl);
		memset(name, 0, sizeof(name));
		retrieveChunk(localDecl.name, name);
		retrieveChunk(localDecl.type, &localType);

		localChunk = localDecl.next;
	}

	// Push the arguments onto the stack
	while (argChunk) {
		retrieveChunk(argChunk, &_expr);
		retrieveChunk(_expr.evalType, &argType);
		retrieveChunk(paramChunk, &param);
		retrieveChunk(param.type, &paramType);

		retrieveChunk(_expr.left, &exprLeft);

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
			genExpr(_expr.left, 0, 1, 0);
			paramByRef2[PARAM_BYREF2_SIZEL] = WORD_LOW(paramType.size);
			paramByRef2[PARAM_BYREF2_SIZEH] = WORD_HIGH(paramType.size);
			writeCodeBuf(paramByRef2, 27);
		}
		else if (paramType.flags & TYPE_FLAG_ISBYREF) {
			genExpr(_expr.left, 0, 1, 0);
			genThreeAddr(JSR, RT_PUSHADDRSTACK);
		}
		else {
			genExpr(_expr.left, 1, 0, 0);
		}

		// How do I match this up to the param_list for the routine?
		argChunk = _expr.right;
		paramChunk = param.next;
	}

	// Activate the new stack frame
	activateFrame[ACTIVATE_FRAME_LEVEL] = sym.level;
	writeCodeBuf(activateFrame, 13);

	// Call the routine
	sprintf(enterLabel, "RTN%04xENTER", declChunk);
	linkAddressLookup(enterLabel, codeOffset + 1, 0, LINKADDR_BOTH);
	genThreeAddr(JMP, 0);

	linkAddressSet(returnLabel, codeOffset);

	// Tear down the routine's stack frame and free local variables

	if (pType->kind == TYPE_PROCEDURE) {
		// Clean the un-used return value off the stack
		genThreeAddr(JSR, RT_INCSP4);
	}

	genOne(PLA);
	genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);
}

static void genOddCall(CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0, 0);
	genThreeAddr(JSR, RT_POPTOINTOP1);
	genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
	genTwo(AND_IMMEDIATE, 1);
	genThreeAddr(JSR, RT_PUSHBYTE);
}

static void genOrdCall(CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0, 0);
}

static void genPredSuccCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	unsigned call = rc == rcPred ? RT_SUBINT16 : RT_ADDINT16;
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0, 0);
	predSuccCode[PRED_SUCC_JSR] = WORD_LOW(call);
	predSuccCode[PRED_SUCC_JSR + 1] = WORD_HIGH(call);
	writeCodeBuf(predSuccCode, 17);
}

static void genReadReadlnCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;
	struct type _type;

	while (argChunk) {
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &_type);

		switch (_type.kind) {
		case TYPE_INTEGER:
			genThreeAddr(JSR, RT_READINTFROMINPUT);
			genThreeAddr(JSR, RT_PUSHINT);
			genExpr(arg.left, 0, 0, 0);
			genThreeAddr(JSR, RT_STOREINT);
			break;

		case TYPE_REAL:
			genThreeAddr(JSR, RT_READFLOATFROMINPUT);
			genThreeAddr(JSR, RT_PUSHREAL);
			genExpr(arg.left, 0, 0, 0);
			genThreeAddr(JSR, RT_STOREREAL);
			break;
		}

		argChunk = arg.right;
	}

	if (rc == rcReadln) {
		genThreeAddr(JSR, RT_CLRINPUT);
	}
}

static void genRoundTruncCall(TRoutineCode rc, CHUNKNUM argChunk)
{
	struct expr arg;

	retrieveChunk(argChunk, &arg);

	genExpr(arg.left, 1, 0, 0);
	genThreeAddr(JSR, RT_POPTOREAL);
	if (rc == rcRound) {
		genTwo(LDA_IMMEDIATE, 0);	// Round to 0 decimal places
		genThreeAddr(JSR, RT_PRECRD);
	}
	genThreeAddr(JSR, RT_FLOATTOINT16);
	genThreeAddr(JSR, RT_PUSHINTOP1);
}

static void genRoutineDeclaration(CHUNKNUM chunkNum, struct decl* pDecl, struct type* pDeclType)
{
	short heapOffsets[MAX_LOCAL_HEAPS];
	char name[CHUNK_LEN + 1], startLabel[15];
	struct stmt _stmt;
	int numLocals, offset = -1, numHeap = 0;
	CHUNKNUM paramChunk;
	struct param_list param;
	struct type paramType;

	retrieveChunk(pDecl->code, &_stmt);

	genRoutineDeclarations(_stmt.decl);

	memset(name, 0, sizeof(name));
	retrieveChunk(pDecl->name, name);
	sprintf(startLabel, "RTN%04xENTER", chunkNum);
	linkAddressSet(startLabel, codeOffset);

	// Push the local variables onto the stack
	numLocals = genVariableDeclarations(_stmt.decl, heapOffsets);

	genStmts(_stmt.body);

	// Count of the number of heap offsets already declared
	while (heapOffsets[numHeap] >= 0) {
		numHeap++;
	}

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

	if (argType.kind == TYPE_INTEGER) {
		genExpr(arg.left, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOINTOP1);
		genThreeAddr(JSR, RT_INT16SQR);
		genThreeAddr(JSR, RT_PUSHINTOP1);
	}
	else {
		genExpr(arg.left, 1, 0, 0);
		genThreeAddr(JSR, RT_POPTOREAL);
		genThreeAddr(JSR, RT_COPYFPACC);
		genThreeAddr(JSR, RT_FPMULT);
		genThreeAddr(JSR, RT_PUSHREAL);
	}
}

void genSubroutineCall(CHUNKNUM chunkNum)
{
	struct expr _expr, rtnExpr;
	struct symbol sym;
	struct type rtnType;

	retrieveChunk(chunkNum, &_expr);
	retrieveChunk(_expr.left, &rtnExpr);
	retrieveChunk(rtnExpr.node, &sym);
	retrieveChunk(sym.type, &rtnType);
	if (rtnType.flags & TYPE_FLAG_ISSTD) {
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

	case rcChr:
		genChrCall(argChunk);
		break;

	case rcSqr:
		genSqrCall(argChunk);
		break;

	case rcRound:
	case rcTrunc:
		genRoundTruncCall(rc, argChunk);
		break;

	case rcOdd:
		genOddCall(argChunk);
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
	char labelBool[15];
	struct expr arg;
	struct type _type;

	while (argChunk) {
		retrieveChunk(argChunk, &arg);
		retrieveChunk(arg.evalType, &_type);

		switch (_type.kind) {
		case TYPE_BOOLEAN:
			sprintf(labelBool, "LBF%04x", argChunk);
			if (arg.width) {
				genExpr(arg.width, 1, 1, 0);
				genOne(PHA);
			}
			genExpr(arg.left, 1, 0, 0);
			genThreeAddr(JSR, RT_POPTOINTOP1);
			if (arg.width) {
				genTwo(LDX_IMMEDIATE, 5);
				genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
				genTwo(BEQ, 2);		// boolean value is false - value width is 5
				genTwo(LDX_IMMEDIATE, 4);
				genOne(PLA);
				genThreeAddr(JSR, RT_LEFTPAD);
			}
			genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
			genTwo(BEQ, 7);		// boolean value is false - load "false" in ptr1
			linkAddressLookup(DATA_BOOLTRUE, codeOffset + 1, 0, LINKADDR_LOW);
			genTwo(LDA_IMMEDIATE, 0);
			linkAddressLookup(DATA_BOOLTRUE, codeOffset + 1, 0, LINKADDR_HIGH);
			genTwo(LDX_IMMEDIATE, 0);
			linkAddressLookup(labelBool, codeOffset + 1, 0, LINKADDR_BOTH);
			genThreeAddr(JMP, 0);	// skip to printing the boolean value
			// Boolean value is false
			linkAddressLookup(DATA_BOOLFALSE, codeOffset + 1, 0, LINKADDR_LOW);
			genTwo(LDA_IMMEDIATE, 0);
			linkAddressLookup(DATA_BOOLFALSE, codeOffset + 1, 0, LINKADDR_HIGH);
			genTwo(LDX_IMMEDIATE, 0);
			linkAddressSet(labelBool, codeOffset);
			genThreeAddr(JSR, RT_PRINTZ);
			break;

		case TYPE_CHARACTER:
			if (arg.width) {
				genExpr(arg.width, 1, 1, 0);
				genTwo(LDX_IMMEDIATE, 1);
				genThreeAddr(JSR, RT_LEFTPAD);
			}
			genExpr(arg.left, 1, 1, 0);
			genThreeAddr(JSR, CHROUT);
			break;

		case TYPE_INTEGER:
			if (arg.width) {
				genExpr(arg.width, 1, 1, 0);
				genOne(PHA);
			}
			genExpr(arg.left, 1, 0, 0);
			genThreeAddr(JSR, RT_POPTOINTOP1);
			if (arg.width) {
				genOne(PLA);
			}
			else {
				genTwo(LDA_IMMEDIATE, 0);	// field width
			}
			genThreeAddr(JSR, RT_WRITEINT16);
			genTwo(LDA_ZEROPAGE, ZP_INTPTR);
			genTwo(LDX_ZEROPAGE, ZP_INTPTR + 1);
			genThreeAddr(JSR, RT_PRINTZ);
			break;

		case TYPE_REAL:
			genExpr(arg.left, 1, 0, 0);
			genThreeAddr(JSR, RT_POPTOREAL);
			if (arg.precision) {
				genExpr(arg.precision, 1, 1, 0);
			}
			else {
				genTwo(LDA_IMMEDIATE, 0xff);
			}
			genThreeAddr(JSR, RT_FPOUT);
			if (arg.width) {
				genOne(PHA);	// Preserve the value width
				genExpr(arg.width, 1, 1, 0);
				genOne(TAY);	// Save field width in Y for a sec
				genOne(PLA);	// Pull value width from stack
				genOne(TAX);	// Value width in X
				genOne(TYA);	// Field width in A
				genThreeAddr(JSR, RT_LEFTPAD);
			}
			genThreeAddr(JSR, RT_GETFPBUF);
			genThreeAddr(JSR, RT_PRINTZ);
			break;

		case TYPE_STRING:
			genExpr(arg.left, 1, 0, 0);
			genThreeAddr(JSR, RT_POPEAX);
			genThreeAddr(JSR, RT_PRINTZ);
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
			retrieveChunk(_type.indextype, &_type);
			genExpr(_type.min, 1, 1, 0);
			genThreeAddr(JSR, RT_PUSHAX);
			genExpr(_type.max, 1, 1, 0);
			genThreeAddr(JSR, RT_PUSHAX);
			genTwo(LDA_IMMEDIATE, node.level);
			genTwo(LDX_IMMEDIATE, node.offset);
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
}
