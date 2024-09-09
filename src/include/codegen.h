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
#define MAX_LOCAL_VARS 32

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

struct ARRAYINIT
{
	char scopeLevel;
	char scopeOffset;
	short heapOffset;		// offset into variable heap for array header
	short minIndex;
	short maxIndex;
	short elemSize;
	CHUNKNUM literals;
	short numLiterals;
	char areLiteralsReals;
};

/*
	Array Initialization:

	Arrays are stored in memory as a six-byte header followed by the elements. Since
	they are statically allocated, arrays always take up the space needed to store all
	elements.

	Array Header:
		Size in bytes  Description
		-------------  ----------------------------
		2              Lower bound of array index
		2              Upper bound of array index
		2              Size of each element
	
	Arrays are initialized at the time their declaration comes into scope. The array heap
	is allocated dynamically when the array enters scope and freed when it leaves scope.
	As part of the initialization, the array header is populated. If the program specified
	a list of literals to initialize the elements, those are set at that time. For each
	declaration scope, including the global scope, an initialization list is created that
	describes each array in that scope. The list consists of a block for each array. That
	block is defined as:

	  Size in bytes  Description
	  -------------  --------------------------------------------------------------
	  1              Scope level (global scope is 1)
	  1              Scope offset (variable offset in stack frame within scope)
	  2              This array's offset inside variable heap
	  2              Lower bound of array index
	  2              Upper bound of array index
	  2              Element size
	  2              Pointer to list of literals to initialize the array elements
	  2              The number of literals within the list
	  1              Non-zero if the list of literals are real numbers
	
	This list is stored within the PRG file and written by the linker. The runtime reads the
	list when it is time to initialize the arrays in a particular scope. Again, each scope gets
	its own list of these initialization blocks.
*/

// Shared global variables
extern CHUNKNUM linkerTags;
extern CHUNKNUM arrayInitsForScope;
extern CHUNKNUM arrayInitsForAllScopes;
extern CHUNKNUM stringLiterals;
extern int numArrayInitsForScope;
extern int numArrayInitsForAllScopes;
extern int numStringLiterals;
extern FILE *codeFh;
extern unsigned short codeOffset;
extern unsigned short codeBase;		// base address of code
extern short heapOffset;

/*
	Internal Handling of Array Initialization

	This section documents how the compiler handles array intialization internally.

	During object code generation, a list of initialization blocks is created for
	each scope. The list is empty if no arrays are declared in that scope. The
	list for each scope is combined into a list of the lists. The list-of-lists
	is later used by the linker to put into the output PRG.

	The following variables are used to manage the array initializations.

	  Name                       Description
	  ----------------------     -----------------------------------------------------
	  arrayInitsForScope         Initialization blocks for the current scope
	  numArrayInitsForScope      Number of initialization blocks for the current scope
	  arrayInitsForAllScopes     List of lists for all scopes
	  numArrayInitsForAllScopes  Number of lists in arrayInitsForAllScopes

	arrayInitsForScope:
	  This is a membuf that contains the initialization blocks for the current scope.
	  When object code generation for the current scope concludes, the value of this
	  variable is written to the membuf at arrayInitsForAllScopes and a call to
	  initArrays in the runtime is generated.
	
	arrayInitsForAllScopes:
	  This is a membuf that contains the CHUNKNUMs of each membuf that was created
	  when a scope was processed.
	
	When the object generator completes the declarations for a given scope, it is left
	with a membuf in arrayInitsForScope. The membuf is not allocated if no arrays were
	declared. At the time of code generation a call to initArrays in the runtime is
	generated. The runtime call expects a pointer to the list of initialization blocks.
	That pointer is a forward reference that is resolved later by the linker using a
	label. The label is called "arrayInits<CHUNKNUM>" where CHUNKNUM is the membuf for
	the list of initialization blocks.

*/

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
void genExpr(CHUNKNUM chunkNum, char isRead, char noStack);
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
int genVariableDeclarations(CHUNKNUM chunkNum, short* heapOffsets);
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
char linkAddressLookup(const char* name, unsigned short position, char whichNeeded);

// Sets the code offset for a given symbol.
void linkAddressSet(const char* name, unsigned short offset);

void cleanupLibraries(CHUNKNUM astRoot);
void initLibraries(CHUNKNUM astRoot);
void loadLibraries(CHUNKNUM astRoot);

void readRuntimeDefFile(void);
void setRuntimeRef(unsigned char exportNum, unsigned short offset);
void linkerWriteRuntime(void);

void sortLinkerTags(void);

#endif // end of CODEGEN_H
