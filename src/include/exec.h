#ifndef EXEC_H
#define EXEC_H

#include <misc.h>
#include <error.h>
#include <symtab.h>
#include <backend.h>

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

    TOKEN *pToken;      // ptr to the current token
    TTokenCode token;   // code of current token
    SYMTABNODE *pNode;  // ptr to symtab node

    // Pointers to the special "input" and "output"
    // symbol table nodes entered by the parser.
    SYMTABNODE *pInputNode;
    SYMTABNODE *pOutputNode;
} EXECUTOR;

// Icode

EXECUTOR *executorInit(void);
void freeExecutor(EXECUTOR *pExec);
void executorGoto(EXECUTOR *pExec, unsigned location);
unsigned executorCurrentLocation(EXECUTOR *pExec);

// Statements
void executeStatement(EXECUTOR *pExec);
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
