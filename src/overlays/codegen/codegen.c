#include <stdio.h>
#include <string.h>

#include <buffer.h>
#include <codegen.h>
#include <asm.h>
#include <ast.h>
#include <membuf.h>
#include <error.h>
#include <real.h>
#include <cbm.h>

#define RUNTIME_STACK_SIZE 2048

static CHUNKNUM stringLiterals;
static int numStringLiterals;

CHUNKNUM codeBuf;
unsigned short codeOffset;
unsigned short codeBase;

#ifdef COMPILERTEST
static unsigned char chainCall[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 8,		// Offset 3: device
	LDY_IMMEDIATE, 0xff,
	JSR, 0xba, 0xff,		// SETLFS

	LDA_IMMEDIATE, 0,		// Offset 10: strlen(name)
	LDX_IMMEDIATE, 0x1c,	// Offset 12: lower str address
	LDY_IMMEDIATE, 0xca,	// Offset 14: upper str address
	JSR, 0xbd, 0xff,		// SETNAM

	LDA_IMMEDIATE, 0,
	TAX,
	TAY,
	JSR, 0xd5, 0xff,		// LOAD

	JMP, 0x0d, 0x08,
};
#endif

// Used when initializing nested arrays and records
static short heapOffset;

static int addStringLiteral(CHUNKNUM chunkNum);
static void dumpStringLiterals(void);
static void freeStringLiterals(void);
static void genArrayInit(struct type* pType, char isParentAnArray, char isParentHeapVar,
	int numElements, CHUNKNUM arrayNum);
static void genExeHeader(void);
static void genRecordInit(struct type* pType);
static void genRuntime(void);
int getArrayLimit(CHUNKNUM chunkNum);
static void updateHeapOffset(short newOffset);

#ifdef COMPILERTEST
// static void copyChainCall(char* name);
static void writeChainCall(char* name);
#endif

static int addStringLiteral(CHUNKNUM chunkNum)
{
	if (numStringLiterals == 0) {
		allocMemBuf(&stringLiterals);
	}

	writeToMemBuf(stringLiterals, &chunkNum, sizeof(CHUNKNUM));

	return ++numStringLiterals;
}

static void dumpStringLiterals(void)
{
	int num = 1, pos;
	char label[15], value[MAX_LINE_LEN + 4];
	CHUNKNUM chunkNum;

	if (!numStringLiterals) {
		return;
	}

	setMemBufPos(stringLiterals, 0);
	while (!isMemBufAtEnd(stringLiterals)) {
		readFromMemBuf(stringLiterals, &chunkNum, sizeof(CHUNKNUM));
		memset(value, 0, sizeof(value));
		setMemBufPos(chunkNum, 0);
		pos = 0;
		while (!isMemBufAtEnd(chunkNum)) {
			readFromMemBuf(chunkNum, value + pos, 1);
			++pos;
		}
		value[pos] = 0;
		sprintf(label, "strVal%d", num);
		linkAddressSet(label, codeOffset);
		writeToMemBuf(codeBuf, value, (short)strlen(value) + 1);
		codeOffset += (short)strlen(value) + 1;

		++num;
	}
}

static void freeStringLiterals(void)
{
	if (stringLiterals && isChunkAllocated(stringLiterals)) {
		freeMemBuf(stringLiterals);
	}

	stringLiterals = 0;
	numStringLiterals = 0;
}

void genOne(unsigned char b)
{
	writeToMemBuf(codeBuf, &b, 1);
	++codeOffset;
}

void genTwo(unsigned char b1, unsigned char b2)
{
	unsigned char buf[2];

    buf[0] = b1;
    buf[1] = b2;

	writeToMemBuf(codeBuf, buf, 2);
	codeOffset += 2;
}

void genThreeAddr(unsigned char b, unsigned short addr)
{
	unsigned char buf[3];

    buf[0] = b;
    buf[1] = WORD_LOW(addr);
    buf[2] = WORD_HIGH(addr);

	writeToMemBuf(codeBuf, buf, 3);
	codeOffset += 3;
}

