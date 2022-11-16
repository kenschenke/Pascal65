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

#define RUNTIME_STACKSIZE 32

typedef struct {
    int stack[RUNTIME_STACKSIZE];
    char top;
} RTSTACK;

RTSTACK *rtstack_init(void);
int rtstack_pop(RTSTACK *pStack);
void rtstack_push(RTSTACK *pStack, int value);

typedef struct {
    unsigned stmtCount;
    RTSTACK *runStack;
    char userStop;      // 1 if user requested stop execution

    TTokenCode token;   // code of current token
    SYMTABNODE *pNode;  // ptr to symtab node

    // Chunk numbers for the special "input" and "output"
    // symbol table nodes entered by the parser.
    CHUNKNUM inputNode;
    CHUNKNUM outputNode;
} EXECUTOR;

// Icode

void executorFree(EXECUTOR *pExec);
EXECUTOR *executorInit(void);
void freeExecutor(EXECUTOR *pExec);
void executorGoto(EXECUTOR *pExec, unsigned location);
unsigned executorCurrentLocation(EXECUTOR *pExec);

// Statements
void executeCompound(EXECUTOR *pExec);
void executeREPEAT(EXECUTOR *pExec);
void executeStatement(EXECUTOR *pExec);
void executeStatementList(EXECUTOR *pExec, TTokenCode terminator);
void executeAssignment(EXECUTOR *pExec);

// Expressions
void executeExpression(EXECUTOR *pExec);
void executeSimpleExpression(EXECUTOR *pExec);
void executeTerm(EXECUTOR *pExec);
void executeFactor(EXECUTOR *pExec);

EXECUTOR *executorInit(void);
void executorGo(EXECUTOR *pExec);
void getTokenForExecutor(EXECUTOR *pExec);

#endif // end of EXEC_H
