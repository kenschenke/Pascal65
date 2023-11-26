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
#include <int16.h>
#include <device.h>

#define RUNTIME_STACK_SIZE 2048

#define BOOTSTRAP_CODE		"BOOTSTRAP_CODE"
#define BSS_BOOTSTRAP_MSG	"BSS_BOOTSTRAP_MSG"

#ifdef COMPILERTEST
#ifdef __MEGA65__
static unsigned char chainCall[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 8,		// Offset 3: device
	LDY_IMMEDIATE, 0xff,
	JSR, 0xba, 0xff,		// SETLFS

	LDA_IMMEDIATE, 0,		// Offset 10: strlen(name)
	LDX_IMMEDIATE, 0x1c,	// Offset 12: lower str address
	LDY_IMMEDIATE, 0x7a,	// Offset 14: upper str address
	JSR, 0xbd, 0xff,		// SETNAM

	LDA_IMMEDIATE, 0,
	TAX,
	TAY,
	JSR, 0xd5, 0xff,		// LOAD

	JMP, 0x11, 0x20,
};
#elif defined(__C64__)
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
#else
#error chainCall not defined for this platform
#endif
#endif  // end of COMPILERTEST

#ifdef COMPILERTEST
static void writeChainCall(char* name);
#endif

#ifdef __MEGA65__
#define PRG_HEADER_CODE_OFFSET_1 5
#define PRG_HEADER_CODE_OFFSET_2 53
#define PRG_HEADER_CODE_OFFSET_3 55
#define PRG_HEADER_CODE_OFFSET_4 78
#define PRG_HEADER_CODE_OFFSET_5 82
#define PRG_HEADER_CODE_EXIT_HANDLER_L 19
#define PRG_HEADER_CODE_EXIT_HANDLER_H 23
#define PRG_HEADER_LENGTH 85
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

	// Set the exit handler
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_EXITHANDLER,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_EXITHANDLER + 1,

	// Initialize runtime stack
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_SPL,
	STA_ZEROPAGE, ZP_STACKFRAMEL,
	LDA_IMMEDIATE, 0xc0,		// Runtime stack at $C000
	STA_ZEROPAGE, ZP_SPH,		// (grows downward)
	STA_ZEROPAGE, ZP_STACKFRAMEH,

	// Set the runtime stack size and initialize the stack
	LDA_IMMEDIATE, WORD_LOW(RUNTIME_STACK_SIZE),
	LDX_IMMEDIATE, WORD_HIGH(RUNTIME_STACK_SIZE),
	JSR, WORD_LOW(RT_STACKINIT), WORD_HIGH(RT_STACKINIT),

	LDA_IMMEDIATE, WORD_LOW(0xc000 - RUNTIME_STACK_SIZE - 4),
	LDX_IMMEDIATE, WORD_HIGH(0xc000 - RUNTIME_STACK_SIZE - 4),
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
#elif defined(__C64__)
#define PRG_HEADER_CODE_OFFSET_1 5
#define PRG_HEADER_CODE_OFFSET_2 53
#define PRG_HEADER_CODE_OFFSET_3 55
#define PRG_HEADER_CODE_OFFSET_4 78
#define PRG_HEADER_CODE_OFFSET_5 82
#define PRG_HEADER_CODE_EXIT_HANDLER_L 19
#define PRG_HEADER_CODE_EXIT_HANDLER_H 23
#define PRG_HEADER_LENGTH 85
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

	// Set the exit handler
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_EXITHANDLER,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_EXITHANDLER + 1,

	// Initialize runtime stack
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_SPL,
	STA_ZEROPAGE, ZP_STACKFRAMEL,
	LDA_IMMEDIATE, 0xd0,			// Runtime stack at $D000
	STA_ZEROPAGE, ZP_SPH,			// (grows downward)
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
#else
#error Program header and footer not defined for this platform
#endif

#define PRG_CLEANUP_OFFSET 12
#define PRG_CLEANUP_LENGTH 21
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
#ifdef __MEGA65__
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
	LDA_IMMEDIATE, 0x7a,
	STA_ZEROPAGE, ZP_PTR1H,
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_MEMCOPY), WORD_HIGH(RT_MEMCOPY),
	JMP, 0, 0x7a,
};
#elif defined (__C64__)
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
#else
#error chainCode not defined for this platform
#endif
#endif  // end of COMPILERTEST

static void dumpStringLiterals(void);
static void freeStringLiterals(void);
#ifndef COMPILERTEST
static void genBootstrap(void);
#endif
static void genExeHeader(void);
static void genRuntime(void);
static void updateLinkerAddresses(CHUNKNUM codeBuf);

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
		strcpy(label, "strVal");
		strcat(label, formatInt16(num));
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

