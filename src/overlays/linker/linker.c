/**
 * linker.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

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
#include <buffer.h>
#include <codegen.h>
#include <ast.h>
#include <asm.h>
#include <membuf.h>
#include <string.h>
#include <int16.h>
#include <inputbuf.h>
#include <doscmd.h>

#ifndef __GNUC__
#include <cbm.h>
#include <device.h>
#endif

#define BUFLEN 20
#define TEMP_PROG "zztmp"

#ifdef __MEGA65__
#include <memory.h>
#endif

#ifdef __GNUC__
#define stricmp strcasecmp
#endif

#define RUNTIME_STACK_SIZE 2048

#define BOOTSTRAP_CODE		"BOOTSTRAP_CODE"
#define BSS_BOOTSTRAP_MSG	"BSS_BOOTSTRAP_MSG"

#ifdef COMPILERTEST

#ifdef __MEGA65__
#define CODESEG_CEIL 0x9000
#else
#define CODESEG_CEIL 0xca00
#endif

#else

#ifdef __MEGA65__
#define CODESEG_CEIL (0xc000-RUNTIME_STACK_SIZE)
#else
#define CODESEG_CEIL (0xd000-RUNTIME_STACK_SIZE)
#endif

#endif

#ifdef COMPILERTEST
#ifdef __MEGA65__
static unsigned char chainCall[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 8,		// Offset 3: device
	LDY_IMMEDIATE, 0xff,
	JSR, 0xba, 0xff,		// SETLFS

	LDA_IMMEDIATE, 0,		// Offset 10: strlen(name)
	LDX_IMMEDIATE, 0x1c,	// Offset 12: lower str address
	LDY_IMMEDIATE, 0x90,	// Offset 14: upper str address
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
#define PRG_HEADER_CODE_OFFSET_1 13
#define PRG_HEADER_CODE_OFFSET_2 62
#define PRG_HEADER_CODE_OFFSET_3 64
#define PRG_HEADER_CODE_OFFSET_4 89
#define PRG_HEADER_CODE_OFFSET_5 93
#define PRG_HEADER_CODE_OFFSET_6 97
#define PRG_HEADER_CODE_OFFSET_7 99
#define PRG_HEADER_CODE_OFFSET_9 78
#define PRG_HEADER_CODE_OFFSET_10 82
#define PRG_HEADER_CODE_EXIT_HANDLER_L 27
#define PRG_HEADER_CODE_EXIT_HANDLER_H 31
#define PRG_HEADER_LENGTH 109
static unsigned char prgHeader[] = {
	// Disable BASIC ROM
	LDA_ZEROPAGE, 1,
	AND_IMMEDIATE, 0xf8,
	ORA_IMMEDIATE, 0x06,
	STA_ZEROPAGE, 1,

	// Make a backup copy of page zero
	LDX_IMMEDIATE, 0,
	LDA_X_INDEXED_ZP, 0x04,
	STA_ABSOLUTEX, 0, 0,  // PRG_HEADER_CODE_OFFSET_1
	INX,
	CPX_IMMEDIATE, 0x5d,
	BNE, 0xf6,

	// Save the stack pointer
	TSX,
	STX_ZEROPAGE, ZP_SAVEDSTACK,

	JSR, WORD_LOW(RT_RUNTIMEERRORINIT), WORD_HIGH(RT_RUNTIMEERRORINIT),

	// Set the exit handler
	LDA_IMMEDIATE, 0,	// PRG_HEADER_CODE_EXIT_HANDLER_L
	STA_ZEROPAGE, ZP_EXITHANDLER,
	LDA_IMMEDIATE, 0,	// PRG_HEADER_CODE_EXIT_HANDLER_H
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
	STA_ZEROPAGE, ZP_PTR1L,
	LDA_IMMEDIATE, WORD_HIGH(0xc000 - RUNTIME_STACK_SIZE - 4),
	STA_ZEROPAGE, ZP_PTR1H,
	LDA_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_2
	LDX_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_3
	JSR, WORD_LOW(RT_HEAPINIT), WORD_HIGH(RT_HEAPINIT),

	// Current nesting level
	LDA_IMMEDIATE, 1,
	STA_ZEROPAGE, ZP_NESTINGLEVEL,

	// Switch to upper/lower case character set
	LDA_IMMEDIATE, 0x0e,
	JSR, WORD_LOW(CHROUT), WORD_HIGH(CHROUT),

	// Set the input buffer pointer
	// PRG_HEADER_CODE_OFFSET_9
	LDA_IMMEDIATE, 0,	// BSS_INPUTBUF low
	STA_ZEROPAGE, ZP_INPUTBUFPTRL,
	// PRG_HEADER_CODE_OFFSET_10
	LDA_IMMEDIATE, 0,	// BSS_INPUTBUF high
	STA_ZEROPAGE, ZP_INPUTBUFPTRH,

	// Clear the input buffer
	JSR, WORD_LOW(RT_CLEARINPUTBUF), WORD_HIGH(RT_CLEARINPUTBUF),

	// Initialize the int buffer
	LDA_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_4
	STA_ZEROPAGE, ZP_INTPTR,
	LDA_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_5
	STA_ZEROPAGE, ZP_INTPTR + 1,

	// Initialize integer/ascii table
	// PRG_HEADER_CODE_OFFSET_6
	LDA_IMMEDIATE, 0,	// BSS_TENSTABLE low
	// PRG_HEADER_CODE_OFFSET_7
	LDX_IMMEDIATE, 0,	// BSS_TENSTABLE high
	JSR, WORD_LOW(RT_INITTENSTABLE32), WORD_HIGH(RT_INITTENSTABLE32),

	// Initialize file i/o
	JSR, WORD_LOW(RT_INITFILEIO), WORD_HIGH(RT_INITFILEIO),

	// Clear the keyboard buffer
	JSR, WORD_LOW(RT_CLEARKEYBUF), WORD_HIGH(RT_CLEARKEYBUF),
};
#elif defined(__C64__)
#define PRG_HEADER_CODE_OFFSET_1 5
#define PRG_HEADER_CODE_OFFSET_2 54
#define PRG_HEADER_CODE_OFFSET_3 56
#define PRG_HEADER_CODE_OFFSET_4 87
#define PRG_HEADER_CODE_OFFSET_5 91
#define PRG_HEADER_CODE_OFFSET_6 95
#define PRG_HEADER_CODE_OFFSET_7 97
#define PRG_HEADER_CODE_OFFSET_9 76
#define PRG_HEADER_CODE_OFFSET_10 80
#define PRG_HEADER_CODE_OFFSET_14 16
#define PRG_HEADER_CODE_EXIT_HANDLER_L 19
#define PRG_HEADER_CODE_EXIT_HANDLER_H 23
#define PRG_HEADER_LENGTH 107
static unsigned char prgHeader[] = {
	// Make a backup copy of page zero
	LDX_IMMEDIATE, 0,
	LDA_X_INDEXED_ZP, 0x02,
	STA_ABSOLUTEX, 0, 0,  // PRG_HEADER_CODE_OFFSET_1
	INX,
	CPX_IMMEDIATE, 0x62,
	BNE, 0xf6,

	// Save the stack pointer
	TSX,
	STX_ZEROPAGE, ZP_SAVEDSTACK,

	JSR, WORD_LOW(RT_RUNTIMEERRORINIT), WORD_HIGH(RT_RUNTIMEERRORINIT),

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
	STA_ZEROPAGE, PTR1L,
	LDA_IMMEDIATE, WORD_HIGH(0xd000 - RUNTIME_STACK_SIZE - 4),
	STA_ZEROPAGE, PTR1H,
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

	// Set the input buffer pointer
	// PRG_HEADER_CODE_OFFSET_9
	LDA_IMMEDIATE, 0,	// BSS_INPUTBUF low
	STA_ZEROPAGE, ZP_INPUTBUFPTRL,
	// PRG_HEADER_CODE_OFFSET_10
	LDA_IMMEDIATE, 0,	// BSS_INPUTBUF high
	STA_ZEROPAGE, ZP_INPUTBUFPTRH,

	// Clear the input buffer
	JSR, WORD_LOW(RT_CLEARINPUTBUF), WORD_HIGH(RT_CLEARINPUTBUF),

	// Initialize the int buffer
	LDA_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_4
	STA_ZEROPAGE, ZP_INTPTR,
	LDA_IMMEDIATE, 0,  // PRG_HEADER_CODE_OFFSET_5
	STA_ZEROPAGE, ZP_INTPTR + 1,

	// Initialize integer/ascii table
	// PRG_HEADER_CODE_OFFSET_6
	LDA_IMMEDIATE, 0,	// BSS_TENSTABLE low
	// PRG_HEADER_CODE_OFFSET_7
	LDX_IMMEDIATE, 0,	// BSS_TENSTABLE high
	JSR, WORD_LOW(RT_INITTENSTABLE32), WORD_HIGH(RT_INITTENSTABLE32),

	// Initialize file i/o
	JSR, WORD_LOW(RT_INITFILEIO), WORD_HIGH(RT_INITFILEIO),

	// Clear the keyboard buffer
	JSR, WORD_LOW(RT_CLEARKEYBUF), WORD_HIGH(RT_CLEARKEYBUF),
};
#else
#error Program header and footer not defined for this platform
#endif

#define PRG_CLEANUP_OFFSET 15
#define PRG_CLEANUP_LENGTH 24
static unsigned char prgCleanup[] = {
	// Clean up the program's stack frame
	JSR, WORD_LOW(RT_STACKCLEANUP), WORD_HIGH(RT_STACKCLEANUP),

	// Re-enable BASIC ROM
	LDA_ZEROPAGE, 1,
	ORA_IMMEDIATE, 1,
	STA_ZEROPAGE, 1,

	// Close all open files and clear I/O channels
	JSR, 0xe7, 0xff,  // CLALL

	// Copy the backup of page zero back
	LDX_IMMEDIATE, 0,
	LDA_ABSOLUTEX, 0, 0,
	STA_X_INDEXED_ZP, 0x04,
	INX,
	CPX_IMMEDIATE, 0x62,
	BNE, 0xf6,
};

#ifdef COMPILERTEST
#define CHAIN_CODE_MSGL 8
#define CHAIN_CODE_MSGH 10
#define CHAIN_CODE_CALLL 15
#define CHAIN_CODE_CALLH 19
#define CHAIN_CODE_STRLEN 31
#define CHAIN_CODE_LEN 40
#ifdef __MEGA65__
static unsigned char chainCode[] = {
	LDA_IMMEDIATE, FH_STDIO,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_SETFH), WORD_HIGH(RT_SETFH),
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_PRINTZ), WORD_HIGH(RT_PRINTZ),
	// 0, 0, 0,

	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR2L,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR2H,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1L,
	LDA_IMMEDIATE, 0x90,
	STA_ZEROPAGE, ZP_PTR1H,
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_MEMCOPY), WORD_HIGH(RT_MEMCOPY),
	JMP, 0, 0x90,	// JMP to $9000
};
#elif defined (__C64__)
static unsigned char chainCode[] = {
	LDA_IMMEDIATE, FH_STDIO,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_SETFH), WORD_HIGH(RT_SETFH),
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, 0, 0,

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
	JSR, 0, 0,
	JMP, 0, 0xca,	// JMP to $ca00
};
#else
#error chainCode not defined for this platform
#endif
#endif  // end of COMPILERTEST

static void dumpArrayInits(void);
static void dumpStringLiterals(void);
static void freeArrayInits(void);
static void freeStringLiterals(void);
#ifndef COMPILERTEST
static void genBootstrap(void);
#endif
static void genExeHeader(void);
static void genRuntime(void);
static void writePrgFile(FILE *out);

static void dumpArrayInits(void)
{
	char label[20], areLiteralsReals, isNeg;
	CHUNKNUM arrayInits, literals, stringChunkNum, literalsBuf = 0;
	struct ARRAYINIT arrayInit;
	unsigned char arrayInitBuf[sizeof(struct ARRAYINIT)];

	if (!arrayInitsForAllScopes || !numArrayInitsForAllScopes) {
		return;
	}

	setMemBufPos(arrayInitsForAllScopes, 0);
	while (!isMemBufAtEnd(arrayInitsForAllScopes)) {
		readFromMemBuf(arrayInitsForAllScopes, &arrayInits, sizeof(CHUNKNUM));

		strcpy(label, "arrayInits");
		strcat(label, formatInt16(arrayInits));
		linkAddressSet(label, codeOffset);

		setMemBufPos(arrayInits, 0);
		while (!isMemBufAtEnd(arrayInits)) {
			readFromMemBuf(arrayInits, arrayInitBuf, sizeof(struct ARRAYINIT));
			memcpy(&arrayInit, arrayInitBuf, sizeof(struct ARRAYINIT));

			if (arrayInit.literals) {
				if (!literalsBuf) {
					allocMemBuf(&literalsBuf);
				}
				writeToMemBuf(literalsBuf, &arrayInit.literals, sizeof(CHUNKNUM));
				writeToMemBuf(literalsBuf, &arrayInit.areLiteralsReals, 1);

				strcpy(label, "arrayLits");
				strcat(label, formatInt16(arrayInit.literals));
				linkAddressLookup(label, codeOffset+10, LINKADDR_BOTH);
			}

			writeCodeBuf(arrayInitBuf, sizeof(struct ARRAYINIT));
		}

		arrayInitBuf[0] = arrayInitBuf[1] = 0;
		writeCodeBuf(arrayInitBuf, 2);
	}

	if (!literalsBuf) {
		return;
	}

	setMemBufPos(literalsBuf, 0);
	while (!isMemBufAtEnd(literalsBuf)) {
		readFromMemBuf(literalsBuf, &literals, sizeof(CHUNKNUM));
		readFromMemBuf(literalsBuf, &areLiteralsReals, 1);

		strcpy(label, "arrayLits");
		strcat(label, formatInt16(literals));
		linkAddressSet(label, codeOffset);

		setMemBufPos(literals, 0);
		if (areLiteralsReals) {
			while (!isMemBufAtEnd(literals)) {
				readFromMemBuf(literals, &isNeg, 1);
				readFromMemBuf(literals, &stringChunkNum, sizeof(CHUNKNUM));

				writeCodeBuf((unsigned char *)&isNeg, 1);
				setMemBufPos(stringChunkNum, 0);
				while (!isMemBufAtEnd(stringChunkNum)) {
					readFromMemBuf(stringChunkNum, label, 1);
					writeCodeBuf((unsigned char *)label, 1);
				}
				label[0] = 0;
				writeCodeBuf((unsigned char *)label, 1);
			}
		} else {
			while (!isMemBufAtEnd(literals)) {
				readFromMemBuf(literals, arrayInitBuf, 1);
				writeCodeBuf(arrayInitBuf, 1);
			}
		}
	}

	freeMemBuf(literalsBuf);
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
		while (!isMemBufAtEnd(chunkNum) && pos < sizeof(value)-1) {
			readFromMemBuf(chunkNum, value + pos, 1);
			++pos;
		}
		value[pos] = 0;
		strcpy(label, "strVal");
		strcat(label, formatInt16(num));
		linkAddressSet(label, codeOffset);
		fwrite(value, 1, strlen(value) + 1, codeFh);
		codeOffset += (short)strlen(value) + 1;

		++num;
	}
}

static void freeArrayInits(void)
{
	CHUNKNUM arrayInits;
	struct ARRAYINIT arrayInit;

	if (arrayInitsForAllScopes || numArrayInitsForAllScopes) {
		setMemBufPos(arrayInitsForAllScopes, 0);

		while (!isMemBufAtEnd(arrayInitsForAllScopes)) {
			readFromMemBuf(arrayInitsForAllScopes, &arrayInits, sizeof(CHUNKNUM));

			setMemBufPos(arrayInits, 0);
			while (!isMemBufAtEnd(arrayInits)) {
				readFromMemBuf(arrayInits, &arrayInit, sizeof(struct ARRAYINIT));
				if (arrayInit.literals) {
					freeMemBuf(arrayInit.literals);
				}
			}

			freeMemBuf(arrayInits);
		}

		freeMemBuf(arrayInitsForAllScopes);
	}

	arrayInitsForAllScopes = 0;
	numArrayInitsForAllScopes = 0;
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
	linkAddressLookup(BSS_BOOTSTRAP_MSG, codeOffset + 1, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(BSS_BOOTSTRAP_MSG, codeOffset + 1, LINKADDR_HIGH);
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
	linkAddressLookup(BOOTSTRAP_CODE, codeOffset + 1, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	genTwo(STA_ZEROPAGE, ZP_PTR1L);
	linkAddressLookup(BOOTSTRAP_CODE, codeOffset + 1, LINKADDR_HIGH);
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
	fwrite(buf, 1, 2, codeFh);

	// Line number
	buf[0] = 10;
	buf[1] = 0;
	fwrite(buf, 1, 2, codeFh);

	// BANK token
	buf[0] = 0xfe;
	buf[1] = 0x02;
	fwrite(buf, 1, 2, codeFh);

	// BANK argument
	buf[0] = '0';
	buf[1] = ':';
	fwrite(buf, 1, 2, codeFh);

	// SYS token
	buf[0] = 0x9e;  // SYS
	fwrite(buf, 1, 1, codeFh);

	// Starting address of code
	strcpy(startAddr, formatInt16(codeBase + 16));
	fwrite(startAddr, 1, strlen(startAddr), codeFh);

	// End of BASIC line
	buf[0] = 0;
	fwrite(buf, 1, 1, codeFh);

	// End of BASIC program marker
	buf[1] = 0;
	fwrite(buf, 1, 2, codeFh);

	codeOffset = 16;
#elif defined(__C64__)
	// Link to next line
	buf[0] = WORD_LOW(codeBase + 10);
	buf[1] = WORD_HIGH(codeBase + 10);
	fwrite(buf, 1, 2, codeFh);

	// Line number
	buf[0] = 10;
	buf[1] = 0;
	fwrite(buf, 1, 2, codeFh);

	// SYS token
	buf[0] = 0x9e;  // SYS
	fwrite(buf, 1, 1, codeFh);

	// Starting address of code
	strcpy(startAddr, formatInt16(codeBase + 12));
	fwrite(startAddr, 1, strlen(startAddr), codeFh);

	// End of BASIC line
	buf[0] = 0;
	fwrite(buf, 1, 1, codeFh);

	// End of BASIC program marker
	fwrite(buf, 1, 2, codeFh);

	codeOffset = 12;
#else
#error Platform Exe header not defined
#endif
}

void linkerPreWrite(CHUNKNUM astRoot)
{
	int i;
	unsigned char ch = 0xba;

#ifdef __MEGA65__
	codeBase = 0x2001;
#elif defined(__C64__)
	codeBase = 0x801;
#else
#error Platform start address not defined
#endif

#ifndef __GNUC__
	_filetype = 'p';
#endif

	codeFh = fopen(TEMP_PROG, "w");
	initLinkerSymbolTable();

	// Write the BASIC stub to start the program code
	// (this also initializes codeOffset)
	genExeHeader();

	linkAddressLookup("INIT", codeOffset + 1, LINKADDR_BOTH);
	genThreeAddr(JMP, 0);

#ifdef __MEGA65__
	// Dedicate 20 bytes for the Mega65 DMA command block
	for (i = 0; i < sizeof(struct dmagic_dmalist); ++i) {
		writeCodeBuf(&ch, 1);
	}
#endif

	genRuntime();
	loadLibraries(astRoot);

	linkAddressSet("INIT", codeOffset);

	linkAddressLookup(BSS_ZPBACKUP, codeOffset + PRG_HEADER_CODE_OFFSET_1, LINKADDR_BOTH);
	linkAddressLookup(BSS_HEAPBOTTOM, codeOffset + PRG_HEADER_CODE_OFFSET_2, LINKADDR_LOW);
	linkAddressLookup(BSS_HEAPBOTTOM, codeOffset + PRG_HEADER_CODE_OFFSET_3, LINKADDR_HIGH);
	linkAddressLookup(BSS_INTBUF, codeOffset + PRG_HEADER_CODE_OFFSET_4, LINKADDR_LOW);
	linkAddressLookup(BSS_INTBUF, codeOffset + PRG_HEADER_CODE_OFFSET_5, LINKADDR_HIGH);
	linkAddressLookup(BSS_TENSTABLE, codeOffset + PRG_HEADER_CODE_OFFSET_6, LINKADDR_LOW);
	linkAddressLookup(BSS_TENSTABLE, codeOffset + PRG_HEADER_CODE_OFFSET_7, LINKADDR_HIGH);
	linkAddressLookup(BSS_INPUTBUF, codeOffset + PRG_HEADER_CODE_OFFSET_9, LINKADDR_LOW);
	linkAddressLookup(BSS_INPUTBUF, codeOffset + PRG_HEADER_CODE_OFFSET_10, LINKADDR_HIGH);
	linkAddressLookup("EXIT_HANDLER", codeOffset + PRG_HEADER_CODE_EXIT_HANDLER_L, LINKADDR_LOW);
	linkAddressLookup("EXIT_HANDLER", codeOffset + PRG_HEADER_CODE_EXIT_HANDLER_H, LINKADDR_HIGH);
	writeCodeBuf(prgHeader, PRG_HEADER_LENGTH);
}

void runPrg(void);

#ifdef COMPILERTEST
void linkerPostWrite(const char*filename, char* nextTest, CHUNKNUM astRoot)
#else
void linkerPostWrite(const char* filename, char run, CHUNKNUM astRoot)
#endif
{
	FILE* out;
	char ch, prgFilename[16 + 1];
	int i;

	linkAddressSet("EXIT_HANDLER", codeOffset);
	linkAddressLookup(BSS_ZPBACKUP, codeOffset + PRG_CLEANUP_OFFSET, LINKADDR_BOTH);
	writeCodeBuf(prgCleanup, PRG_CLEANUP_LENGTH);

#ifdef COMPILERTEST
	if (nextTest) {
		char msg[40];

		linkAddressLookup("CHAINMSG", codeOffset + CHAIN_CODE_MSGL, LINKADDR_LOW);
		linkAddressLookup("CHAINMSG", codeOffset + CHAIN_CODE_MSGH, LINKADDR_HIGH);
		linkAddressLookup("CHAINCALL", codeOffset + CHAIN_CODE_CALLL, LINKADDR_LOW);
		linkAddressLookup("CHAINCALL", codeOffset + CHAIN_CODE_CALLH, LINKADDR_HIGH);
		chainCode[CHAIN_CODE_STRLEN] = 28 + strlen(nextTest);
		writeCodeBuf(chainCode, CHAIN_CODE_LEN);
		writeChainCall(nextTest);	// filename of the next test in the chain

		strcpy(msg, "Loading ");
		strcat(msg, nextTest);
		strcat(msg, " ");
		linkAddressSet("CHAINMSG", codeOffset);
		fwrite(msg, 1, strlen(msg)+1, codeFh);
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
	dumpArrayInits();

	linkAddressSet(BSS_INTBUF, codeOffset);
	ch = 0;
	for (i = 0; i < 15; ++i) {
		fwrite(&ch, 1, 1, codeFh);
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
	for (i = 0; i < 97; ++i) {
		fwrite(&ch, 1, 1, codeFh);
		++codeOffset;
	}

	// Set aside memory for the integer/ascii table
	linkAddressSet(BSS_TENSTABLE, codeOffset);
	ch = 0;
	for (i = 0; i < 40; ++i) {
		fwrite(&ch, 1, 1, codeFh);
		++codeOffset;
	}

	// Set aside memory for the input buffer
	linkAddressSet(BSS_INPUTBUF, codeOffset);
	ch = 0;
	for (i = 0; i < INPUTBUFLEN; ++i) {
		fwrite(&ch, 1, 1, codeFh);
		++codeOffset;
	}

	// This MUST be the last thing written to the code buffer
#if 0
	printf("heap bottom = %04x\n", codeBase+codeOffset);
	printf("ceiling %04x\n", CODESEG_CEIL);
	printf("heap size %d\n", CODESEG_CEIL-codeBase-codeOffset);
#endif
	linkAddressSet(BSS_HEAPBOTTOM, codeOffset);
	ch = 0;
	fwrite(&ch, 1, 1, codeFh);
	fwrite(&ch, 1, 1, codeFh);

	// Check if the code segment overflows
	if (codeBase+codeOffset > CODESEG_CEIL) {
		abortTranslation(abortCodeSegmentOverflow);
	}

	decl_free(astRoot);

	sortLinkerTags();
	
	// Close the temporary program file and re-open it in read-only mode.
	fclose(codeFh);

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

	// See if the program file already exists
#ifndef __GNUC__
	_filetype = 'p';
#endif
	out = fopen(prgFilename, "r");
	if (out) {
		fclose(out);
#ifdef __MEGA65__
		removeFile(prgFilename);
#else
		remove(prgFilename);
#endif
	}

	codeFh = fopen(TEMP_PROG, "r");

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

	writePrgFile(out);

	fclose(out);
	freeStringLiterals();
	freeArrayInits();
	freeLinkerSymbolTable();

	fclose(codeFh);
	removeFile(TEMP_PROG);

#if !defined (COMPILERTEST) && !defined(__GNUC__)
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

#ifdef __GNUC__
	in = fopen("../../lib/runtime/bin/mega65/runtime", "rb");
#else
	in = fopen("runtime", "r");
#endif
	fread(buf, 1, 2, in);	// discard the starting address
	while (!feof(in)) {
		read = fread(buf, 1, sizeof(buf), in);
		if (read) {
			fwrite(buf, 1, read, codeFh);
			codeOffset += read;
		}
	}

	fclose(in);

	// Write an extra 200 bytes for BSS

	memset(buf, 0, sizeof(buf));
	for (i = 0; i < 20; ++i) {
		fwrite(buf, 1, sizeof(buf), codeFh);
		codeOffset += sizeof(buf);
	}
}

#ifdef COMPILERTEST
static void writeChainCall(char* name)
{
	linkAddressSet("CHAINCALL", codeOffset);
	chainCall[10] = strlen(name);
	fwrite(chainCall, 1, 28, codeFh);
	codeOffset += 28;

#ifdef __GNUC__
	// Convert the next program's filename to PETSCII
	char localname[20];
	strcpy(localname, name);
	for (char *p=localname; *p; p++) {
		*p -= 32;
	}
	fwrite(localname, 1, strlen(localname), codeFh);
#else
	fwrite(name, 1, strlen(name), codeFh);
#endif
	codeOffset += strlen(name);
}
#endif

static void writePrgFile(FILE *out)
{
	struct LINKTAG tag;
	struct LINKSYMBOL sym;
	int pos = 0, n, toGo = -1;  // toGo is -1 if no addresses to fix
	unsigned char buffer[BUFLEN];

	setMemBufPos(linkerTags, 0);
	if (!isMemBufAtEnd(linkerTags)) {
		readFromMemBuf(linkerTags, &tag, sizeof(struct LINKTAG));
		toGo = tag.position;
	}

    while (!feof(codeFh)) {
		// As long as toGo is non-zero, keep reading code from the file.
		while (!feof(codeFh) && toGo) {
			n = BUFLEN;
			if (toGo > 0 && BUFLEN > toGo) {
				n = toGo;
			}
			n = fread(buffer, 1, n, codeFh);
			if (n) {
				fwrite(buffer, 1, n, out);
				pos += n;
				if (toGo >= 0) {
					toGo -= n;
				}
			}
		}

		// If toGo is still -1, the end of the file has been reached.
		if (feof(codeFh)) {
			break;
		}

		// This is an address to fix.
		n = tag.which == LINKADDR_BOTH ? 2 : 1;
		n = fread(buffer, 1, n, codeFh);
		retrieveChunk(tag.chunkNum, &sym);
		if (tag.which == LINKADDR_LOW) {
			buffer[0] = WORD_LOW(sym.address);
		}
		else if (tag.which == LINKADDR_HIGH) {
			buffer[0] = WORD_HIGH(sym.address);
		}
		else if (tag.which == LINKADDR_BOTH) {
			memcpy(buffer, &sym.address, 2);
		}
		fwrite(buffer, 1, n, out);
		pos += n;

		if (isMemBufAtEnd(linkerTags)) {
			toGo = -1;
		} else {
			readFromMemBuf(linkerTags, &tag, sizeof(struct LINKTAG));
			toGo = tag.position - pos;
		}
    }
}
