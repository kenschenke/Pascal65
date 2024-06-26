#include <stdio.h>
#include <tests.h>
#include <editor.h>
#include <string.h>

#include "editortests.h"

static void testCharPosOutOfRange(void);
static void testInsertCharIntoLastChunk(void);
static void testInsertCharIntoMiddleChunk(void);
static void testInsertCharWithRoom(void);
static void testInsertCharWithNoRoom(void);

void testEditorRowInsertChar(void) {
    printf("Running editorRowInsertChar tests\n");

    testCharPosOutOfRange();
    testInsertCharWithRoom();
    testInsertCharIntoMiddleChunk();
    testInsertCharIntoLastChunk();
    testInsertCharWithNoRoom();
}

static void testCharPosOutOfRange(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testCharPosOutOfRange");

    setupTestData();

    // Passing a out of range character position just appends
    // the character to the end of the row.

    E.cf.cy = 0;
    assertNonZero(retrieveChunk(E.cf.firstRowChunk, (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW, row.size);
    editorRowInsertChar(-1, 'X');
    assertNonZero(retrieveChunk(E.cf.firstRowChunk, (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW-1],
        (unsigned char *)&chunk));
    assertEqualInt(TEST_CHUNK_LEN + 1, chunk.bytesUsed);
    assertEqualByte('X', chunk.bytes[chunk.bytesUsed-1]);

    E.cf.cy = 1;
    assertNonZero(retrieveChunk(row.nextRowChunk, (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW, row.size);
    editorRowInsertChar(row.size + 1, 'X');
    assertNonZero(retrieveChunk(row.rowChunk, (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[1][TEST_CHUNKS_PER_ROW-1],
        (unsigned char *)&chunk));
    assertEqualInt(TEST_CHUNK_LEN + 1, chunk.bytesUsed);
    assertEqualByte('X', chunk.bytes[chunk.bytesUsed-1]);
}

static void testInsertCharIntoLastChunk(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testInsertCharIntoLastChunk");

    setupTestData();

    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    memcpy(chunk.bytes, "ABCDEFGHIJKLMNOPQRST", 20);
    chunk.bytesUsed = 20;
    assertNonZero(storeChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    editorRowInsertChar(TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1) + 5, 'Z');
    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    assertEqualInt(6, chunk.bytesUsed);
    assertZero(memcmp(chunk.bytes, "ABCDEZ", 6));
    assertNonZero(retrieveChunk(chunk.nextChunk, (unsigned char *)&chunk));
    assertZero(chunk.nextChunk);
    assertEqualInt(15, chunk.bytesUsed);
    assertZero(memcmp(chunk.bytes, "FGHIJKLMNOPQRST", 15));
}

static void testInsertCharIntoMiddleChunk(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testInsertCharIntoMiddleChunk");

    setupTestData();

    assertNonZero(retrieveChunk(textChunkNums[0][1], (unsigned char *)&chunk));
    memcpy(chunk.bytes, "ABCDEFGHIJKLMNOPQRST", 20);
    chunk.bytesUsed = 20;
    assertNonZero(storeChunk(textChunkNums[0][1], (unsigned char *)&chunk));
    editorRowInsertChar(TEST_CHUNK_LEN + 5, 'Z');
    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][1], (unsigned char *)&chunk));
    assertEqualInt(6, chunk.bytesUsed);
    assertZero(memcmp(chunk.bytes, "ABCDEZ", 6));
    assertNonZero(retrieveChunk(chunk.nextChunk, (unsigned char *)&chunk));
    assertEqualChunkNum(textChunkNums[0][2], chunk.nextChunk);
    assertEqualInt(15, chunk.bytesUsed);
    assertZero(memcmp(chunk.bytes, "FGHIJKLMNOPQRST", 15));
}

static void testInsertCharWithNoRoom(void) {
    erow row;
    echunk chunk;
    char bytes[ECHUNK_LEN];

    DECLARE_TEST("testInsertCharWithNoRoom");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    memset(chunk.bytes, 'X', ECHUNK_LEN);
    chunk.bytesUsed = ECHUNK_LEN;
    assertNonZero(storeChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    row.size = TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1) + ECHUNK_LEN;
    assertNonZero(storeChunk(rowChunkNums[0], (unsigned char *)&row));
    editorRowInsertChar(row.size, 'X');
    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1) + ECHUNK_LEN + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    assertNonZero(retrieveChunk(chunk.nextChunk, (unsigned char *)&chunk));
    assertEqualByte(1, chunk.bytesUsed);
    assertEqualByte('X', chunk.bytes[0]);
}

static void testInsertCharWithRoom(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testInsertCharWithRoom");

    setupTestData();

    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    memcpy(chunk.bytes, "ABCDEFGHIJ", 10);
    chunk.bytesUsed = 10;
    assertNonZero(storeChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    editorRowInsertChar(5, 'Z');
    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    assertEqualInt(11, chunk.bytesUsed);
    assertZero(memcmp(chunk.bytes, "ABCDEZFGHIJ", 11));
}