#ifndef COMPILERTEST
static void genBootstrap(void)
{
#ifdef __MEGA65__
	// Flush the keyboard buffer
	genTwo(LDA_IMMEDIATE, 0);
	genThreeAddr(LDX_ABSOLUTE, 0xd610);
	genTwo(BEQ, 5);
	genThreeAddr(STA_ABSOLUTE, 0xd610);
	genTwo(BNE, 0xf6);
#endif
	// Display a message to press a key
	linkAddressLookup(BSS_BOOTSTRAP_MSG, codeOffset + 1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(BSS_BOOTSTRAP_MSG, codeOffset + 1, 0, LINKADDR_HIGH);
	genTwo(LDX_IMMEDIATE, 0);
	genThreeAddr(JSR, RT_PRINTZ);
	// Wait for a key to get pressed
#ifdef __MEGA65__
	genThreeAddr(LDX_ABSOLUTE, 0xd610);
	genTwo(BEQ, 0xfb);
	genTwo(LDA_IMMEDIATE, 0);
	genThreeAddr(STA_ABSOLUTE, 0xd610);
	genOne(TXA);
#else
	genThreeAddr(JSR, 0xffe4);		// GETIN
	genTwo(CMP_IMMEDIATE, 0);
	genTwo(BEQ, 0xfa);
#endif
	// Copy bootstrap code to upper memory
	linkAddressLookup(BOOTSTRAP_CODE, codeOffset + 1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	genTwo(STA_ZEROPAGE, ZP_PTR1L);
	linkAddressLookup(BOOTSTRAP_CODE, codeOffset + 1, 0, LINKADDR_HIGH);
	genTwo(LDA_IMMEDIATE, 0);
	genTwo(STA_ZEROPAGE, ZP_PTR1H);
	genTwo(LDA_IMMEDIATE, 0xd0);
	genTwo(STA_ZEROPAGE, ZP_PTR2L);
	genTwo(LDA_IMMEDIATE, 0x8f);
	genTwo(STA_ZEROPAGE, ZP_PTR2H);
	genTwo(LDY_IMMEDIATE, 44);
	genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
	genTwo(STA_ZPINDIRECT, ZP_PTR2L);
	genOne(DEY);
	genTwo(BPL, 0xf9);
	genThreeAddr(JMP, 0x8fd0);
	linkAddressSet(BOOTSTRAP_CODE, codeOffset);
	genTwo(LDA_IMMEDIATE, 0);
	genTwo(LDX_ZEROPAGE, 0xba); // current device number
	genTwo(LDY_IMMEDIATE, 0xff);
	genThreeAddr(JSR, 0xffba);	// SETLFS
	genTwo(LDA_IMMEDIATE, 8);	// "pascal65" length
	genTwo(LDX_IMMEDIATE, 0xec);
	genTwo(LDY_IMMEDIATE, 0x8f);
	genThreeAddr(JSR, 0xffbd);	// SETNAM
	genTwo(LDA_IMMEDIATE, 0);
	genOne(TAX);
	genOne(TAY);
	genThreeAddr(JSR, 0xffd5);	// LOAD
#ifdef __MEGA65__
	genThreeAddr(JMP, 0x2011);
#else
	genThreeAddr(JMP, 0x80d);
#endif
	writeCodeBuf((unsigned char *)"pascal65", 8);
}
#endif

static void genExeHeader(void)
{
	char startAddr[5], buf[2];

#ifdef __MEGA65__
	// Link to next line
	buf[0] = WORD_LOW(codeBase + 14);
	buf[1] = WORD_HIGH(codeBase + 14);
	writeToMemBuf(codeBuf, buf, 2);

	// Line number
	buf[0] = 10;
	buf[1] = 0;
	writeToMemBuf(codeBuf, buf, 2);

	// BANK token
	buf[0] = 0xfe;
	buf[1] = 0x02;
	writeToMemBuf(codeBuf, buf, 2);

	// BANK argument
	buf[0] = '0';
	buf[1] = ':';
	writeToMemBuf(codeBuf, buf, 2);

	// SYS token
	buf[0] = 0x9e;  // SYS
	writeToMemBuf(codeBuf, buf, 1);

	// Starting address of code
	strcpy(startAddr, formatInt16(codeBase + 16));
	writeToMemBuf(codeBuf, startAddr, strlen(startAddr));

	// End of BASIC line
	buf[0] = 0;
	writeToMemBuf(codeBuf, buf, 1);

	// End of BASIC program marker
	buf[1] = 0;
	writeToMemBuf(codeBuf, buf, 2);

	codeOffset = 16;
#elif defined(__C64__)
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
	strcpy(startAddr, formatInt16(codeBase + 12));
	writeToMemBuf(codeBuf, startAddr, strlen(startAddr));

	// End of BASIC line
	buf[0] = 0;
	writeToMemBuf(codeBuf, buf, 1);

	// End of BASIC program marker
	writeToMemBuf(codeBuf, buf, 2);

	codeOffset = 12;
#else
#error Platform Exe header not defined
#endif
}

void linkerPreWrite(void)
{
#ifdef __MEGA65__
	codeBase = 0x2001;
#elif defined(__C64__)
	codeBase = 0x801;
#else
#error Platform start address not defined
#endif
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
	linkAddressLookup("EXIT_HANDLER", codeOffset + PRG_HEADER_CODE_EXIT_HANDLER_L, 0, LINKADDR_LOW);
	linkAddressLookup("EXIT_HANDLER", codeOffset + PRG_HEADER_CODE_EXIT_HANDLER_H, 0, LINKADDR_HIGH);
	writeCodeBuf(prgHeader, PRG_HEADER_LENGTH);
}

void runPrg(void);

#ifdef COMPILERTEST
void linkerPostWrite(const char*filename, char* nextTest)
#else
void linkerPostWrite(const char* filename, char run)
#endif
{
	FILE* out;
	char ch, prgFilename[16 + 1];
	int i;

	linkAddressSet("EXIT_HANDLER", codeOffset);
	linkAddressLookup(BSS_ZPBACKUP, codeOffset + PRG_CLEANUP_OFFSET, 0, LINKADDR_BOTH);
	writeCodeBuf(prgCleanup, PRG_CLEANUP_LENGTH);

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

		strcpy(msg, "Loading ");
		strcat(msg, nextTest);
		linkAddressSet("CHAINMSG", codeOffset);
		writeToMemBuf(codeBuf, msg, strlen(msg) + 1);
		codeOffset += strlen(msg) + 1;
	} else {
		genTwo(LDA_IMMEDIATE, 0);
		genOne(RTS);
	}
#else
	// Return to the OS
	if (run) {
		genBootstrap();
	} else {
		genTwo(LDA_IMMEDIATE, 0);
		genOne(RTS);
	}
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

#ifndef COMPILERTEST
	if (run) {
		linkAddressSet(BSS_BOOTSTRAP_MSG, codeOffset);
		writeCodeBuf((unsigned char *)"\nPress a key...", 16);
	}
#endif

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

    // Generate PRG filename
#ifndef COMPILERTEST
	if (run) {
		strcpy(prgFilename, "zzprg");
	} else
#endif
	{
		strcpy(prgFilename, filename);
#ifndef COMPILERTEST
		if (!stricmp(prgFilename+strlen(prgFilename)-4, ".pas")) {
			// If the source filename ends in ".pas",
			// drop the extension and use that for the PRG filename.
			prgFilename[strlen(prgFilename)-4] = 0;
		} else {
			if (strlen(filename) > 12) {
				// The source filename is more than 12 characters,
				// so use the first 12 chars and add ".prg".
				strcpy(prgFilename+12, ".prg");
			} else {
				strcat(prgFilename, ".prg");
			}
		}
#endif
	}

	_filetype = 'p';
	out = fopen(prgFilename, "w");
	ch = 1;
	fwrite(&ch, 1, 1, out);
#ifdef __MEGA65__
	ch = 0x20;	// 0x2001
#elif defined(__C64__)
	ch = 8;		// 0x801
#else
#error Platform starting address not defined
#endif
	fwrite(&ch, 1, 1, out);

	setMemBufPos(codeBuf, 0);
	while (!isMemBufAtEnd(codeBuf)) {
		readFromMemBuf(codeBuf, &ch, 1);
		fwrite(&ch, 1, 1, out);
	}

	fclose(out);
	freeMemBuf(codeBuf);
	freeStringLiterals();

#ifndef COMPILERTEST
	if (run) {
		runPrg();
	}
#endif
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

static void updateLinkerAddresses(CHUNKNUM codeBuf)
{
	struct LINKSYMBOL sym;
	struct LINKTAG tag;

	setMemBufPos(linkerTags, 0);
	while (!isMemBufAtEnd(linkerTags)) {
		readFromMemBuf(linkerTags, &tag, sizeof(struct LINKTAG));
		retrieveChunk(tag.chunkNum, &sym);
		setMemBufPos(codeBuf, tag.position);
		if (tag.which == LINKADDR_LOW) {
			unsigned char c = WORD_LOW(sym.address);
			writeToMemBuf(codeBuf, &c, 1);
		}
		else if (tag.which == LINKADDR_HIGH) {
			unsigned char c = WORD_HIGH(sym.address);
			writeToMemBuf(codeBuf, &c, 1);
		}
		else if (tag.which == LINKADDR_BOTH) {
			writeToMemBuf(codeBuf, &sym.address, sizeof(sym.address));
		}
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
