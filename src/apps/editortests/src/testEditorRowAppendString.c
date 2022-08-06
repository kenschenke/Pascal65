#include <stdio.h>
#include <tests.h>
#include <editor.h>
#include <string.h>

#include "editortests.h"

#define TEST_DATA "TESTSTR"
#define TEST_DATA_LEN 7

#define TEST_DATA_LONG "Lorem ipsum dolor sit amet, consectetur cras amet."
#define TEST_DATA_LONG_LEN 50

#if TEST_CHUNK_LEN + TEST_DATA_LEN > ECHUNK_LEN
#error "Test data too long"
#endif

static void testAppendWithEnoughSpace(void);
static void testAppendWithOverflow(void);

void testEditorRowAppendString(void) {
    testAppendWithEnoughSpace();
    testAppendWithOverflow();
}

static void testAppendWithEnoughSpace(void) {
    erow row;
    echunk chunk;
    char bytes[ECHUNK_LEN];

    DECLARE_TEST("testAppendWithEnoughSpace");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    memcpy(bytes, chunk.bytes, chunk.bytesUsed);
    memcpy(bytes + chunk.bytesUsed, TEST_DATA, TEST_DATA_LEN);
    editorRowAppendString(&row, bytes + TEST_CHUNK_LEN, TEST_DATA_LEN);
    assertEqualByte(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + TEST_DATA_LEN, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    assertEqualByte(TEST_CHUNK_LEN + TEST_DATA_LEN, chunk.bytesUsed);
    assertZero(memcmp(bytes, chunk.bytes, ECHUNK_LEN));
    assertEqualChunkNum(0, chunk.nextChunk);
}

static void testAppendWithOverflow(void) {
    erow row;
    echunk chunk;
    int offset, toCompare;
    char bytes[ECHUNK_LEN];

    DECLARE_TEST("testAppendWithOverflow");

    setupTestData();

    assertNonZero(retrieveChunk(rowChunkNums[0], (unsigned char *)&row));
    editorRowAppendString(&row, TEST_DATA_LONG, TEST_DATA_LONG_LEN);
    assertEqualByte(TEST_CHUNK_LEN * TEST_CHUNKS_PER_ROW + TEST_DATA_LONG_LEN, row.size);
    assertNonZero(retrieveChunk(textChunkNums[0][TEST_CHUNKS_PER_ROW - 1], (unsigned char *)&chunk));
    assertEqualByte(TEST_CHUNK_LEN, chunk.bytesUsed);

    offset = 0;
    while (offset < TEST_DATA_LONG_LEN) {
        assertNonZero(retrieveChunk(chunk.nextChunk, (unsigned char *)&chunk));
        toCompare = offset + ECHUNK_LEN < TEST_DATA_LONG_LEN ? ECHUNK_LEN : TEST_DATA_LONG_LEN - offset;
        assertEqualByte(toCompare, chunk.bytesUsed);
        assertZero(memcmp(TEST_DATA_LONG + offset, chunk.bytes, toCompare));
        offset += toCompare;
    }
    assertEqualChunkNum(0, chunk.nextChunk);
}
