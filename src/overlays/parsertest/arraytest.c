#include <stdio.h>
#include "parsertest.h"
#include <tests.h>
#include <string.h>
#include <stdlib.h>

// elemType, indexBaseType, minIndex, maxIndex, elemCount, subArrayCase
static struct ArrayTestCase subArrayCase =
    { REAL_TYPE, CHAR_TYPE, 'm', 'r', 6 };

static struct ArrayTestCase arrayTests[] = {
    { BOOLEAN_TYPE, INTEGER_TYPE, 1, 6, 6 },
    { CHAR_TYPE, INTEGER_TYPE, 0, 10, 11 },
    { INTEGER_TYPE, INTEGER_TYPE, -5, 5, 11 },
    { REAL_TYPE, INTEGER_TYPE, 0, 3, 4 },
    { EN_TYPE, INTEGER_TYPE, -5, 0, 6 },
    { INTEGER_TYPE, INTEGER_TYPE, 0, 4, 5 },
    { REAL_TYPE, INTEGER_TYPE, 0, 2, 3 },
    { BOOLEAN_TYPE, CHAR_TYPE, 'a', 'z', 26 },
    { NONE_TYPE, INTEGER_TYPE, 1, 10, 10, &subArrayCase },
    { 0 },
};

// name, type, baseType
static struct VarTestCase arrayVarTests[] = {
    { "ab",         NONE_TYPE, NONE_TYPE },
    { "ac",         NONE_TYPE, NONE_TYPE },
    { "ai",         NONE_TYPE, NONE_TYPE },
    { "ar",         NONE_TYPE, NONE_TYPE },
    { "ae",         NONE_TYPE, NONE_TYPE },
    { "ae2",        NONE_TYPE, NONE_TYPE },
    { "ae3",        NONE_TYPE, NONE_TYPE },
    { "al",         NONE_TYPE, NONE_TYPE },
    { "an",         NONE_TYPE, NONE_TYPE },
    { "b",          BOOLEAN_TYPE, BOOLEAN_TYPE },
    { "c",          CHAR_TYPE,    CHAR_TYPE    },
    { "i",          INTEGER_TYPE, INTEGER_TYPE },
    { "r",          REAL_TYPE,    REAL_TYPE    },
    { "e",          EN_TYPE,      EN_TYPE      },
    { NULL },
};

void arrayTest(CHUNKNUM programId) {
    SYMBNODE programNode;

    loadSymbNode(programId, &programNode);
    testIcode = programNode.defn.routine.Icode;
    setMemBufPos(testIcode, 0);
    runIcodeTests("arraytest.txt", 24, "arrayIcodeTests");

    runVarTests(programNode.defn.routine.locals.variableIds, arrayVarTests, 1, "arrayVarTests");

    runArrayTests(programNode.defn.routine.locals.variableIds, arrayTests, "arrayTests");
}