static void genArrayInit(struct type* pType, char isParentAnArray, char isParentHeapVar,
	int numElements, CHUNKNUM arrayNum)
{
	char label[15];
	unsigned short branchOffest;
	struct type indexType, elemType;
	short size = pType->size;

	retrieveChunk(pType->indextype, &indexType);
	retrieveChunk(pType->subtype, &elemType);
	if (isParentAnArray) {
		// Loop through and intialize each child array of the parent array
		// Parent is an array
		// Initialize number of elements in tmp1/tmp2
		genTwo(LDA_IMMEDIATE, WORD_LOW(numElements));	// lda #{numElements & 0xff}
		genTwo(STA_ZEROPAGE, ZP_TMP1);					// sta tmp1
		genTwo(LDA_IMMEDIATE, WORD_HIGH(numElements));	// lda #{numElements >> 8}
		genTwo(STA_ZEROPAGE, ZP_TMP2);					// sta tmp2
		branchOffest = codeOffset;
		sprintf(label, "ARRAY%04x", arrayNum);
		linkAddressSet(label, codeOffset);
		// Initialize this array's heap
		genTwo(LDA_IMMEDIATE, WORD_LOW(elemType.size));	// lda #{elemType.size & 0xff}
		genTwo(LDX_IMMEDIATE, WORD_HIGH(elemType.size));	// ldx #{elemType.size >> 8}
		genThreeAddr(JSR, RT_PUSHAX);
		// Array upper bound
		genExpr(indexType.max, 0, 1, 0);
		genThreeAddr(JSR, RT_PUSHAX);
		// Array lower bound
		genExpr(indexType.min, 0, 1, 0);
		genThreeAddr(JSR, RT_PUSHAX);
		// heap address must be in A/X
		genTwo(LDA_ZEROPAGE, ZP_PTR1L);
		genTwo(LDX_ZEROPAGE, ZP_PTR1H);
		genThreeAddr(JSR, RT_INITARRAYHEAP);
		// Advance ptr1 past array header
		updateHeapOffset(heapOffset + 6);

		// Check if the element is a record
		if (elemType.kind == TYPE_DECLARED) {
			char name[CHUNK_LEN + 1];
			struct symbol sym;
			memset(name, 0, sizeof(name));
			if (!scope_lookup(name, &sym)) {
				Error(errUndefinedIdentifier);
				return;
			}
			retrieveChunk(sym.type, &elemType);
		}
		if (elemType.kind == TYPE_RECORD) {
            int i;
			for (i = 0; i < numElements; ++i) {
				genRecordInit(&elemType);
			}
		}
		else {
			// Advance prt1 past array elements
			updateHeapOffset(heapOffset + size - 6);
		}

		// Decrement tmp1/tmp2
		genTwo(DEC_ZEROPAGE, ZP_TMP1);
		genTwo(BNE, 256 - (codeOffset - branchOffest) - 2);
		genTwo(LDA_ZEROPAGE, ZP_TMP2);
		genTwo(BEQ, 5);
		genTwo(DEC_ZEROPAGE, ZP_TMP2);
		linkAddressLookup(label, codeOffset + 1, 0, LINKADDR_BOTH);
		genThreeAddr(JMP, 0);
	}
	else {
		if (!isParentHeapVar) {
			// Allocate array heap
			genTwo(LDA_IMMEDIATE, WORD_LOW(size));
			genTwo(LDX_IMMEDIATE, WORD_HIGH(size));
			genThreeAddr(JSR, RT_HEAPALLOC);
			genTwo(STA_ZEROPAGE, ZP_PTR1L);
			genTwo(STX_ZEROPAGE, ZP_PTR1H);
			genThreeAddr(JSR, RT_PUSHINT);
		}
		else {
			// Restore ptr1 from parent heap
			genTwo(LDA_ZEROPAGE, ZP_PTR1L);
			genTwo(LDX_ZEROPAGE, ZP_PTR1H);
		}
		// keep the heap pointer
		genOne(PHA);
		genOne(TXA);
		genOne(PHA);

		// Array element size
		genTwo(LDA_IMMEDIATE, WORD_LOW(elemType.size));
		genTwo(LDX_IMMEDIATE, WORD_HIGH(elemType.size));
		genThreeAddr(JSR, RT_PUSHAX);
		// Array upper bound
		genExpr(indexType.max, 0, 1, 0);
		genThreeAddr(JSR, RT_PUSHAX);
		// Array lower bound
		genExpr(indexType.min, 0, 1, 0);
		genThreeAddr(JSR, RT_PUSHAX);
		// heap address must be in A/X
		genOne(PLA);	// Restore ptr1 for call to initArrayHeap
		genOne(TAX);
		genOne(PLA);
		genThreeAddr(JSR, RT_INITARRAYHEAP);
		// Advance ptr1 past array header
		updateHeapOffset(heapOffset + 6);
		if (elemType.kind == TYPE_ARRAY) {
			int lowBound = getArrayLimit(indexType.min);
			int highBound = getArrayLimit(indexType.max);
			genArrayInit(&elemType, 1, 1, highBound - lowBound + 1, pType->subtype);
		}

		// Check if the element is a record
		if (elemType.kind == TYPE_DECLARED) {
			char name[CHUNK_LEN + 1];
			struct symbol sym;
			memset(name, 0, sizeof(name));
			retrieveChunk(elemType.name, name);
			if (!scope_lookup(name, &sym)) {
				Error(errUndefinedIdentifier);
				return;
			}
			retrieveChunk(sym.type, &elemType);
		}
		if (elemType.kind == TYPE_RECORD) {
			short offset = heapOffset + elemType.size;
			// Loop through and intialize each child array of the parent array
			// Array element is record
			// Store number of elements in tmp1/tmp2
			genTwo(LDA_IMMEDIATE, WORD_LOW(numElements));
			genTwo(STA_ZEROPAGE, ZP_TMP1);
			genTwo(LDA_IMMEDIATE, WORD_HIGH(numElements));
			genTwo(STA_ZEROPAGE, ZP_TMP2);
			sprintf(label, "ARRAY%04x", arrayNum);
			branchOffest = codeOffset;
			linkAddressSet(label, codeOffset);
			// Initialize record
			genRecordInit(&elemType);
			// Decrement tmp1/tmp2
			genTwo(DEC_ZEROPAGE, ZP_TMP1);
			genTwo(BNE, 256 - (codeOffset - branchOffest) - 2);
			genTwo(LDA_ZEROPAGE, ZP_TMP2);
			genTwo(BEQ, 5);
			genTwo(DEC_ZEROPAGE, ZP_TMP2);
			linkAddressLookup(label, codeOffset + 1, 0, LINKADDR_BOTH);
			genThreeAddr(JMP, 0);

			heapOffset += elemType.size * numElements;
		}
	}
}

