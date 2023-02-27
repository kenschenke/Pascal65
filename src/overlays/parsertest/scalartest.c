#include <stdio.h>
#include "parsertest.h"
#include <types.h>

// name, type, baseType
static struct VarTestCase varTests[] = {
    { "b",          BOOLEAN_TYPE, BOOLEAN_TYPE },
    { "b2",         BOOLEAN_TYPE, BOOLEAN_TYPE },
    { "c",          CHAR_TYPE,    CHAR_TYPE    },
    { "c2",         CHAR_TYPE,    CHAR_TYPE    },
    { "i",          INTEGER_TYPE, INTEGER_TYPE },
    { "j",          INTEGER_TYPE, INTEGER_TYPE },
    { "r",          REAL_TYPE,    REAL_TYPE    },
    { "s",          REAL_TYPE,    REAL_TYPE    },
    { NULL },
};

void scalarTest(CHUNKNUM programId) {
    SYMBNODE programNode;

    loadSymbNode(programId, &programNode);
    testIcode = programNode.defn.routine.Icode;
    setMemBufPos(testIcode, 0);
    runIcodeTests("scalartest.txt", 10, "scalarIcodeTests");

    runVarTests(programNode.defn.routine.locals.variableIds, varTests, 1, "varTests");
}
