#include <exec.h>
#include <membuf.h>
#include <error.h>
#include <common.h>
#include <string.h>
#include <real.h>

void executeRoutine(SYMBNODE *pRoutineId) {
    enterRoutine(pRoutineId);

    // Execute the routine's compound statement.
    executeCompound();

    exitRoutine(pRoutineId);
}

CHUNKNUM executeSubroutineCall(DEFN *pDefn) {
    return pDefn->routine.which == rcDeclared ?
        executeDeclaredSubroutineCall(executor.nodeChunkNum) :
        executeStandardSubroutineCall(pDefn->routine.which);
}

CHUNKNUM executeDeclaredSubroutineCall(CHUNKNUM nodeChunkNum) {
    SYMBNODE routineId;
    int oldLevel = currentNestingLevel;     // level of caller
    int newLevel;                           // level of callee's locals
    STACKITEM *pNewFrameBase;

    loadSymbNode(nodeChunkNum, &routineId);
    newLevel = routineId.node.level + 1;   // level of callee's locals

    // Set up a new stack frame for the callee
    pNewFrameBase = stackPushFrameHeader(oldLevel, newLevel, executor.Icode);

    // Push actual parameter values onto the stack
    getTokenForExecutor();
    if (executor.token.code == tcLParen) {
        executeActualParameters(&routineId);
        getTokenForExecutor();
    }

    // Activate the new stack frame
    currentNestingLevel = newLevel;
    stackActivateFrame(pNewFrameBase, getMemBufPos(executor.Icode));

    // And execute the callee
    executeRoutine(&routineId);

    // Return to the caller.  Restore the current token.
    currentNestingLevel = oldLevel;
    getTokenForExecutor();

    return routineId.type.nodeChunkNum;
}

CHUNKNUM executeStandardSubroutineCall(TRoutineCode routineCode) {
    switch (routineCode) {
        case rcRead:
        case rcReadln:   return executeReadReadlnCall(routineCode);

        case rcWrite:
        case rcWriteln:  return executeWriteWritelnCall(routineCode);

        case rcEof:
        case rcEoln:     return executeEofEolnCall(routineCode);

        case rcPred:
        case rcSucc:     return executePrecSuccCall(routineCode);

        case rcOdd:      return executeOddCall();

        case rcChr:      return executeChrCall();

        case rcOrd:      return executeOrdCall();

        case rcAbs:      return executeAbsCall();

        case rcRound:
        case rcTrunc:    return executeRoundTruncCall(routineCode);

        default:  return dummyType;
    }
}

void executeActualParameters(SYMBNODE *pRoutineId) {
    CHUNKNUM formalId;
    SYMBNODE node;
    CHUNKNUM formalType, actualType, actualBaseType;

    for (formalId = pRoutineId->defn.routine.locals.parmIds;
        formalId;
        formalId = node.node.nextNode) {
        loadSymbNode(formalId, &node);

        formalType = node.type.nodeChunkNum;
        getTokenForExecutor();

        // VAR parameter.  executeVariable will leave the actual
        // parameter's address on top of the stack.
        if (node.defn.how == dcVarParm) {
            executeVariable(executor.nodeChunkNum, getChunk(executor.defnChunkNum), executor.typeChunkNum, isTypeScalar(getChunk(executor.typeChunkNum)));
        } else {
            // Value parameter
            actualType = executeExpression();
            actualBaseType = getBaseType(getChunk(actualType));

            if (formalType == realType && actualBaseType == integerType) {
                // real formal := integer actual:
                // Convert integer value to real.
                stackPushReal(int16ToFloat(stackPop()->integer));
            } else if (!isTypeScalar(&node.type)) {
                // Formal parameter is an array or record.
                // Make a copy of the actual parameter's value.
                CHUNKNUM membuf;
                duplicateMemBuf(stackPop()->membuf.membuf, &membuf);
                stackPushMemBuf(membuf, 0);
            } else {
                // Range check a formal subrange parameter.
                rangeCheck(&pRoutineId->type, stackTOS()->integer);
            }
        }
    }
}

void enterRoutine(SYMBNODE *pRoutineId) {
    CHUNKNUM chunkNum;
    SYMBNODE nodeId;      // local variable's symtab node

    traceRoutineEntry(pRoutineId);

    // Allocate the callee's local variables.
    for (chunkNum = pRoutineId->defn.routine.locals.variableIds;
        chunkNum;
        chunkNum = nodeId.node.nextNode) {
        loadSymbNode(chunkNum, &nodeId);
        stackAllocateValue(&nodeId);
    }

    // Switch to the callee's intermediate code.
    executor.Icode = pRoutineId->defn.routine.Icode;
    setMemBufPos(executor.Icode, 0);
}

void exitRoutine(SYMBNODE *pRoutineId) {
    CHUNKNUM chunkNum;
    SYMBNODE nodeId;

    traceRoutineExit(pRoutineId);

    // Deallocate local parameters and variables.
    for (chunkNum = pRoutineId->defn.routine.locals.parmIds;
        chunkNum;
        chunkNum = nodeId.node.nextNode) {
        loadSymbNode(chunkNum, &nodeId);
        stackDeallocateValue(&nodeId);
    }
    for (chunkNum = pRoutineId->defn.routine.locals.variableIds;
        chunkNum;
        chunkNum = nodeId.node.nextNode) {
        loadSymbNode(chunkNum, &nodeId);
        stackDeallocateValue(&nodeId);
    }

    // Pop off the callee's stack frame and return to the caller's
    // intermediate code.
    stackPopFrame(pRoutineId, &executor.Icode);
}