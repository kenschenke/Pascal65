#include <stdio.h>
#include <tests.h>
#include <editor.h>
#include <string.h>

#include "editortests.h"

static void testCharPosOutOfRange(void);
static void testDeleteFirstCharInChunk(void);
static void testDeleteLastCharInChunk(void);
static void testDeleteMiddleCharInChunk(void);
static void testDeleteOnlyCharInFirstChunk(void);
static void testDeleteOnlyCharInMiddleChunk(void);

void testEditorRowDelChars(void) {
    testCharPosOutOfRange();
    testDeleteOnlyCharInFirstChunk();
    testDeleteOnlyCharInMiddleChunk();
    testDeleteLastCharInChunk();
    testDeleteMiddleCharInChunk();
    testDeleteFirstCharInChunk();
}

static void testCharPosOutOfRange(void) {
    erow row;

    DECLARE_TEST("testCharPosOutOfRange");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    editorRowDelChars(&row, -1, 1);
    assertEqualByte(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW, row.size);
    editorRowDelChars(&row, row.size - 1, 2);
    assertEqualByte(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW, row.size);
}

static void testDeleteFirstCharInChunk(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testDeleteFirstCharInChunk");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    memcpy(chunk.bytes, "ABCDEFGHIJ", 10);
    chunk.bytesUsed = 10;
    assertNonZero(storeChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    row.size = 10 + TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1);
    assertNonZero(storeChunk(rowChunkNums[0], (unsigned char *)&row));
    editorRowDelChars(&row, 0, 1);
    assertEqualInt(9 + TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1), row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    assertEqualByte(9, chunk.bytesUsed);
    assertZero(memcmp("BCDEFGHIJ", chunk.bytes, 9));
}

static void testDeleteLastCharInChunk(void) {
    erow row;
    echunk chunk;
    char bytes[TEST_CHUNK_LEN];

    DECLARE_TEST("testDeleteLastCharInChunk");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    memcpy(bytes, chunk.bytes, TEST_CHUNK_LEN);
    editorRowDelChars(&row, TEST_CHUNK_LEN - 1, 1);
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW - 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    assertEqualByte(TEST_CHUNK_LEN - 1, chunk.bytesUsed);
    assertZero(memcmp(bytes, chunk.bytes, TEST_CHUNK_LEN - 1));
}

static void testDeleteMiddleCharInChunk(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testDeleteMiddleCharInChunk");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    memcpy(chunk.bytes, "ABCDEFGHIJ", 10);
    chunk.bytesUsed = 10;
    assertNonZero(storeChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    row.size = 10 + TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1);
    assertNonZero(storeChunk(rowChunkNums[0], (unsigned char *)&row));
    editorRowDelChars(&row, 5, 1);
    assertEqualInt(9 + TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1), row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    assertEqualByte(9, chunk.bytesUsed);
    assertZero(memcmp("ABCDEGHIJ", chunk.bytes, 9));
}

static void testDeleteOnlyCharInFirstChunk(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testDeleteOnlyCharInFirstChunk");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    chunk.bytesUsed = 1;
    assertNonZero(storeChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    row.size = TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1) + 1;
    assertNonZero(storeChunk(rowChunkNums[0], (unsigned char *)&row));
    editorRowDelChars(&row, 0, 1);
    assertEqualInt(TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1), row.size);
    assertEqualChunkNum(textChunkNums[0][1], row.firstTextChunk);
    assertZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
}

static void testDeleteOnlyCharInMiddleChunk(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testDeleteOnlyCharInMiddleChunk");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][2], (unsigned char *)&chunk));
    chunk.bytesUsed = 1;
    assertNonZero(storeChunk(textChunkNums[0][2], (unsigned char *)&chunk));
    row.size = TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1) + 1;
    assertNonZero(storeChunk(rowChunkNums[0], (unsigned char *)&row));
    editorRowDelChars(&row, TEST_CHUNK_LEN * 2, 1);
    assertEqualInt(TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1), row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][1], (unsigned char *)&chunk));
    assertEqualChunkNum(textChunkNums[0][3], chunk.nextChunk);
    assertZero(retrieveChunk(textChunkNums[0][2], (unsigned char *)&chunk));
}
