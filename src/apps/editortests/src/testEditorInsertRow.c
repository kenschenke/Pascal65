#include <tests.h>
#include <editor.h>
#include <string.h>

#include "editortests.h"

static void testInsertFirstRow(void);
static void testInsertLastRow(void);
static void testInsertMiddleRow(void);
static void testRowNumberOutOfRange(void);

void testEditorInsertRow(void) {
    testRowNumberOutOfRange();
    testInsertFirstRow();
    testInsertMiddleRow();
    testInsertLastRow();
}

static void testInsertFirstRow(void) {
    int i;
    erow row;
    CHUNKNUM chunkNum;

    DECLARE_TEST("testInsertFirstRow");

    setupTestData();

    editorInsertRow(0, "", 0);
    assertEqualInt(TEST_ROWS + 1, E.cf->numrows);
    assertNonZero(retrieveChunk(E.cf->firstRowChunk, (unsigned char *)&row));
    assertZero(row.size);

    chunkNum = E.cf->firstRowChunk;
    i = 0;
    while (chunkNum) {
        assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&row));
        assertEqualInt(i, row.idx);
        ++i;
        chunkNum = row.nextRowChunk;
    }
}

static void testInsertLastRow(void) {
    int i;
    erow row;
    CHUNKNUM chunkNum;

    DECLARE_TEST("testInsertLastRow");

    setupTestData();

    editorInsertRow(TEST_ROWS, "", 0);
    assertEqualInt(TEST_ROWS + 1, E.cf->numrows);
    assertNonZero(retrieveChunk(rowChunkNums[4], (unsigned char *)&row));
    assertNonZero(retrieveChunk(row.nextRowChunk, (unsigned char *)&row));
    assertZero(row.size);

    chunkNum = E.cf->firstRowChunk;
    i = 0;
    while (chunkNum) {
        assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&row));
        assertEqualInt(i, row.idx);
        ++i;
        chunkNum = row.nextRowChunk;
    }
}

static void testInsertMiddleRow(void) {
    int i;
    erow row;
    CHUNKNUM chunkNum;

    DECLARE_TEST("testInsertMiddleRow");

    setupTestData();

    editorInsertRow(2, "", 0);
    assertEqualInt(TEST_ROWS + 1, E.cf->numrows);
    assertNonZero(retrieveChunk(rowChunkNums[1], (unsigned char *)&row));
    assertNonZero(retrieveChunk(row.nextRowChunk, (unsigned char *)&row));
    assertZero(row.size);

    chunkNum = E.cf->firstRowChunk;
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

    editorInsertRow(-1, "", 0);
    assertEqualInt(TEST_ROWS, E.cf->numrows);

    editorInsertRow(E.cf->numrows + 1, "", 0);
    assertEqualInt(TEST_ROWS, E.cf->numrows);
}
