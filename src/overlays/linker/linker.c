// This generates code for the executable:
//    Sets up and tears down the runtime
//    The BASIC exe header
//    Resolves memory addresses not known until all code is generated
//    Adds the runtime to the executable
//    Global Pascal variable declarations
//    Initialize the executable's global memory heap
//
// NOTE: Pascal code is generated elsewhere, in the objcode overlay.

#include <stdio.h>
#include <cbm.h>
#include <buffer.h>
#include <codegen.h>
#include <ast.h>
#include <asm.h>
#include <membuf.h>
#include <string.h>

#define RUNTIME_STACK_SIZE 2048

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

#ifdef COMPILERTEST
// static void copyChainCall(char* name);
static void writeChainCall(char* name);
#endif

#define PRG_HEADER_CODE_OFFSET_1 5
#define PRG_HEADER_CODE_OFFSET_2 45
#define PRG_HEADER_CODE_OFFSET_3 47
#define PRG_HEADER_CODE_OFFSET_4 70
#define PRG_HEADER_CODE_OFFSET_5 74
static unsigned char prgHeader[] = {
	// Make a backup copy of page zero
	LDX_IMMEDIATE, 0,
	LDA_X_INDEXED_ZP, 0x02,
	STA_ABSOLUTEX, 0, 0,  // PRG_HEADER_CODE_OFFSET_1
	INX,
	CPX_IMMEDIATE, 0x1b,
	BNE, 0xf6,

	// Save the stack pointer
	TSX,
	STX_ZEROPAGE, ZP_SAVEDSTACK,

	JSR, WORD_LOW(RT_ERRORINIT), WORD_HIGH(RT_ERRORINIT),

	// Initialize runtime stack
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_SPL,
	STA_ZEROPAGE, ZP_STACKFRAMEL,
	LDA_IMMEDIATE, 0xd0,
	STA_ZEROPAGE, ZP_SPH,
	STA_ZEROPAGE, ZP_STACKFRAMEH,

	// Set the runtime stack size and initialize the stack
	LDA_IMMEDIATE, WORD_LOW(RUNTIME_STACK_SIZE),
	LDX_IMMEDIATE, WORD_HIGH(RUNTIME_STACK_SIZE),
	JSR, WORD_LOW(RT_STACKINIT), WORD_HIGH(RT_STACKINIT),

	LDA_IMMEDIATE, WORD_LOW(0xd000 - RUNTIME_STACK_SIZE - 4),
	LDX_IMMEDIATE, WORD_HIGH(0xd000 - RUNTIME_STACK_SIZE - 4),
	JSR, WORD_LOW(RT_PUSHAX), WORD_HIGH(RT_PUSHAX),
	LDA_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_2
	LDX_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_3
	JSR, WORD_LOW(RT_HEAPINIT), WORD_HIGH(RT_HEAPINIT),

	// Current nesting level
	LDA_IMMEDIATE, 1,
	STA_ZEROPAGE, ZP_NESTINGLEVEL,

	// Switch to upper/lower case character set
	LDA_IMMEDIATE, 0x0e,
	JSR, WORD_LOW(CHROUT), WORD_HIGH(CHROUT),

	// Disable BASIC ROM
	LDA_ZEROPAGE, 1,
	AND_IMMEDIATE, 0xfe,
	STA_ZEROPAGE, 1,

	// Clear the input buffer
	JSR, WORD_LOW(RT_CLRINPUT), WORD_HIGH(RT_CLRINPUT),

	// Initialize the int buffer
	LDA_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_4
	STA_ZEROPAGE, ZP_INTPTR,
	LDA_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_5
	STA_ZEROPAGE, ZP_INTPTR + 1,
};

#define PRG_CLEANUP_OFFSET 12
static unsigned char prgCleanup[] = {
	// Clean up the program's stack frame
	JSR, WORD_LOW(RT_STACKCLEANUP), WORD_HIGH(RT_STACKCLEANUP),

	// Re-enable BASIC ROM
	LDA_ZEROPAGE, 1,
	ORA_IMMEDIATE, 1,
	STA_ZEROPAGE, 1,

	// Copy the backup of page zero back
	LDX_IMMEDIATE, 0,
	LDA_ABSOLUTEX, 0, 0,
	STA_X_INDEXED_ZP, 0x02,
	INX,
	CPX_IMMEDIATE, 0x1b,
	BNE, 0xf6,
};

#ifdef COMPILERTEST
#define CHAIN_CODE_MSGL 1
#define CHAIN_CODE_MSGH 3
#define CHAIN_CODE_CALLL 8
#define CHAIN_CODE_CALLH 12
#define CHAIN_CODE_STRLEN 24
static unsigned char chainCode[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_PRINTZ), WORD_HIGH(RT_PRINTZ),

	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR2L,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR2H,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1L,
	LDA_IMMEDIATE, 0xca,
	STA_ZEROPAGE, ZP_PTR1H,
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_MEMCOPY), WORD_HIGH(RT_MEMCOPY),
	JMP, 0, 0xca,
};
#endif

static void dumpStringLiterals(void);
static void freeStringLiterals(void);
static void genExeHeader(void);
static void genRuntime(void);

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

void linkerPreWrite(void)
{
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

	linkAddressLookup(BSS_ZPBACKUP, codeOffset + PRG_HEADER_CODE_OFFSET_1, 0, LINKADDR_BOTH);
	linkAddressLookup(BSS_HEAPBOTTOM, codeOffset + PRG_HEADER_CODE_OFFSET_2, 0, LINKADDR_LOW);
	linkAddressLookup(BSS_HEAPBOTTOM, codeOffset + PRG_HEADER_CODE_OFFSET_3, 0, LINKADDR_HIGH);
	linkAddressLookup(BSS_INTBUF, codeOffset + PRG_HEADER_CODE_OFFSET_4, 0, LINKADDR_LOW);
	linkAddressLookup(BSS_INTBUF, codeOffset + PRG_HEADER_CODE_OFFSET_5, 0, LINKADDR_HIGH);
	writeCodeBuf(prgHeader, 77);
}

#ifdef COMPILERTEST
void linkerPostWrite(const char*prgFilename, char* nextTest)
#else
void linkerPostWrite(const char* prgFilename)
#endif
{
	FILE* out;
	char ch;
	int i;

	linkAddressLookup(BSS_ZPBACKUP, codeOffset + PRG_CLEANUP_OFFSET, 0, LINKADDR_BOTH);
	writeCodeBuf(prgCleanup, 21);

#ifdef COMPILERTEST
	if (nextTest) {
		char msg[40];

		linkAddressLookup("CHAINMSG", codeOffset + CHAIN_CODE_MSGL, 0, LINKADDR_LOW);
		linkAddressLookup("CHAINMSG", codeOffset + CHAIN_CODE_MSGH, 0, LINKADDR_HIGH);
		linkAddressLookup("CHAINCALL", codeOffset + CHAIN_CODE_CALLL, 0, LINKADDR_LOW);
		linkAddressLookup("CHAINCALL", codeOffset + CHAIN_CODE_CALLH, 0, LINKADDR_HIGH);
		chainCode[CHAIN_CODE_STRLEN] = 28 + strlen(nextTest);
		writeCodeBuf(chainCode, 33);
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

#ifdef COMPILERTEST
static void writeChainCall(char* name)
{
	linkAddressSet("CHAINCALL", codeOffset);
	chainCall[10] = strlen(name);
	writeToMemBuf(codeBuf, chainCall, 28);
	codeOffset += 28;

	writeToMemBuf(codeBuf, name, strlen(name));
	codeOffset += strlen(name);
}
#endif
