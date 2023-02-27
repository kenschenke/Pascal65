#include <stdio.h>
#include "parsertest.h"
#include <tests.h>
#include <string.h>
#include <stdlib.h>

static char isTypeEn(SYMBNODE *pNode);
static void testAnonRec(SYMBNODE *pNode);
static void testArrayOfScalarRec(SYMBNODE *pNode);
static void testArrayRec(SYMBNODE *pNode);
static void testNestedAnonRec(SYMBNODE *pNode);
static void testNestedRec(SYMBNODE *pNode);
static void testRecordDefs(CHUNKNUM variableIds);
static void testScalarRec(SYMBNODE *pNode);

static char isTypeEn(SYMBNODE *pNode) {
    char name[CHUNK_LEN];
    TTYPE typeNode;
    SYMTABNODE enNode;

    retrieveChunk(pNode->node.typeChunk, (unsigned char *)&typeNode);
    retrieveChunk(pNode->type.typeId, (unsigned char *)&enNode);
    retrieveChunk(enNode.nameChunkNum, (unsigned char *)name);
    return (strlen(name) == 2 && name[0] == 'e' && name[1] == 'n') ? 1 : 0;
}

static void testAnonRec(SYMBNODE *pNode) {
    int i = 0, offset = 0;
    char names[] = {'f', 't'};
    char types[] = {BOOLEAN_TYPE, REAL_TYPE};
    int sizes[] = {2, 4};
    char name[CHUNK_LEN];
    CHUNKNUM nodeId;
    SYMBNODE node;
    SYMTAB symtab;

    DECLARE_TEST("testAnonRec");

    retrieveChunk(pNode->type.record.symtab, (unsigned char *)&symtab);
    nodeId = symtab.rootChunkNum;
    while (nodeId) {
        assertNonZero(i < 5);

        loadSymbNode(nodeId, &node);

        retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
        assertEqualInt(1, strlen(name));
        assertEqualByte(names[i], name[0]);
        assertEqualInt(offset, node.defn.data.offset);

        assertEqualChunkNum(getTypeFromDefine(types[i]), node.node.typeChunk);

        offset += sizes[i];

        ++i;
        nodeId = node.node.nextNode;
    }
}

static void testArrayOfScalarRec(SYMBNODE *pNode) {
    SYMBNODE node;
    char name[CHUNK_LEN];
    TTYPE elemType;

    DECLARE_TEST("testArrayOfScalarRec");

    assertEqualInt(fcArray, pNode->type.form);
    assertEqualInt(0, pNode->type.array.minIndex);
    assertEqualInt(5, pNode->type.array.maxIndex);
    assertEqualInt(6, pNode->type.array.elemCount);

    retrieveChunk(pNode->type.array.elemType, (unsigned char *)&elemType);
    loadSymbNode(elemType.typeId, &node);
    assertEqualInt(fcRecord, node.type.form);
    retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
    assertZero(strncmp(name, "scalarrec", CHUNK_LEN));
    testScalarRec(&node);

    assertZero(pNode->node.nextNode);
}

static void testArrayRec(SYMBNODE *pNode) {
    char name[CHUNK_LEN];
    SYMTAB symtab;
    SYMBNODE node;
    TTYPE indexType;

    DECLARE_TEST("testArrayRec");

    retrieveChunk(pNode->type.record.symtab, (unsigned char *)&symtab);
    loadSymbNode(symtab.rootChunkNum, &node);

    retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
    assertEqualInt(1, strlen(name));
    assertEqualByte('a', name[0]);
    assertEqualInt(fcArray, node.type.form);
    assertEqualChunkNum(integerType, node.type.array.elemType);
    assertEqualInt(1, node.type.array.minIndex);
    assertEqualInt(10, node.type.array.maxIndex);
    assertEqualInt(10, node.type.array.elemCount);

    retrieveChunk(node.type.array.indexType, (unsigned char *)&indexType);
    assertEqualInt(fcSubrange, indexType.form);
    assertEqualChunkNum(integerType, indexType.subrange.baseType);
    assertEqualInt(1, indexType.subrange.min);
    assertEqualInt(10, indexType.subrange.max);

    assertZero(node.node.nextNode);
}

