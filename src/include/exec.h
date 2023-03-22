/**
 * exec.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for executor
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef EXEC_H
#define EXEC_H

#include <misc.h>
#include <icode.h>
#include <error.h>
#include <symtab.h>
#include <chunks.h>
#include <real.h>

#define RUNTIME_STACKSIZE 128
#define RUNTIME_FRAMEHEADERSIZE 5

typedef union STACKITEM {
    int integer;
    FLOAT real;
    char character;
    struct {
        CHUNKNUM membuf;    // membuf header
        int offset;         // offset of value within buffer
    } membuf;
    CHUNKNUM nodeChunk;     // chunknum of SYMBNODE
    union STACKITEM *pStackItem;  // pointer to item elsewhere in stack
} STACKITEM;

typedef struct {
    STACKITEM stack[RUNTIME_STACKSIZE];
    STACKITEM *tos;     // pointer to top of stack
    STACKITEM *pFrameBase;  // ptr to current stack frame base
} RTSTACK;

typedef struct {
    STACKITEM functionValue;
    STACKITEM staticLink;
    STACKITEM dynamicLink;

    struct {
        STACKITEM icode;
        STACKITEM location;
    } returnAddress;
} STACKFRAMEHDR;

RTSTACK *rtstack_init(void);

typedef struct {
    unsigned stmtCount;
    char userStop;      // 1 if user requested stop execution

    TOKEN token;        // current token
    SYMBNODE pNode;     // symtab node
    CHUNKNUM prevNode;  // previous symtab node

    CHUNKNUM Icode;     // current icode

    // Trace Flags
    int traceRoutineFlag;
    int traceStatementFlag;
    int traceStoreFlag;
    int traceFetchFlag;

    // Chunk numbers for the special "input" and "output"
    // symbol table nodes entered by the parser.
    CHUNKNUM inputNode;
    CHUNKNUM outputNode;
} EXECUTOR;

extern EXECUTOR executor;

void stackInit(void);
void stackAllocateValue(SYMBNODE *pId);
void stackDeallocateValue(SYMBNODE *pId);
STACKITEM *stackGetValueAddress(SYMBNODE *pId);
void stackPushInt(int value);
void stackPushReal(FLOAT value);
void stackPushChar(char value);
void stackPushMemBuf(CHUNKNUM value, int offset);
void stackPushNode(CHUNKNUM nodeChunk);
void stackPushItem(STACKITEM *pStackItem);
STACKITEM *stackPushFrameHeader(int oldLevel, int newLevel, CHUNKNUM icode);
STACKITEM *stackPop(void);
STACKITEM *stackTOS(void);
void stackActivateFrame(STACKITEM *pNewFrameBase, int location);
void stackPopFrame(SYMBNODE *routineId, CHUNKNUM *pIcode);

// Icode

void executorInit(void);
void executorGoto(unsigned location);
unsigned executorCurrentLocation(void);

// Routines
void executeRoutine(SYMBNODE *routineId);
void executeActualParameters(SYMBNODE *pRoutineId);
CHUNKNUM executeDeclaredSubroutineCall(SYMBNODE *pRoutineId);
CHUNKNUM executeStandardSubroutineCall(SYMBNODE *pRoutineId);
CHUNKNUM executeSubroutineCall(SYMBNODE *pRoutineId);
void enterRoutine(SYMBNODE *pRoutineId);
void exitRoutine(SYMBNODE *pRoutineId);

// Standard subroutines
CHUNKNUM executeAbsSqrCall(SYMBNODE *pRoutineId);
CHUNKNUM executeChrCall(void);
CHUNKNUM executeEofEolnCall(SYMBNODE *pRoutineId);
CHUNKNUM executeOddCall(void);
CHUNKNUM executeOrdCall(void);
CHUNKNUM executePrecSuccCall(SYMBNODE *pRoutineId);
CHUNKNUM executeReadReadlnCall(SYMBNODE *pRoutineId);
CHUNKNUM executeRoundTruncCall(SYMBNODE *pRoutineId);
CHUNKNUM executeWriteWritelnCall(SYMBNODE *pRoutineId);

// Statements
void executeCompound(void);
void executeCASE(void);
void executeFOR(void);
void executeIF(void);
void executeREPEAT(void);
void executeWHILE(void);
void executeStatement(void);
void executeStatementList(TTokenCode terminator);
void executeAssignment(SYMBNODE *pTargetId);

// Expressions
CHUNKNUM executeExpression(void);
CHUNKNUM executeSimpleExpression(void);
CHUNKNUM executeTerm(void);
CHUNKNUM executeFactor(void);
CHUNKNUM executeConstant(SYMBNODE *pId);
CHUNKNUM executeVariable(SYMBNODE *pId, char addressFlag);
CHUNKNUM executeSubscripts(TTYPE *pType);
CHUNKNUM executeField(TTYPE *pType);

void executorGo(SYMBNODE *pRoutineId);
void getTokenForExecutor(void);

void rangeCheck(TTYPE *targetType, int value);

#ifdef __TEST__
// Tracing
void traceRoutineEntry(SYMBNODE *pRoutineId);
void traceRoutineExit(SYMBNODE *pRoutineId);
void traceStatement(void);
void traceDataStore(SYMBNODE *pTargetId,
    void *pDataValue, TTYPE *pDataType);
void traceDataFetch(SYMBNODE *pId,
    void *pDataValue, TTYPE *pDataType);
void traceDataValue(void *pDataValue, TTYPE *pDataType);
#endif

#endif // end of EXEC_H
