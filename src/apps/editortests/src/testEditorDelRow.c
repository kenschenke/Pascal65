#include <tests.h>
#include <editor.h>
#include <stdio.h>

#include "editortests.h"

static void testDeleteFirstRow(void);
static void testDeleteLastRow(void);
static void testDeleteMiddleRow(void);
static void testRowNumberOutOfRange(void);

void testEditorDelRow(void) {
    printf("Running editorDelRow tests\n");

    testRowNumberOutOfRange();
    testDeleteFirstRow();
    testDeleteMiddleRow();
    testDeleteLastRow();
}

static void testDeleteFirstRow(void) {
    int i;
    erow row;
    echunk chunk;
    CHUNKNUM chunkNum;

    DECLARE_TEST("testDeleteFirstRow");

    setupTestData();

    editorDelRow(0);
    assertEqualInt(TEST_ROWS - 1, E.cf.numrows);
    assertEqualChunkNum(rowChunkNums[1], E.cf.firstRowChunk);

    for (i = 0; i < TEST_CHUNKS_PER_ROW; ++i) {
        assertZero(retrieveChunk(textChunkNums[0][i], (unsigned char *)&chunk));
    }

    chunkNum = E.cf.firstRowChunk;
    i = 0;
    while (chunkNum) {
        assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&row));
        assertEqualInt(i, row.idx);
        ++i;
        chunkNum = row.nextRowChunk;
    }
}

static void testDeleteLastRow(void) {
    int i;
    erow row;
    echunk chunk;
    CHUNKNUM chunkNum;

    DECLARE_TEST("testDeleteLastRow");

    setupTestData();

    editorDelRow(TEST_ROWS - 1);
    assertEqualInt(TEST_ROWS - 1, E.cf.numrows);

    retrieveChunk(rowChunkNums[3], (unsigned char *)&row);
    assertEqualInt(0, row.nextRowChunk);

    for (i = 0; i < TEST_CHUNKS_PER_ROW; ++i) {
        assertZero(retrieveChunk(textChunkNums[4][i], (unsigned char *)&chunk));
    }

    chunkNum = E.cf.firstRowChunk;
    i = 0;
    while (chunkNum) {
        assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&row));
        assertEqualInt(i, row.idx);
        ++i;
        chunkNum = row.nextRowChunk;
    }
}

static void testDeleteMiddleRow(void) {
    int i;
    erow row;
    echunk chunk;
    CHUNKNUM chunkNum;

    DECLARE_TEST("testDeleteMiddleRow");

    setupTestData();

    editorDelRow(2);
    assertEqualInt(TEST_ROWS - 1, E.cf.numrows);

    retrieveChunk(rowChunkNums[1], (unsigned char *)&row);
    assertEqualChunkNum(rowChunkNums[3], row.nextRowChunk);

    for (i = 0; i < TEST_CHUNKS_PER_ROW; ++i) {
        assertZero(retrieveChunk(textChunkNums[2][i], (unsigned char *)&chunk));
    }

    chunkNum = E.cf.firstRowChunk;
    i = 0;
    while (chunkNum) {
        assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&row));
        assertEqualInt(i, row.idx);
        ++i;
        chunkNum = row.nextRowChunk;
    }
}

static void testRowNumberOutOfRange(void) {
    DECLARE_TEST("testRowNumberOutOfRange");

    setupTestData();

    editorDelRow(-1);
    assertEqualInt(TEST_ROWS, E.cf.numrows);

    editorDelRow(TEST_ROWS);
    assertEqualInt(TEST_ROWS, E.cf.numrows);
}
