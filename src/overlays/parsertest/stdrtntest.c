#include <stdio.h>
#include "parsertest.h"
#include <types.h>

void stdRtnTest(CHUNKNUM programId) {
    SYMBNODE programNode;

    loadSymbNode(programId, &programNode);
    testIcode = programNode.defn.routine.Icode;
    setMemBufPos(testIcode, 0);
    runIcodeTests("stdrtntest.txt", 10, "stdRtnIcodeTests");
}