static void genExeHeader(void)
{
	char startAddr[5], buf[2];

	// Link to next line
	buf[0] = WORD_LOW(codeBase + 10);
	buf[1] = WORD_HIGH(codeBase + 10);
	writeToMemBuf(codeBuf, buf, 2);

	// Line number
	buf[0] = 10;
	buf[1] = 0;
	writeToMemBuf(codeBuf, buf, 2);

	// SYS token
	buf[0] = 0x9e;  // SYS
	writeToMemBuf(codeBuf, buf, 1);

	// Starting address of code
	sprintf(startAddr, "%04d", codeBase + 12);
	writeToMemBuf(codeBuf, startAddr, 4);

	// End of BASIC line
	buf[0] = 0;
	writeToMemBuf(codeBuf, buf, 1);

	// End of BASIC program marker
	writeToMemBuf(codeBuf, buf, 2);

	codeOffset = 12;
}

void genFreeVariableHeaps(short* heapOffsets)
{
	int i = 0;

	while (heapOffsets[i] >= 0) {
		genTwo(LDA_ZEROPAGE, ZP_NESTINGLEVEL);
		genTwo(LDX_IMMEDIATE, WORD_LOW(heapOffsets[i]));
		genThreeAddr(JSR, RT_CALCSTACK);
		genTwo(LDY_IMMEDIATE, 1);
		genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
		genOne(TAX);
		genOne(DEY);
		genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
		genThreeAddr(JSR, RT_HEAPFREE);
		++i;
	}
}

