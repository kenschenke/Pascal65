#include <stdio.h>
#include "parsertest.h"
#include <tests.h>
#include <string.h>
#include <stdlib.h>

// elemType, indexBaseType, minIndex, maxIndex, elemCount
static struct ArrayTestCase subrangeArrayTests[] = {
    { INTEGER_TYPE, INTEGER_TYPE, -5, 5, 11 },
    { INTEGER_TYPE, INTEGER_TYPE, -6, 0, 7 },
    { INTEGER_TYPE, INTEGER_TYPE, 0, 10, 11 },
    { INTEGER_TYPE, INTEGER_TYPE, 1, 6, 6 },
    { NULL },
};

void subrangeTest(CHUNKNUM programId) {
    SYMBNODE programNode;

    loadSymbNode(programId, &programNode);

    runArrayTests(programNode.defn.routine.locals.variableIds, subrangeArrayTests, "subrangeArrayTests");
}
