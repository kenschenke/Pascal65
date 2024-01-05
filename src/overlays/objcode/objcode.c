#include <stdio.h>
#include <codegen.h>
#include <chunks.h>
#include <membuf.h>
#include <asm.h>
#include <string.h>
#include <int16.h>
#include <common.h>

static int addStringLiteral(CHUNKNUM chunkNum);
static int genUnitDeclarations(short* heapOffsets);
static void genUnitRoutines(void);

#define FREE_VAR_HEAPS_OFFSET 3
static unsigned char freeVarHeapsCode[] = {
	LDA_ZEROPAGE, ZP_NESTINGLEVEL,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_CALCSTACK), WORD_HIGH(RT_CALCSTACK),
	LDY_IMMEDIATE, 1,
	LDA_ZPINDIRECT, ZP_PTR1L,
	TAX,
	DEY,
	LDA_ZPINDIRECT, ZP_PTR1L,
	JSR, WORD_LOW(RT_HEAPFREE), WORD_HIGH(RT_HEAPFREE),
};

static int addStringLiteral(CHUNKNUM chunkNum)
{
	if (numStringLiterals == 0) {
		allocMemBuf(&stringLiterals);
	}

	writeToMemBuf(stringLiterals, &chunkNum, sizeof(CHUNKNUM));

	return ++numStringLiterals;
}

void genFreeVariableHeaps(short* heapOffsets)
{
	int i = 0;

	while (heapOffsets[i] >= 0) {
		freeVarHeapsCode[FREE_VAR_HEAPS_OFFSET] = heapOffsets[i];
		writeCodeBuf(freeVarHeapsCode, 18);
		++i;
	}
}

void genRealValueEAX(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		genOne(TAX);
		genTwo(STA_ZEROPAGE, ZP_SREGL);
		genTwo(STA_ZEROPAGE, ZP_SREGH);
		return;
	}

	retrieveChunk(chunkNum, &_expr);

	// Pointer to the real string in A/X
	genStringValueAX(_expr.value.stringChunkNum);
	// Convert to float in FPACC
	genThreeAddr(JSR, RT_STRTOFLOAT);

	if (_expr.neg) {
		genThreeAddr(JSR, RT_FLOATNEG);
	}
}

void genStringValueAX(CHUNKNUM chunkNum)
{
	char label[15];

	int num = addStringLiteral(chunkNum);
	strcpy(label, "strVal");
	strcat(label, formatInt16(num));
	linkAddressLookup(label, codeOffset + 1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(label, codeOffset + 1, 0, LINKADDR_HIGH);
	genTwo(LDX_IMMEDIATE, 0);
}

static int genUnitDeclarations(short* heapOffsets)
{
	int numToPop = 0;
	struct unit _unit;
	struct decl _decl;
	struct stmt _stmt;
	CHUNKNUM chunkNum = units;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);
		retrieveChunk(_unit.astRoot, &_decl);
		retrieveChunk(_decl.code, &_stmt);
		numToPop += genVariableDeclarations(_stmt.decl, heapOffsets);
		numToPop += genVariableDeclarations(_stmt.interfaceDecl, heapOffsets);

		chunkNum = _unit.next;
	}

	return numToPop;
}

static void genUnitRoutines(void)
{
	struct decl _decl;
	struct stmt _stmt;
	struct unit _unit;
	CHUNKNUM chunkNum = units;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);
		retrieveChunk(_unit.astRoot, &_decl);
		retrieveChunk(_decl.code, &_stmt);

		genRoutineDeclarations(_stmt.decl);

		chunkNum = _unit.next;
	}
}

void objCodeWrite(CHUNKNUM astRoot)
{
	struct decl _decl;
	struct stmt _stmt;
	int i, numToPop;
	short heapOffsets[MAX_LOCAL_HEAPS];

	retrieveChunk(astRoot, &_decl);
	scope_enter_symtab(_decl.symtab);
	retrieveChunk(_decl.code, &_stmt);

	// Create stack entries for the global variables
	numToPop = genVariableDeclarations(_stmt.decl, heapOffsets);
	numToPop += genUnitDeclarations(heapOffsets);

	// Skip over global function/procedure declarations and start main code
	linkAddressLookup("MAIN", codeOffset + 1, 0, LINKADDR_BOTH);
	genThreeAddr(JMP, 0);

	genRoutineDeclarations(_stmt.decl);

	genUnitRoutines();

	// Walk the declarations tree and define setup and tear down
	// routines for every Pascal routine at any nesting level.
	// Also define code routines for each Pascal routine.

	// Statements in main block
	linkAddressSet("MAIN", codeOffset);
	genStmts(_stmt.body);

	// Clean up the declarations from the stack
	for (i = 0; i < numToPop; ++i) {
		genThreeAddr(JSR, RT_INCSP4);
	}

	scope_exit();
}
