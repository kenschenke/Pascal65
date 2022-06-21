#include <stdlib.h>
#include <string.h>
#include <exec.h>
#include <icode.h>
#include <error.h>
#include <common.h>
#include <symtab.h>

void getTokenForExecutor(EXECUTOR *pExec)
{
    pExec->pToken = getNextTokenFromIcode(pGlobalIcode);
    pExec->token = pExec->pToken->code;
    pExec->pNode = pGlobalIcode->pNode;
}

RTSTACK *rtstack_init(void)
{
    RTSTACK *pStack = malloc(sizeof(RTSTACK));
    if (pStack == NULL) {
        runtimeError(rteOutOfMemory);
        return NULL;
    }
    
    pStack->top = 0;
    return pStack;
}

int rtstack_pop(RTSTACK *pStack)
{
    return pStack->stack[pStack->top--];
}

void rtstack_push(RTSTACK *pStack, int value)
{
    if (pStack->top < RUNTIME_STACKSIZE) {
        pStack->stack[++pStack->top] = value;
    } else {
        runtimeError(rteStackOverflow);
    }
}

EXECUTOR *executorInit(void)
{
    EXECUTOR *pExec = malloc(sizeof(EXECUTOR));
    if (pExec == NULL) {
        runtimeError(rteOutOfMemory);
        return NULL;
    }

    memset(pExec, 0, sizeof(EXECUTOR));
    pExec->runStack = rtstack_init();
    if (pExec->runStack == NULL) {
        free(pExec);
        return NULL;
    }

    pExec->pInputNode = searchSymtab(pGlobalSymtab, "input");
    pExec->pOutputNode = searchSymtab(pGlobalSymtab, "output");

    return pExec;
}

void freeExecutor(EXECUTOR *pExec)
{
    free(pExec->runStack);
    free(pExec);
}

void executorGoto(EXECUTOR *pExec, unsigned location)
{
    gotoIcodePosition(pGlobalIcode, location);
}

unsigned executorCurrentLocation(EXECUTOR *pExec)
{
    return getCurrentIcodeLocation(pGlobalIcode);
}

void executorGo(EXECUTOR *pExec)
{
    // Reset the icode to the beginning
    // and extract the first token
    resetIcodePosition(pGlobalIcode);
    getTokenForExecutor(pExec);

    // Loop to execute statements until the end of the program.
    do {
        executeStatement(pExec);

        // Skip semicolons
        while (pExec->token == tcSemicolon) {
            getTokenForExecutor(pExec);
        }
    } while (pExec->token != tcPeriod);
}

