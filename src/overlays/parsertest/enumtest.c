#include <stdio.h>
#include "parsertest.h"
#include <tests.h>
#include <string.h>
#include <stdlib.h>

static const char *arValues[] = { "one", "two", "three", "four", "five" };
static const char *enValues[] = { "alpha", "beta", "gamma" };
static const char *fruitValues[] = { "apple", "banana", "lemon" };

static void testEnumValues(CHUNKNUM typeId, const char *values[]);

static void testEnumValues(CHUNKNUM typeId, const char *values[]) {
    int i = 0;
    char name[CHUNK_LEN];
    TTYPE typeNode;
    SYMBNODE value;
    CHUNKNUM valueId;

    retrieveChunk(typeId, (unsigned char *)&typeNode);
    valueId = typeNode.enumeration.constIds;

    while (valueId) {
        while (valueId) {
            loadSymbNode(valueId, &value);
            retrieveChunk(value.node.nameChunkNum, (unsigned char *)name);
            if (strncmp(name, values[i], CHUNK_LEN)) {
                printf("Expected enum %d as %s -- got %.22s\n",
                    i, values[i], name);
                exit(5);
            }
            if (i != value.defn.constant.value.integer) {
                printf("Expected enum %d -- got %d\n", i,
                    value.defn.constant.value.integer);
                exit(5);
            }
            ++i;

            valueId = value.node.nextNode;
        }
    }
}

void enumTest(CHUNKNUM programId) {
    char name[CHUNK_LEN];
    CHUNKNUM variableId;
    SYMBNODE varNode;
    SYMBNODE programNode;

    loadSymbNode(programId, &programNode);
    testIcode = programNode.defn.routine.Icode;
    setMemBufPos(testIcode, 0);
    runIcodeTests("enumtest.txt", 16, "enumIcodeTests");

    variableId = programNode.defn.routine.locals.variableIds;
    while (variableId) {
        loadSymbNode(variableId, &varNode);

        retrieveChunk(varNode.node.nameChunkNum, (unsigned char *)name);
        if (!strncmp(name, "ae", CHUNK_LEN)) {
            testEnumValues(varNode.type.array.indexType, enValues);
        } else if (!strncmp(name, "a1", CHUNK_LEN)) {
            testEnumValues(varNode.type.array.indexType, enValues);
        } else if (!strncmp(name, "an", CHUNK_LEN)) {
            testEnumValues(varNode.type.array.indexType, arValues);
        } else if (!strncmp(name, "af", CHUNK_LEN)) {
            testEnumValues(varNode.type.array.indexType, fruitValues);
        } else if (!strncmp(name, "ee", CHUNK_LEN) || !strncmp(name, "ef", CHUNK_LEN)) {
            testEnumValues(varNode.type.nodeChunkNum, enValues);
        }

        variableId = varNode.node.nextNode;
    }
}
