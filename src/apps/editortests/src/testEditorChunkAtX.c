#include <tests.h>
#include <editor.h>

#include "editortests.h"

static void testEmptyRow(void);
static void testFirstByteInChunk(void);
static void testLastByteInChunk(void);
static void testMiddleByteInChunk(void);
static void testRangeError(void);

void testEditorChunkAtX(void) {
    testRangeError();
    testEmptyRow();
    testFirstByteInChunk();
    testMiddleByteInChunk();
    testLastByteInChunk();
}

static void testEmptyRow(void) {
    erow row;
    int firstCol;
    CHUNKNUM chunkNum;
    echunk chunk;

    DECLARE_TEST("testEmptyRow");

    setupTestData();

    assertNonZero(editorRowAt(0, &row));

    row.firstTextChunk = 0;
    assertZero(editorChunkAtX(&row, 0, &firstCol, &chunkNum, &chunk));
}

static void testFirstByteInChunk(void) {
    erow row;
    int firstCol;
    CHUNKNUM chunkNum;
    echunk chunk;

    DECLARE_TEST("testFirstByteInChunk");

    setupTestData();

    assertNonZero(editorRowAt(3, &row));
    assertNonZero(editorChunkAtX(&row, TEST_CHUNK_LEN, &firstCol, &chunkNum, &chunk));
    assertEqualInt(TEST_CHUNK_LEN, firstCol);
    assertEqualByte(TEST_CHUNK_LEN, chunk.bytesUsed);
}

static void testLastByteInChunk(void) {
    erow row;
    int firstCol;
    CHUNKNUM chunkNum;
    echunk chunk;

    DECLARE_TEST("testLastByteInChunk");

    setupTestData();

    assertNonZero(editorRowAt(3, &row));
    assertNonZero(editorChunkAtX(&row, TEST_CHUNK_LEN * 3 - 1, &firstCol, &chunkNum, &chunk));
    assertEqualInt(TEST_CHUNK_LEN * 2, firstCol);
    assertEqualByte(TEST_CHUNK_LEN, chunk.bytesUsed);
}

static void testMiddleByteInChunk(void) {
    erow row;
    int firstCol;
    CHUNKNUM chunkNum;
    echunk chunk;

    DECLARE_TEST("testMiddleByteInChunk");

    setupTestData();

    assertNonZero(editorRowAt(3, &row));
    assertNonZero(editorChunkAtX(&row, 5, &firstCol, &chunkNum, &chunk));
    assertEqualChunkNum(row.firstTextChunk, chunkNum);
    assertEqualInt(0, firstCol);
    assertEqualByte(TEST_CHUNK_LEN, chunk.bytesUsed);
}

static void testRangeError(void) {
    erow row;
    int firstCol;
    CHUNKNUM chunkNum;
    echunk chunk;

    DECLARE_TEST("testRangeError");

    setupTestData();

    assertNonZero(editorRowAt(0, &row));
    assertZero(editorChunkAtX(&row, -1, &firstCol, &chunkNum, &chunk));
    assertZero(editorChunkAtX(&row, row.size + 1, &firstCol, &chunkNum, &chunk));
}
