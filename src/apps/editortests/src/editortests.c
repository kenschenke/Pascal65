#include "editortests.h"
#include "editor.h"

#include <stdio.h>
#include <string.h>
#include <chunks.h>

CHUNKNUM rowChunkNums[TEST_ROWS];
CHUNKNUM textChunkNums[TEST_ROWS][TEST_CHUNKS_PER_ROW];

void setupTestData(void) {
    int i, j, n;
    echunk chunk;
    erow row;
    CHUNKNUM rowChunk, textChunk;
    char buf[15];

    initFile(&E.cf);

    initBlockStorage();

    // Create five rows of text
    for (i = TEST_ROWS; i >= 1; --i) {
        allocChunk(&rowChunk);
        rowChunkNums[i - 1] = rowChunk;

        row.idx = i - 1;
        row.size = 0;
        row.rowChunk = rowChunk;
        row.firstTextChunk = 0;

        for (j = 5; j >= 1; --j) {
            allocChunk(&textChunk);
            textChunkNums[i - 1][j - 1] = textChunk;
            n = snprintf(buf, sizeof(buf), "test row %d,%d ", i, j);
            memcpy(chunk.bytes, buf, n);
            chunk.bytesUsed = n;
            chunk.nextChunk = row.firstTextChunk;
            row.size += n;
            row.firstTextChunk = textChunk;
            storeChunk(textChunk, (unsigned char *)&chunk);
        }

        row.nextRowChunk = E.cf.firstRowChunk;
        E.cf.firstRowChunk = rowChunk;
        E.cf.numrows++;
        storeChunk(rowChunk, (unsigned char *)&row);
    }
}