static void genRecordInit(struct type* pType)
{
	struct decl _decl;
	struct type _type;
	short offset = heapOffset;
	CHUNKNUM chunkNum = pType->paramsFields;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		retrieveChunk(_decl.type, &_type);

		if (_type.kind == TYPE_DECLARED) {
			struct symbol sym;
			retrieveChunk(_decl.node, &sym);
			retrieveChunk(sym.type, &_type);
		}

		if (_type.kind == TYPE_RECORD) {
			genRecordInit(&_type);
		}

		if (_type.kind == TYPE_ARRAY) {
			struct type indexType;
            int lowerBound, upperBound;
			retrieveChunk(_type.indextype, &indexType);
			lowerBound = getArrayLimit(indexType.min);
			upperBound = getArrayLimit(indexType.max);
			updateHeapOffset(offset);
			// Record field is an array
			genArrayInit(&_type, 0, 1, upperBound - lowerBound + 1, chunkNum);
		}

		offset += _type.size;
		chunkNum = _decl.next;
	}

	if (offset > heapOffset) {
		// Advance ptr1 the remainder of the record
		updateHeapOffset(offset);
	}
}

int genVariableDeclarations(CHUNKNUM chunkNum, short* heapOffsets)
{
	char name[CHUNK_LEN + 1];
	struct decl _decl;
	struct type _type;
	struct symbol sym;
	int num = 0, heapVar = 0;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);

		if (_decl.kind == DECL_CONST || _decl.kind == DECL_VARIABLE) {
			retrieveChunk(_decl.type, &_type);

			if (_type.flags & TYPE_FLAG_ISRETVAL) {
				chunkNum = _decl.next;
				continue;
			}

			memset(name, 0, sizeof(name));
			retrieveChunk(_decl.name, name);

			if (_decl.node) {
				retrieveChunk(_decl.node, &sym);
			}
			else {
				sym.offset = -1;
			}

			switch (_type.kind) {
			case TYPE_INTEGER:
			case TYPE_BOOLEAN:
			case TYPE_ENUMERATION:
				genIntValueAX(_decl.value);
				genThreeAddr(JSR, RT_PUSHINT);
				break;

			case TYPE_CHARACTER:
				genCharValueA(_decl.value);
				genTwo(LDX_IMMEDIATE, 0);
				genThreeAddr(JSR, RT_PUSHINT);
				break;

			case TYPE_REAL:
				genRealValueEAX(_decl.value);
				genThreeAddr(JSR, RT_PUSHREAL);
				break;

			case TYPE_ARRAY: {
				struct type indexType;
                int lowerBound, upperBound;
				retrieveChunk(_type.indextype, &indexType);
				lowerBound = getArrayLimit(indexType.min);
				upperBound = getArrayLimit(indexType.max);
				heapOffset = 0;
				genArrayInit(&_type, 0, 0, upperBound - lowerBound + 1, chunkNum);
				heapOffsets[heapVar++] = sym.offset;
				break;
			}

			case TYPE_RECORD:
				genTwo(LDA_IMMEDIATE, WORD_LOW(_type.size));
				genTwo(LDX_IMMEDIATE, WORD_HIGH(_type.size));
				genThreeAddr(JSR, RT_HEAPALLOC);
				genTwo(STA_ZEROPAGE, ZP_PTR1L);
				genTwo(STX_ZEROPAGE, ZP_PTR1H);
				genThreeAddr(JSR, RT_PUSHINT);
				heapOffset = 0;
				genRecordInit(&_type);
				heapOffsets[heapVar++] = sym.offset;
				break;
			}

			++num;
		}

		chunkNum = _decl.next;
	}

	heapOffsets[heapVar] = -1;

	return num;
}

