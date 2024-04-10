/**
 * codegen.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for object code generation
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef CODEGEN_H
#define CODEGEN_H

#include <chunks.h>
#include <ast.h>
#include <stdio.h>

#define WORD_LOW(a) ((unsigned char)((a) & 0xff))
#define WORD_HIGH(a) ((unsigned char)((a) >> 8))

#define DWORD_LSB(a) ((unsigned char)((a) & 0xff))
#define DWORD_NLSB(a) ((unsigned char)(((a) >> 8) & 0xff))
#define DWORD_NMSB(a) ((unsigned char)(((a) >> 16) & 0xff))
#define DWORD_MSB(a) ((unsigned char)(((a) >> 24) & 0xff))

#define MAX_LOCAL_HEAPS 16

#define LINKADDR_LOW  1
#define LINKADDR_HIGH 2
#define LINKADDR_BOTH 3

struct LINKSYMBOL {
	char name[16 + 1];
	unsigned short address;
	CHUNKNUM left;
	CHUNKNUM right;
};

struct LINKTAG {
	CHUNKNUM chunkNum;
	unsigned short position;
	char which;  // one of LINKADDR_*
};

// Shared global variables
extern CHUNKNUM linkerTags;
extern CHUNKNUM stringLiterals;
extern int numStringLiterals;
extern FILE *codeFh;
extern unsigned short codeOffset;
extern unsigned short codeBase;		// base address of code
extern short heapOffset;

/*
	Code generation is split between two overlays: objcode and linker

	ObjCode Handles:
		* Allocating and initializing global variables and their
		* Generating object code for all routines and the main routine
	
	Linker Handles:
		* Writing the BASIC header
		* Writing the runtime to the program file
		* Generating initialization code for the program
		* Writing string literals to the program file
		* Generating code to clean up resources and set the system back
		* Resolve address references
		* Write the program file
	
	The overlays share the work of generating the program file.  The linker
	is called first.  It sets up the object code buffer and writes some
	preliminary code.

	Then, the objcode overlay takes over and generates object code for
	global variable initialization, function and procedures, and the main procedure.

	Finally, the linker is brought back in to finish up object code and write
	the program file to disk.

	Order:
		1) Linker:
			Allocate codeBuf
			Initialize linker symbol table
			Write BASIC header
			Write runtime to code buffer
			Write program header
		2) ObjCode:
			Generate global variable declarations
			Generate routine declarations
			Generate main procedure body
		3) Linker:
			Generate program cleanup code
			Dump string literals
			Restore page zero
			Write program file from codeBuf
*/

#define EXPR_FREE_STRING1_LEN 5
extern unsigned char exprFreeString1[];

void genOne(unsigned char b);
void genTwo(unsigned char b1, unsigned char b2);
void genThreeAddr(unsigned char b, unsigned short addr);

void genBoolValueA(CHUNKNUM chunkNum);
void genCharValueA(CHUNKNUM chunkNum);
void genExpr(CHUNKNUM chunkNum, char isRead, char noStack, char isParentHeapVar);
void genFreeVariableHeaps(short* heapOffsets);
void genShortValueA(CHUNKNUM chunkNum);
void genIntValueAX(CHUNKNUM chunkNum);
void genIntValueEAX(CHUNKNUM chunkNum);
void genRealValueEAX(CHUNKNUM chunkNum);
void genRoutineDeclarations(CHUNKNUM chunkNum);
void genRuntimeCall(unsigned char routine);
void genStringValueAX(CHUNKNUM chunkNum);
void genSubroutineCall(CHUNKNUM chunkNum);
void genStmts(CHUNKNUM chunkNum);
void genRecordInit(struct type* pType);
int genVariableDeclarations(CHUNKNUM chunkNum, short* heapOffsets);
int getArrayLimit(CHUNKNUM chunkNum);
char isStringFunc(CHUNKNUM exprChunk);
void writeCodeBuf(unsigned char *buf, int len);

// Linker Symbol Table

void freeLinkerSymbolTable(void);
void initLinkerSymbolTable(void);

void linkerPreWrite(CHUNKNUM astRoot);
void objCodeWrite(CHUNKNUM astRoot);
#ifdef COMPILERTEST
void linkerPostWrite(const char* prgFilename, char* nextTest, CHUNKNUM astRoot);
#else
void linkerPostWrite(const char* prgFilename, char run, CHUNKNUM astRoot);
#endif

// Returns 1 if address found in table : address is valid
// address parameter can be NULL if the caller does not need to know it
// whichNeeded is one of LINKADDR_LOW, LINKADDR_HIGH, or LINKADDR_BOTH
//    This is ignored if address is non-null.  It is only used if the
//    address is to be filled in later.
char linkAddressLookup(const char* name, unsigned short position, unsigned short* address, char whichNeeded);

// Sets the code offset for a given symbol.
void linkAddressSet(const char* name, unsigned short offset);

void loadLibraries(CHUNKNUM astRoot);

void readRuntimeDefFile(void);
void setRuntimeRef(unsigned char exportNum, unsigned short offset);
void linkerWriteRuntime(void);

void sortLinkerTags(void);

#endif // end of CODEGEN_H
