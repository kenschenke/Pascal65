#ifndef CODEGEN_H
#define CODEGEN_H

#include <chunks.h>

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

extern CHUNKNUM codeBuf;
extern unsigned short codeOffset;
extern unsigned short codeBase;		// base address of code

void genOne(unsigned char b);
void genTwo(unsigned char b1, unsigned char b2);
void genThreeAddr(unsigned char b, unsigned short addr);

void genBoolValueA(CHUNKNUM chunkNum);
void genCharValueA(CHUNKNUM chunkNum);
void genExpr(CHUNKNUM chunkNum, char isRead, char noStack, char isParentHeapVar);
void genFreeVariableHeaps(short* heapOffsets);
void genIntValueAX(CHUNKNUM chunkNum);
#ifdef COMPILERTEST
void genProgram(CHUNKNUM astRoot, const char* prgFilename, char* nextTest);
#else
void genProgram(CHUNKNUM astRoot, const char* prgFilename);
#endif
void genRealValueEAX(CHUNKNUM chunkNum);
void genRoutineDeclarations(CHUNKNUM chunkNum);
void genStringValueAX(CHUNKNUM chunkNum);
void genSubroutineCall(CHUNKNUM chunkNum);
void genStmts(CHUNKNUM chunkNum);
int genVariableDeclarations(CHUNKNUM chunkNum, short* heapOffsets);
#if 0
void freeVariableHeaps(short* heapOffsets);
#endif
void writeCodeBuf(unsigned char *buf, int len);

// Linker Symbol Table

void freeLinkerSymbolTable(void);
void initLinkerSymbolTable(void);

// Returns 1 if address found in table : address is valid
// address parameter can be NULL if the caller does not need to know it
// whichNeeded is one of LINKADDR_LOW, LINKADDR_HIGH, or LINKADDR_BOTH
//    This is ignored if address is non-null.  It is only used if the
//    address is to be filled in later.
char linkAddressLookup(const char* name, unsigned short position, unsigned short* address, char whichNeeded);

// Sets the code offset for a given symbol.
void linkAddressSet(const char* name, unsigned short offset);

void updateLinkerAddresses(CHUNKNUM codeBuf);

#endif // end of CODEGEN_H