#ifdef COMPILERTEST
void genProgram(CHUNKNUM astRoot, const char*prgFilename, char* nextTest)
#else
void genProgram(CHUNKNUM astRoot, const char* prgFilename)
#endif
{
	FILE* out;
	char ch;

	short heapOffsets[MAX_LOCAL_HEAPS];
	struct decl _decl;
	struct stmt _stmt;
	int i, numToPop;

	codeBase = 0x801;
	allocMemBuf(&codeBuf);
	initLinkerSymbolTable();

	// Write the BASIC stub to start the program code
	// (this also initializes codeOffset)
	genExeHeader();

	linkAddressLookup("INIT", codeOffset + 1, 0, LINKADDR_BOTH);
	genThreeAddr(JMP, 0);

	genRuntime();

	linkAddressSet("INIT", codeOffset);

	// Make a backup copy of page zero
	genTwo(LDX_IMMEDIATE, 0);
	genTwo(LDA_X_INDEXED_ZP, 0x02);
	linkAddressLookup(BSS_ZPBACKUP, codeOffset + 1, 0, LINKADDR_BOTH);
	genThreeAddr(STA_ABSOLUTEX, 0);
	genOne(INX);
	genTwo(CPX_IMMEDIATE, 0x1b);
	genTwo(BNE, 0xf6);

	// Save the stack pointer
	genOne(TSX);
	genTwo(STX_ZEROPAGE, ZP_SAVEDSTACK);

	genThreeAddr(JSR, RT_ERRORINIT);

	// Initialize runtime stack
	genTwo(LDA_IMMEDIATE, 0);
	genTwo(STA_ZEROPAGE, ZP_SPL);
	genTwo(STA_ZEROPAGE, ZP_STACKFRAMEL);
	genTwo(LDA_IMMEDIATE, 0xd0);
	genTwo(STA_ZEROPAGE, ZP_SPH);
	genTwo(STA_ZEROPAGE, ZP_STACKFRAMEH);
	
	// Set the runtime stack size and initialize the stack
	genTwo(LDA_IMMEDIATE, WORD_LOW(RUNTIME_STACK_SIZE));
	genTwo(LDX_IMMEDIATE, WORD_HIGH(RUNTIME_STACK_SIZE));
	genThreeAddr(JSR, RT_STACKINIT);	// Initialize runtime stack

	genTwo(LDA_IMMEDIATE, WORD_LOW(0xd000 - RUNTIME_STACK_SIZE - 4));
	genTwo(LDX_IMMEDIATE, WORD_HIGH(0xd000 - RUNTIME_STACK_SIZE - 4));
	genThreeAddr(JSR, RT_PUSHAX);
	linkAddressLookup(BSS_HEAPBOTTOM, codeOffset + 1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(BSS_HEAPBOTTOM, codeOffset + 1, 0, LINKADDR_HIGH);
	genTwo(LDX_IMMEDIATE, 0);
	genThreeAddr(JSR, RT_HEAPINIT);		// Initialize heap

	// Current nesting level
	genTwo(LDA_IMMEDIATE, 1);
	genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);

	// Switch to upper/lower case character set
	genTwo(LDA_IMMEDIATE, 0x0e);
	genThreeAddr(JSR, CHROUT);

	// Disable BASIC ROM
	genTwo(LDA_ZEROPAGE, 1);
	genTwo(AND_IMMEDIATE, 0xfe);
	genTwo(STA_ZEROPAGE, 1);

	// Clear the input buffer
	genThreeAddr(JSR, RT_CLRINPUT);

	// Initialize the int buffer
	linkAddressLookup(BSS_INTBUF, codeOffset + 1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	genTwo(STA_ZEROPAGE, ZP_INTPTR);
	linkAddressLookup(BSS_INTBUF, codeOffset + 1, 0, LINKADDR_HIGH);
	genTwo(LDA_IMMEDIATE, 0);
	genTwo(STA_ZEROPAGE, ZP_INTPTR + 1);

	retrieveChunk(astRoot, &_decl);
	scope_enter_symtab(_decl.symtab);
	retrieveChunk(_decl.code, &_stmt);

	// Create stack entries for the global variables
	numToPop = genVariableDeclarations(_stmt.decl, heapOffsets);

	// Skip over global function/procedure declarations and start main code
	linkAddressLookup("MAIN", codeOffset + 1, 0, LINKADDR_BOTH);
	genThreeAddr(JMP, 0);

	genRoutineDeclarations(_stmt.decl);

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

	// Clean up the program's stack frame
	genThreeAddr(JSR, RT_STACKCLEANUP);

	// Re-enable BASIC ROM
	genTwo(LDA_ZEROPAGE, 1);
	genTwo(ORA_IMMEDIATE, 1);
	genTwo(STA_ZEROPAGE, 1);

	// Copy the backup of page zero back
	genTwo(LDX_IMMEDIATE, 0);
	linkAddressLookup(BSS_ZPBACKUP, codeOffset + 1, 0, LINKADDR_BOTH);
	genThreeAddr(LDA_ABSOLUTEX, 0);
	genTwo(STA_X_INDEXED_ZP, 0x02);
	genOne(INX);
	genTwo(CPX_IMMEDIATE, 0x1b);
	genTwo(BNE, 0xf6);

#ifdef COMPILERTEST
	if (nextTest) {
		char msg[40];

		linkAddressLookup("CHAINMSG", codeOffset + 1, 0, LINKADDR_LOW);
		genTwo(LDA_IMMEDIATE, 0);
		linkAddressLookup("CHAINMSG", codeOffset + 1, 0, LINKADDR_HIGH);
		genTwo(LDX_IMMEDIATE, 0);
		genThreeAddr(JSR, RT_PRINTZ);

		linkAddressLookup("CHAINCALL", codeOffset + 1, 0, LINKADDR_LOW);
		genTwo(LDA_IMMEDIATE, 0);
		genTwo(STA_ZEROPAGE, ZP_PTR2L);
		linkAddressLookup("CHAINCALL", codeOffset + 1, 0, LINKADDR_HIGH);
		genTwo(LDA_IMMEDIATE, 0);
		genTwo(STA_ZEROPAGE, ZP_PTR2H);
		genTwo(LDA_IMMEDIATE, 0);
		genTwo(STA_ZEROPAGE, ZP_PTR1L);
		genTwo(LDA_IMMEDIATE, 0xca);
		genTwo(STA_ZEROPAGE, ZP_PTR1H);
		genTwo(LDA_IMMEDIATE, 28 + strlen(nextTest));
		genTwo(LDX_IMMEDIATE, 0);
		genThreeAddr(JSR, RT_MEMCOPY);
		genThreeAddr(JMP, 0xca00);
		writeChainCall(nextTest);	// filename of the next test in the chain

		sprintf(msg, "Loading %s...", nextTest);
		linkAddressSet("CHAINMSG", codeOffset);
		writeToMemBuf(codeBuf, msg, strlen(msg) + 1);
		codeOffset += strlen(msg) + 1;
	} else {
		genTwo(LDA_IMMEDIATE, 0);
		genOne(RTS);
	}
#else
	// Return to the OS
	genTwo(LDA_IMMEDIATE, 0);
	genOne(RTS);
#endif

	dumpStringLiterals();

	linkAddressSet(DATA_BOOLTRUE, codeOffset);
	writeToMemBuf(codeBuf, "true", 5);
	codeOffset += 5;

	linkAddressSet(DATA_BOOLFALSE, codeOffset);
	writeToMemBuf(codeBuf, "false", 6);
	codeOffset += 6;

	linkAddressSet(BSS_INTBUF, codeOffset);
	ch = 0;
	for (i = 0; i < 15; ++i) {
		writeToMemBuf(codeBuf, &ch, 1);
		++codeOffset;
	}

	// Set aside some memory to undo the changes to page zero
	linkAddressSet(BSS_ZPBACKUP, codeOffset);
	ch = 0;
	for (i = 0; i < 26; ++i) {
		writeToMemBuf(codeBuf, &ch, 1);
		++codeOffset;
	}

	// This MUST be the last thing written to the code buffer
	linkAddressSet(BSS_HEAPBOTTOM, codeOffset);
	ch = 0;
	writeToMemBuf(codeBuf, &ch, 1);
	writeToMemBuf(codeBuf, &ch, 1);

	updateLinkerAddresses(codeBuf);
	freeLinkerSymbolTable();

	_filetype = 'p';
	out = fopen(prgFilename, "w");
	ch = 1;
	fwrite(&ch, 1, 1, out);
	ch = 8;
	fwrite(&ch, 1, 1, out);

	setMemBufPos(codeBuf, 0);
	while (!isMemBufAtEnd(codeBuf)) {
		readFromMemBuf(codeBuf, &ch, 1);
		fwrite(&ch, 1, 1, out);
	}

	fclose(out);
	freeMemBuf(codeBuf);
	freeStringLiterals();
}

void genBoolValueA(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		return;
	}

	retrieveChunk(chunkNum, &_expr);
	genTwo(LDA_IMMEDIATE, _expr.value.character);
}

