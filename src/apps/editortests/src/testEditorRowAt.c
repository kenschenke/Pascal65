#include <tests.h>
#include <editor.h>

#include "editortests.h"

static void testRowNumberOutOfRange(void);
static void testChunkRetrieval(void);

void testEditorRowAt(void) {
    testRowNumberOutOfRange();
    testChunkRetrieval();
}

static void testRowNumberOutOfRange(void) {
    erow row;
    
    DECLARE_TEST("testRowNumberOutOfRange");

    setupTestData();
    assertZero(editorRowAt(-1, &row));
    assertZero(editorRowAt(TEST_ROWS, &row));
}

static void testChunkRetrieval(void) {
    erow row;
    
    DECLARE_TEST("testChunkRetrieval");

    setupTestData();

    // Set the nextChunk for the first chunk to a bad value.
    assertNonZero(retrieveChunk(E.cf->firstRowChunk, (unsigned char *)&row));
    row.nextRowChunk = TO_BLOCK_AND_CHUNK(99, 5);
    assertNonZero(storeChunk(E.cf->firstRowChunk, (unsigned char *)&row));

    assertNonZero(editorRowAt(0, &row));    // this one should work
    assertEqualByte(0, row.idx);
    assertZero(editorRowAt(1, &row));       // this one should fail
}
