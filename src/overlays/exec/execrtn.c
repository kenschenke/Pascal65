#include <exec.h>
#include <membuf.h>

void executeRoutine(SYMBNODE *pRoutineId) {
    enterRoutine(pRoutineId);

    // Execute the routine's compound statement.
    executeCompound();

    exitRoutine(pRoutineId);
}

CHUNKNUM executeSubroutineCall(SYMBNODE *) {
    return 0;
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