void genCharValueA(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		return;
	}

	retrieveChunk(chunkNum, &_expr);
	genTwo(LDA_IMMEDIATE, _expr.value.character);
	genTwo(LDX_IMMEDIATE, 0);
}

void genIntValueAX(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		genOne(TAX);
		return;
	}

	retrieveChunk(chunkNum, &_expr);
	if (_expr.neg) {
		_expr.value.integer = -_expr.value.integer;
	}
	genTwo(LDA_IMMEDIATE, WORD_LOW(_expr.value.integer));
	genTwo(LDX_IMMEDIATE, WORD_HIGH(_expr.value.integer));
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

	if (_expr.neg) {
        _expr.value.real = floatNeg(_expr.value.real);
	}

    genTwo(LDA_IMMEDIATE, DWORD_MSB(_expr.value.real));
    genTwo(STA_ZEROPAGE, ZP_SREGH);
    genTwo(LDA_IMMEDIATE, DWORD_NMSB(_expr.value.real));
    genTwo(STA_ZEROPAGE, ZP_SREGL);
    genTwo(LDX_IMMEDIATE, DWORD_NLSB(_expr.value.real));
    genTwo(LDA_IMMEDIATE, DWORD_LSB(_expr.value.real));
}

static void genRuntime(void)
{
    int i, read;
	char buf[10];
	FILE* in;

	in = fopen("runtime", "r");
	fread(buf, 1, 2, in);	// discard the starting address
	while (1) {
		read = fread(buf, 1, sizeof(buf), in);
		if (read < sizeof(buf)) {
			break;
		}
		writeToMemBuf(codeBuf, buf, read);
		codeOffset += read;
	}

	fclose(in);

	// Write an extra 200 bytes for BSS

	memset(buf, 0, sizeof(buf));
	for (i = 0; i < 20; ++i) {
		writeToMemBuf(codeBuf, buf, sizeof(buf));
		codeOffset += sizeof(buf);
	}
}