static void testNestedAnonRec(SYMBNODE *pNode) {
    char name[CHUNK_LEN];
    SYMTAB symtab;
    SYMBNODE node;

    DECLARE_TEST("testNestedAnonRec");

    retrieveChunk(pNode->type.record.symtab, (unsigned char *)&symtab);
    loadSymbNode(symtab.rootChunkNum, &node);

    retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
    assertEqualInt(1, strlen(name));
    assertEqualByte('k', name[0]);
    assertEqualChunkNum(integerType, node.node.typeChunk);

    loadSymbNode(node.node.nextNode, &node);
    retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
    assertEqualInt(1, strlen(name));
    assertEqualByte('d', name[0]);
    assertEqualInt(fcRecord, node.type.form);
    testAnonRec(&node);

    assertZero(node.node.nextNode);
}

static void testNestedRec(SYMBNODE *pNode) {
    char name[CHUNK_LEN];
    SYMTAB symtab;
    SYMTABNODE typeNode;
    SYMBNODE node;

    DECLARE_TEST("testNestedRec");

    retrieveChunk(pNode->type.record.symtab, (unsigned char *)&symtab);
    loadSymbNode(symtab.rootChunkNum, &node);

    retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
    assertEqualInt(1, strlen(name));
    assertEqualByte('j', name[0]);
    assertEqualChunkNum(integerType, node.node.typeChunk);

    loadSymbNode(node.node.nextNode, &node);
    assertEqualInt(fcRecord, node.type.form);
    retrieveChunk(node.type.typeId, (unsigned char *)&typeNode);
    retrieveChunk(typeNode.nameChunkNum, (unsigned char *)name);
    assertZero(strncmp(name, "scalarrec", CHUNK_LEN));

    assertZero(node.node.nextNode);
}

static void testRecordDefs(CHUNKNUM typeIds) {
    char name[CHUNK_LEN];
    SYMBNODE node;
    CHUNKNUM typeId = typeIds;

    while (typeId) {
        loadSymbNode(typeId, &node);

        retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
        if (!strncmp(name, "scalarrec", CHUNK_LEN)) {
            testScalarRec(&node);
        } else if (!strncmp(name, "arrayrec", CHUNK_LEN)) {
            testArrayRec(&node);
        } else if (!strncmp(name, "nestedrec", CHUNK_LEN)) {
            testNestedRec(&node);
        } else if (!strncmp(name, "nestedanonrec", CHUNK_LEN)) {
            testNestedAnonRec(&node);
        } else if (!strncmp(name, "ar", CHUNK_LEN)) {
            testArrayOfScalarRec(&node);
        }

        // printf("%.22s\n", name);

        typeId = node.node.nextNode;
    }
}

static void testScalarRec(SYMBNODE *pNode) {
    int i = 0, offset = 0;
    char names[] = {'b', 'c', 'e', 'i', 'r'};
    char types[] = {BOOLEAN_TYPE, CHAR_TYPE, EN_TYPE, INTEGER_TYPE, REAL_TYPE};
    int sizes[] = {2, 1, 2, 2, 4};
    char name[CHUNK_LEN];
    CHUNKNUM nodeId, typeId;
    SYMBNODE node;
    SYMTAB symtab;

    DECLARE_TEST("testScalarRec");

    retrieveChunk(pNode->type.record.symtab, (unsigned char *)&symtab);
    nodeId = symtab.rootChunkNum;
    while (nodeId) {
        assertNonZero(i < 5);

        loadSymbNode(nodeId, &node);

        retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
        assertEqualInt(1, strlen(name));
        assertEqualByte(names[i], name[0]);
        assertEqualInt(offset, node.defn.data.offset);

        if (types[i] == EN_TYPE) {
            typeId = node.node.typeChunk;
            assertNonZero(isTypeEn(&node));
        } else {
            typeId = getTypeFromDefine(types[i]);
        }

        assertEqualChunkNum(typeId, node.node.typeChunk);

        offset += sizes[i];

        ++i;
        nodeId = node.node.nextNode;
    }
}

void recordTest(CHUNKNUM programId) {
    SYMBNODE programNode;

    loadSymbNode(programId, &programNode);
    testIcode = programNode.defn.routine.Icode;
    setMemBufPos(testIcode, 0);
    runIcodeTests("recordtest.txt", 36, "recordIcodeTests");

    testRecordDefs(programNode.defn.routine.locals.typeIds);
}
