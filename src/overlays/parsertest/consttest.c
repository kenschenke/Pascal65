#include <stdio.h>
#include "parsertest.h"
#include <tests.h>
#include <string.h>
#include <stdlib.h>

void constTest(CHUNKNUM programId) {
    char name[CHUNK_LEN];
    CHUNKNUM constId;
    SYMBNODE programNode, constNode;

    DECLARE_TEST("constTest");

    loadSymbNode(programId, &programNode);
    testIcode = programNode.defn.routine.Icode;
    setMemBufPos(testIcode, 0);
    runIcodeTests("consttest.txt", 17, "constIcodeTests");

    constId = programNode.defn.routine.locals.constantIds;
    while (constId) {
        loadSymbNode(constId, &constNode);

        retrieveChunk(constNode.node.nameChunkNum, (unsigned char *)name);
        if (!strncmp(name, "bi", CHUNK_LEN)) {
            assertEqualChunkNum(booleanType, constNode.node.typeChunk);
            assertNonZero(constNode.defn.constant.value.integer);
        } else if (!strncmp(name, "ci", CHUNK_LEN)) {
            assertEqualChunkNum(integerType, constNode.node.typeChunk);
            assertEqualInt(123, constNode.defn.constant.value.integer);
        } else if (!strncmp(name, "ri", CHUNK_LEN)) {
            assertEqualChunkNum(realType, constNode.node.typeChunk);
            assertEqualFloat("3.14159", constNode.defn.constant.value.real);
        } else if (!strncmp(name, "cc", CHUNK_LEN)) {
            assertEqualChunkNum(charType, constNode.node.typeChunk);
            assertEqualByte('c', constNode.defn.constant.value.character);
        } else if (!strncmp(name, "sc", CHUNK_LEN)) {
            if (constNode.type.form != fcArray || constNode.type.array.elemType != charType) {
                printf("Expected const type to be character array\n");
                exit(5);
            }
            copyFromMemBuf(constNode.defn.constant.value.stringChunkNum, name, 0, CHUNK_LEN);
            if (strncmp(name, "Hello, World", CHUNK_LEN)) {
                printf("Expected const string to be \"Hello, World\"\n");
                exit(5);
            }
        }

        constId = constNode.node.nextNode;
    }
}
