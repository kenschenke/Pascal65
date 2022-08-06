#include <stdio.h>
#include <tests.h>
#include <editor.h>
#include <string.h>

#include "editortests.h"

static void testCharPosOutOfRange(void);
static void testInsertCharIntoLastChunk(void);
static void testInsertCharIntoMiddleChunk(void);
static void testInsertCharWithRoom(void);

void testEditorRowInsertChar(void) {
    testCharPosOutOfRange();
    testInsertCharWithRoom();
    testInsertCharIntoMiddleChunk();
    testInsertCharIntoLastChunk();
}

static void testCharPosOutOfRange(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testCharPosOutOfRange");

    setupTestData();

    // Passing a out of range character position just appends
    // the character to the end of the row.

    assertNonZero(retrieveChunk(E.cf->firstRowChunk, (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW, row.size);
    editorRowInsertChar(&row, -1, 'X');
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW-1],
        (unsigned char *)&chunk));
    assertEqualInt(TEST_CHUNK_LEN + 1, chunk.bytesUsed);
    assertEqualByte('X', chunk.bytes[chunk.bytesUsed-1]);

    assertNonZero(retrieveChunk(row.nextRowChunk, (unsigned char *)&row));
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW, row.size);
    editorRowInsertChar(&row, row.size + 1, 'X');
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

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    memcpy(chunk.bytes, "ABCDEFGHIJKLMNOPQRST", 20);
    chunk.bytesUsed = 20;
    assertNonZero(storeChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    editorRowInsertChar(&row, TEST_CHUNK_LEN * (TEST_CHUNKS_PER_ROW - 1) + 5, 'Z');
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

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][1], (unsigned char *)&chunk));
    memcpy(chunk.bytes, "ABCDEFGHIJKLMNOPQRST", 20);
    chunk.bytesUsed = 20;
    assertNonZero(storeChunk(textChunkNums[0][1], (unsigned char *)&chunk));
    editorRowInsertChar(&row, TEST_CHUNK_LEN + 5, 'Z');
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][1], (unsigned char *)&chunk));
    assertEqualInt(6, chunk.bytesUsed);
    assertZero(memcmp(chunk.bytes, "ABCDEZ", 6));
    assertNonZero(retrieveChunk(chunk.nextChunk, (unsigned char *)&chunk));
    assertEqualChunkNum(textChunkNums[0][2], chunk.nextChunk);
    assertEqualInt(15, chunk.bytesUsed);
    assertZero(memcmp(chunk.bytes, "FGHIJKLMNOPQRST", 15));
}

static void testInsertCharWithRoom(void) {
    erow row;
    echunk chunk;

    DECLARE_TEST("testInsertCharWithRoom");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    memcpy(chunk.bytes, "ABCDEFGHIJ", 10);
    chunk.bytesUsed = 10;
    assertNonZero(storeChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    editorRowInsertChar(&row, 5, 'Z');
    assertEqualInt(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + 1, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][0], (unsigned char *)&chunk));
    assertEqualInt(11, chunk.bytesUsed);
    assertZero(memcmp(chunk.bytes, "ABCDEZFGHIJ", 11));
}