void genStringValueAX(CHUNKNUM chunkNum)
{
	char label[15];

	int num = addStringLiteral(chunkNum);
	sprintf(label, "strVal%d", num);
	linkAddressLookup(label, codeOffset + 1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(label, codeOffset + 1, 0, LINKADDR_HIGH);
	genTwo(LDX_IMMEDIATE, 0);

}

int getArrayLimit(CHUNKNUM chunkNum)
{
	struct expr _expr;

	retrieveChunk(chunkNum, &_expr);
	if (_expr.kind == EXPR_INTEGER_LITERAL) {
		return _expr.value.integer;
	}
	else {
		Error(rteUnimplementedRuntimeFeature);
	}

	return 0;
}

static void updateHeapOffset(short newOffset)
{
	if (newOffset != heapOffset) {
		genTwo(LDA_ZEROPAGE, ZP_PTR1L);
		genOne(CLC);
		genTwo(ADC_IMMEDIATE, WORD_LOW(newOffset - heapOffset));
		genTwo(STA_ZEROPAGE, ZP_PTR1L);
		genTwo(LDA_ZEROPAGE, ZP_PTR1H);
		genTwo(ADC_IMMEDIATE, WORD_HIGH(newOffset - heapOffset));
		genTwo(STA_ZEROPAGE, ZP_PTR1H);

		heapOffset = newOffset;
	}
}

#ifdef COMPILERTEST
#if 0
static void copyChainCall(char* name)
{
	unsigned char* p = (unsigned char*)0xca00;

	chainCall[10] = strlen(name);
	memcpy(p, chainCall, 28);
	memcpy(p + 28, name, strlen(name));
}
#endif

static void writeChainCall(char* name)
{
	linkAddressSet("CHAINCALL", codeOffset);
	chainCall[10] = strlen(name);
	writeToMemBuf(codeBuf, chainCall, 28);
#if 0
	linkAddressLookup("CHAINNAME", codeOffset + 12, 0, LINKADDR_LOW);
	linkAddressLookup("CHAINNAME", codeOffset + 14, 0, LINKADDR_HIGH);
#endif
	codeOffset += 28;

#if 0
	linkAddressSet("CHAINNAME", codeOffset);
#endif
	writeToMemBuf(codeBuf, name, strlen(name));
	codeOffset += strlen(name);
}
#endif
