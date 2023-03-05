#include <stdio.h>
#include "parsertest.h"
#include <tests.h>
#include <string.h>
#include <stdlib.h>

static CHUNKNUM testFuncBool(CHUNKNUM routineId);
static CHUNKNUM testFuncChar(CHUNKNUM routineId);
static CHUNKNUM testFuncEnum(CHUNKNUM routineId);
static CHUNKNUM testFuncInt(CHUNKNUM routineId);
static CHUNKNUM testFuncReal(CHUNKNUM routineId);
static CHUNKNUM testProc2(CHUNKNUM routineId);
static CHUNKNUM testScalar1(CHUNKNUM routineId);
static CHUNKNUM testVarEnum(CHUNKNUM routineId);
static CHUNKNUM testVarScalar(CHUNKNUM routineId);
static void testVarProc(CHUNKNUM routineId);

static CHUNKNUM testFuncBool(CHUNKNUM routineId) {
    CHUNKNUM nextNode;
    SYMBNODE node;

    DECLARE_TEST("testFuncBool");

    loadSymbNode(routineId, &node);
    nextNode = node.node.nextNode;
    assertEqualInt(dcFunction, node.defn.how);
    assertZero(strncmp("funcbool", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    assertEqualChunkNum(booleanType, node.node.typeChunk);

    loadSymbNode(node.defn.routine.locals.parmIds, &node);
    assertEqualInt(fcEnum, node.type.form);
    assertEqualChunkNum(booleanType, node.node.typeChunk);
    assertEqualInt(0, node.defn.data.offset);
    assertEqualInt(dcValueParm, node.defn.how);
    assertZero(strncmp("b", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    return nextNode;
}

static CHUNKNUM testFuncChar(CHUNKNUM routineId) {
    CHUNKNUM nextNode;
    SYMBNODE node;

    DECLARE_TEST("testFuncChar");

    loadSymbNode(routineId, &node);
    nextNode = node.node.nextNode;
    assertEqualInt(dcFunction, node.defn.how);
    assertZero(strncmp("funcchar", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    assertEqualChunkNum(charType, node.node.typeChunk);

    loadSymbNode(node.defn.routine.locals.parmIds, &node);
    assertEqualInt(fcScalar, node.type.form);
    assertEqualChunkNum(charType, node.node.typeChunk);
    assertEqualInt(0, node.defn.data.offset);
    assertEqualInt(dcValueParm, node.defn.how);
    assertZero(strncmp("c", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    return nextNode;
}

static CHUNKNUM testFuncEnum(CHUNKNUM routineId) {
    CHUNKNUM nextNode, parmId;
    SYMBNODE node;

    DECLARE_TEST("testFuncEnum");

    loadSymbNode(routineId, &node);
    parmId = node.defn.routine.locals.parmIds;
    nextNode = node.node.nextNode;
    assertEqualInt(dcFunction, node.defn.how);
    assertZero(strncmp("funcenum", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    loadSymbNode(node.type.typeId, &node);
    assertZero(strncmp("en", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    loadSymbNode(parmId, &node);
    assertEqualInt(fcEnum, node.type.form);
    assertEqualInt(0, node.defn.data.offset);
    assertEqualInt(dcValueParm, node.defn.how);
    assertZero(strncmp("e", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    loadSymbNode(node.type.typeId, &node);
    assertZero(strncmp("en", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    return nextNode;
}

static CHUNKNUM testFuncInt(CHUNKNUM routineId) {
    CHUNKNUM nextNode;
    SYMBNODE node;

    DECLARE_TEST("testFuncInt");

    loadSymbNode(routineId, &node);
    nextNode = node.node.nextNode;
    assertEqualInt(dcFunction, node.defn.how);
    assertZero(strncmp("funcint", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    assertEqualChunkNum(integerType, node.node.typeChunk);

    loadSymbNode(node.defn.routine.locals.parmIds, &node);
    assertEqualInt(fcScalar, node.type.form);
    assertEqualChunkNum(integerType, node.node.typeChunk);
    assertEqualInt(0, node.defn.data.offset);
    assertEqualInt(dcValueParm, node.defn.how);
    assertZero(strncmp("i", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    return nextNode;
}

static CHUNKNUM testFuncReal(CHUNKNUM routineId) {
    CHUNKNUM nextNode;
    SYMBNODE node;

    DECLARE_TEST("testFuncReal");

    loadSymbNode(routineId, &node);
    nextNode = node.node.nextNode;
    assertEqualInt(dcFunction, node.defn.how);
    assertZero(strncmp("funcreal", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    assertEqualChunkNum(realType, node.node.typeChunk);

    loadSymbNode(node.defn.routine.locals.parmIds, &node);
    assertEqualInt(fcScalar, node.type.form);
    assertEqualChunkNum(realType, node.node.typeChunk);
    assertEqualInt(0, node.defn.data.offset);
    assertEqualInt(dcValueParm, node.defn.how);
    assertZero(strncmp("r", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    return nextNode;
}

static CHUNKNUM testProc2(CHUNKNUM routineId) {
    int offset = 0;
    CHUNKNUM parmId, nextNode;
    SYMBNODE node;

    DECLARE_TEST("testProc2");

    loadSymbNode(routineId, &node);
    nextNode = node.node.nextNode;
    assertEqualInt(dcProcedure, node.defn.how);
    assertZero(strncmp("proc2", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    parmId = node.defn.routine.locals.parmIds;

    loadSymbNode(parmId, &node);
    parmId = node.node.nextNode;
    assertEqualInt(fcRecord, node.type.form);
    assertEqualInt(offset++, node.defn.data.offset);
    assertEqualInt(dcValueParm, node.defn.how);
    assertZero(strncmp("r", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    loadSymbNode(node.type.typeId, &node);
    assertZero(strncmp("rec", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    loadSymbNode(parmId, &node);
    parmId = node.node.nextNode;
    assertEqualInt(fcArray, node.type.form);
    assertEqualInt(offset++, node.defn.data.offset);
    assertEqualInt(dcValueParm, node.defn.how);
    assertZero(strncmp("a", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    loadSymbNode(node.type.typeId, &node);
    assertZero(strncmp("ar", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    loadSymbNode(parmId, &node);
    assertEqualInt(fcEnum, node.type.form);
    assertEqualInt(offset++, node.defn.data.offset);
    assertEqualInt(dcValueParm, node.defn.how);
    assertZero(strncmp("e", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    loadSymbNode(node.type.typeId, &node);
    assertZero(strncmp("en", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    return nextNode;
}

static CHUNKNUM testScalar1(CHUNKNUM routineId) {
    int offset = 0;
    CHUNKNUM parmId;
    SYMBNODE routineNode, parmNode;

    DECLARE_TEST("testScalar1");

    loadSymbNode(routineId, &routineNode);
    assertEqualInt(dcProcedure, routineNode.defn.how);
    assertZero(strncmp("scalar1", getChunk(routineNode.node.nameChunkNum), CHUNK_LEN));
    parmId = routineNode.defn.routine.locals.parmIds;

    loadSymbNode(parmId, &parmNode);
    assertEqualInt(fcScalar, parmNode.type.form);
    assertEqualChunkNum(integerType, parmNode.node.typeChunk);
    assertEqualInt(offset++, parmNode.defn.data.offset);
    assertEqualInt(dcValueParm, parmNode.defn.how);
    assertZero(strncmp("i", getChunk(parmNode.node.nameChunkNum), CHUNK_LEN));
    parmId = parmNode.node.nextNode;

    loadSymbNode(parmId, &parmNode);
    assertEqualInt(fcScalar, parmNode.type.form);
    assertEqualChunkNum(realType, parmNode.node.typeChunk);
    assertEqualInt(offset++, parmNode.defn.data.offset);
    assertEqualInt(dcValueParm, parmNode.defn.how);
    assertZero(strncmp("r", getChunk(parmNode.node.nameChunkNum), CHUNK_LEN));
    parmId = parmNode.node.nextNode;

    loadSymbNode(parmId, &parmNode);
    assertEqualInt(fcEnum, parmNode.type.form);
    assertEqualChunkNum(booleanType, parmNode.node.typeChunk);
    assertEqualInt(offset++, parmNode.defn.data.offset);
    assertEqualInt(dcValueParm, parmNode.defn.how);
    assertZero(strncmp("b", getChunk(parmNode.node.nameChunkNum), CHUNK_LEN));
    parmId = parmNode.node.nextNode;

    loadSymbNode(parmId, &parmNode);
    assertEqualInt(fcScalar, parmNode.type.form);
    assertEqualChunkNum(charType, parmNode.node.typeChunk);
    assertEqualInt(offset, parmNode.defn.data.offset);
    assertEqualInt(dcValueParm, parmNode.defn.how);
    assertZero(strncmp("c", getChunk(parmNode.node.nameChunkNum), CHUNK_LEN));

    return routineNode.node.nextNode;
}

static CHUNKNUM testVarEnum(CHUNKNUM routineId) {
    CHUNKNUM nextNode;
    SYMBNODE node;

    DECLARE_TEST("testVarEnum");

    loadSymbNode(routineId, &node);
    nextNode = node.node.nextNode;
    assertEqualInt(dcProcedure, node.defn.how);
    assertZero(strncmp("varenum", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    loadSymbNode(node.defn.routine.locals.parmIds, &node);
    assertEqualInt(fcEnum, node.type.form);
    assertEqualInt(0, node.defn.data.offset);
    assertEqualInt(dcVarParm, node.defn.how);
    assertZero(strncmp("e", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    loadSymbNode(node.type.typeId, &node);
    assertZero(strncmp("en", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    return nextNode;
}

static void testVarProc(CHUNKNUM routineId) {
    int offset = 0;
    CHUNKNUM parmId;
    SYMBNODE node;

    DECLARE_TEST("testVarProc");

    loadSymbNode(routineId, &node);
    assertEqualInt(dcProcedure, node.defn.how);
    assertZero(strncmp("varproc", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    parmId = node.defn.routine.locals.parmIds;

    loadSymbNode(parmId, &node);
    parmId = node.node.nextNode;
    assertEqualInt(fcArray, node.type.form);
    assertEqualInt(offset++, node.defn.data.offset);
    assertEqualInt(dcVarParm, node.defn.how);
    assertZero(strncmp("a", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    loadSymbNode(node.type.typeId, &node);
    assertZero(strncmp("ar", getChunk(node.node.nameChunkNum), CHUNK_LEN));

    loadSymbNode(parmId, &node);
    parmId = node.node.nextNode;
    assertEqualInt(fcRecord, node.type.form);
    assertEqualInt(offset, node.defn.data.offset);
    assertEqualInt(dcVarParm, node.defn.how);
    assertZero(strncmp("r", getChunk(node.node.nameChunkNum), CHUNK_LEN));
    loadSymbNode(node.type.typeId, &node);
    assertZero(strncmp("rec", getChunk(node.node.nameChunkNum), CHUNK_LEN));
}

static CHUNKNUM testVarScalar(CHUNKNUM routineId) {
    int offset = 0;
    CHUNKNUM parmId;
    SYMBNODE routineNode, parmNode;

    DECLARE_TEST("testVarScalar");

    loadSymbNode(routineId, &routineNode);
    assertEqualInt(dcProcedure, routineNode.defn.how);
    assertZero(strncmp("varscalar", getChunk(routineNode.node.nameChunkNum), CHUNK_LEN));
    parmId = routineNode.defn.routine.locals.parmIds;

    loadSymbNode(parmId, &parmNode);
    assertEqualInt(fcScalar, parmNode.type.form);
    assertEqualChunkNum(integerType, parmNode.node.typeChunk);
    assertEqualInt(offset++, parmNode.defn.data.offset);
    assertEqualInt(dcVarParm, parmNode.defn.how);
    assertZero(strncmp("i", getChunk(parmNode.node.nameChunkNum), CHUNK_LEN));
    parmId = parmNode.node.nextNode;

    loadSymbNode(parmId, &parmNode);
    assertEqualInt(fcScalar, parmNode.type.form);
    assertEqualChunkNum(realType, parmNode.node.typeChunk);
    assertEqualInt(offset++, parmNode.defn.data.offset);
    assertEqualInt(dcVarParm, parmNode.defn.how);
    assertZero(strncmp("r", getChunk(parmNode.node.nameChunkNum), CHUNK_LEN));
    parmId = parmNode.node.nextNode;

    loadSymbNode(parmId, &parmNode);
    assertEqualInt(fcEnum, parmNode.type.form);
    assertEqualChunkNum(booleanType, parmNode.node.typeChunk);
    assertEqualInt(offset++, parmNode.defn.data.offset);
    assertEqualInt(dcVarParm, parmNode.defn.how);
    assertZero(strncmp("b", getChunk(parmNode.node.nameChunkNum), CHUNK_LEN));
    parmId = parmNode.node.nextNode;

    loadSymbNode(parmId, &parmNode);
    assertEqualInt(fcScalar, parmNode.type.form);
    assertEqualChunkNum(charType, parmNode.node.typeChunk);
    assertEqualInt(offset, parmNode.defn.data.offset);
    assertEqualInt(dcVarParm, parmNode.defn.how);
    assertZero(strncmp("c", getChunk(parmNode.node.nameChunkNum), CHUNK_LEN));

    return routineNode.node.nextNode;
}

void routineTest(CHUNKNUM programId) {
    CHUNKNUM routineId;
    SYMBNODE programNode;

    loadSymbNode(programId, &programNode);
    routineId = programNode.defn.routine.locals.routineIds;

    routineId = testScalar1(routineId);
    routineId = testProc2(routineId);
    routineId = testFuncInt(routineId);
    routineId = testFuncReal(routineId);
    routineId = testFuncBool(routineId);
    routineId = testFuncChar(routineId);
    routineId = testFuncEnum(routineId);
    routineId = testVarScalar(routineId);
    routineId = testVarEnum(routineId);
    testVarProc(routineId);
}
