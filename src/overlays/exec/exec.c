/**
 * exec.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Entry point for executor overlay
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdlib.h>
#include <string.h>
#include <exec.h>
#include <icode.h>
#include <error.h>
#include <common.h>
#include <symtab.h>
#include <membuf.h>
#include <ovrlcommon.h>
#if 1
#include <stdio.h>
#endif

static RTSTACK rtStack;

EXECUTOR executor;

void getTokenForExecutor(void)
{
    executor.prevNode = executor.pNode.node.nodeChunkNum;
    getNextTokenFromIcode(executor.Icode, &executor.token, &executor.pNode);
}

void stackInit(void) {
    rtStack.tos = &rtStack.stack[-1];       // point to just below bottom of stack
    rtStack.pFrameBase = &rtStack.stack[0]; // point to bottom of stack

    // Initialize the program's stack frame at the bottom
    stackPushInt(0);                        // function return value
    stackPushInt(0);                        // static link
    stackPushInt(0);                        // dynamic link
    stackPushInt(0);                        // return address icode pointer
    stackPushInt(0);                        // return address icode location
}

void stackPushInt(int value) {
    if (rtStack.tos < &rtStack.stack[RUNTIME_STACKSIZE-1]) {
        (++rtStack.tos)->integer = value;
    } else {
        runtimeError(rteStackOverflow);
    }
}

void stackPushReal(FLOAT value) {
    if (rtStack.tos < &rtStack.stack[RUNTIME_STACKSIZE-1]) {
        (++rtStack.tos)->real = value;
    } else {
        runtimeError(rteStackOverflow);
    }
}

void stackPushChar(char value) {
    if (rtStack.tos < &rtStack.stack[RUNTIME_STACKSIZE-1]) {
        (++rtStack.tos)->character = value;
    } else {
        runtimeError(rteStackOverflow);
    }
}

void stackPushMemBuf(CHUNKNUM value, int offset) {
    if (rtStack.tos < &rtStack.stack[RUNTIME_STACKSIZE-1]) {
        STACKITEM *pStackItem = ++rtStack.tos;
        pStackItem->membuf.membuf = value;
        pStackItem->membuf.offset = offset;
    } else {
        runtimeError(rteStackOverflow);
    }
}

void stackPushNode(CHUNKNUM value) {
    if (rtStack.tos < &rtStack.stack[RUNTIME_STACKSIZE-1]) {
        (++rtStack.tos)->nodeChunk = value;
    } else {
        runtimeError(rteStackOverflow);
    }
}

void stackPushItem(STACKITEM *value) {
    if (rtStack.tos < &rtStack.stack[RUNTIME_STACKSIZE-1]) {
        (++rtStack.tos)->pStackItem = value;
    } else {
        runtimeError(rteStackOverflow);
    }
}

STACKITEM *stackPushFrameHeader(int oldLevel, int newLevel, CHUNKNUM icode) {
    STACKFRAMEHDR *pHeader = (STACKFRAMEHDR *) rtStack.pFrameBase;
    STACKITEM *pNewFrameBase = rtStack.tos + 1;

    stackPushInt(0);    // function return value (placeholder)

    // Compute the stack link
    if (newLevel == oldLevel + 1) {
        // Callee nested within caller:
        // Push address of caller's stack frame
        stackPushItem((STACKITEM *)pHeader);
    } else if (newLevel == oldLevel) {
        // Callee e level as caller
        // Push address of common parent's stack frame.
        stackPushItem(pHeader->staticLink.pStackItem);
    } else {
        // Callee nested less deeply than caller:
        // Push address of nearest common ancestor's stack frame.
        int delta = oldLevel - newLevel;
        while (delta-- >= 0) {
            pHeader = (STACKFRAMEHDR *) pHeader->staticLink.pStackItem;
        }
        stackPushItem((STACKITEM *)pHeader);
    }

    stackPushItem(rtStack.pFrameBase);      // dynamic link
    stackPushMemBuf(icode, 0);              // return address icode pointer
    stackPushInt(0);                        // return address icode location (placeholder)

    return pNewFrameBase;
}

void stackActivateFrame(STACKITEM *pNewFrameBase, int location) {
    rtStack.pFrameBase = pNewFrameBase;
    ((STACKFRAMEHDR *) rtStack.pFrameBase)->returnAddress.location.integer = location;
}

void stackPopFrame(SYMBNODE *pRoutineId, CHUNKNUM *pIcode) {
    STACKFRAMEHDR *pHeader = (STACKFRAMEHDR *) rtStack.pFrameBase;

    // Don't do anything if it's the bottommost stack frame
    if (rtStack.pFrameBase != &rtStack.stack[0]) {
        // Return to the caller's intermediate code.
        *pIcode = pHeader->returnAddress.icode.membuf.membuf;
        setMemBufPos(*pIcode, pHeader->returnAddress.location.integer);

        // Cut the stack back.  Leave a function value on top
        rtStack.tos = (STACKITEM *) rtStack.pFrameBase;
        if (pRoutineId->defn.how != dcFunction)
            --rtStack.tos;
        rtStack.pFrameBase = pHeader->dynamicLink.pStackItem;
    }
}

void stackAllocateValue(SYMBNODE *pId) {
    CHUNKNUM baseType = getBaseType(&pId->type);

    if (baseType == integerType) {
        stackPushInt(0);
    } else if (baseType == booleanType) {
        stackPushInt(0);
    } else if (baseType == charType) {
        stackPushChar(0);
    } else if (baseType == fcEnum) {
        stackPushInt(0);
    } else {
        // Array or record
        CHUNKNUM membuf;
        allocMemBuf(&membuf);
        reserveMemBuf(membuf, pId->type.size);
        stackPushMemBuf(membuf, 0);
    }
}

void stackDeallocateValue(SYMBNODE *pId) {
    if (!isTypeScalar(&pId->type) && pId->defn.how != dcVarParm) {
        STACKITEM *pValue = ((STACKITEM *) rtStack.pFrameBase) +
        RUNTIME_FRAMEHEADERSIZE + pId->defn.data.offset;
        freeMemBuf(pValue->membuf.membuf);
    }
}

STACKITEM *stackGetValueAddress(SYMBNODE *pId) {
    int functionFlag = pId->defn.how == dcFunction; // true if function, else false
    STACKFRAMEHDR *pHeader = (STACKFRAMEHDR *) rtStack.pFrameBase;

    // Compute the difference between the current nesting level
    // and the level of the variable or parameter.  Treat a function
    // value as if it were a local variable of the function.  (Local
    // variables are one level higher than the function name.)
    int delta = currentNestingLevel - pId->node.level;
    if (functionFlag) --delta;

    // Chase static links delta times.
    while (delta-- > 0) {
        pHeader = (STACKFRAMEHDR *) pHeader->staticLink.pStackItem;
    }

    return functionFlag ? &pHeader->functionValue
        : ((STACKITEM *) pHeader)
            + RUNTIME_FRAMEHEADERSIZE + pId->defn.data.offset;
}

STACKITEM *stackPop(void) {
    return rtStack.tos--;
}

STACKITEM *stackTOS(void) {
    return rtStack.tos;
}

void executorInit(void)
{
    SYMBNODE node;

    memset(&executor, 0, sizeof(EXECUTOR));

    executor.traceRoutineFlag = 1;
    executor.traceStatementFlag = 1;
    executor.traceFetchFlag = 1;
    executor.traceStoreFlag = 1;

    searchSymtab(globalSymtab, &node, "input");
    executor.inputNode = node.node.nodeChunkNum;

    searchSymtab(globalSymtab, &node, "output");
    executor.outputNode = node.node.nodeChunkNum;
}

void executorGoto(unsigned /*location*/)
{
    // setMemBufPos(pGlobalIcode, location);
}

unsigned executorCurrentLocation(void)
{
    return 0;
    // return getMemBufPos(pGlobalIcode);
}

void executorGo(SYMBNODE *pRoutineId)
{
    // Execute the program
    currentNestingLevel = 1;
    executeRoutine(pRoutineId);

    // Print the executor's summary
    printf("\n");
    printf("Successful completion.  %d statements executed\n",
        executor.stmtCount);
}

void rangeCheck(TTYPE *pTargetType, int value) {
    if (pTargetType->form == fcSubrange &&
        (value < pTargetType->subrange.min || value > pTargetType->subrange.max)) {
        runtimeError(rteValueOutOfRange);
    }
}