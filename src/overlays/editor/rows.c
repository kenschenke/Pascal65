/**
 * rows.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to modify rows.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include "editor.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <chunks.h>

void editorFreeRow(CHUNKNUM firstTextChunk);

char editorRowAt(int at, erow *row) {
    CHUNKNUM c;
    int j;

    c = E.cf.firstRowChunk;
    j = 0;
    while (c) {
        if (retrieveChunk(c, (unsigned char *)row) == 0) {
            return 0;
        }
        if (j == at) {
            return 1;
        }
        c = row->nextRowChunk;
        ++j;
    }

    return 0;
}

char editorChunkAtX(erow *row, int at, int *chunkFirstCol, CHUNKNUM *chunkNum, echunk *chunk) {
    *chunkNum = row->firstTextChunk;
    *chunkFirstCol = 0;

    if (*chunkNum == 0 || at < 0 || at > row->size) {
        return 0;
    }

    while (*chunkNum) {
        if (retrieveChunk(*chunkNum, (unsigned char *)chunk) == 0) {
            break;
        }

        if (at < chunk->bytesUsed) {
            break;
        }

        if (chunk->nextChunk == 0) {
            return 0;
        }

        *chunkNum = chunk->nextChunk;
        at -= chunk->bytesUsed;
        *chunkFirstCol += chunk->bytesUsed;
    }

    return 1;
}

// Returns NULL if the row has no text chunks.
char editorRowLastChunk(erow *row, CHUNKNUM *chunkNum, echunk *chunk) {
    *chunkNum = row->firstTextChunk;

    if (*chunkNum == 0) {
        return 0;
    }

    while (1) {
        if (retrieveChunk(*chunkNum, (unsigned char *)chunk) == 0) {
            return 0;
        }
        if (chunk->nextChunk == 0) {
            break;
        }

        *chunkNum = chunk->nextChunk;
    }

    return 1;
}

/*** row operations ***/

void editorDeleteToStartOfLine() {
#if 0
    if (E.cf.cx > 0) {
        editorRowDelChars(0, E.cf.cx);
        E.cf.cx = 0;
    }
#endif
}

void editorDeleteToEndOfLine() {
#if 0
    erow row;
    editorRowAt(E.cf.cy, &row);

    if (E.cf.cx < row.size) {
        editorRowDelChars(E.cf.cx, row.size - E.cf.cx);
    }
#endif
}

void editorInsertRow(int at, char *s, size_t len) {
    int j;
    erow newRow, curRow;
    CHUNKNUM newRowChunk, curChunk;

    if (at < 0 || at > E.cf.numrows) return;

    if (allocChunk(&newRowChunk) == 0) {
        return;
    }
    newRow.rowChunk = newRowChunk;
    newRow.idx = at;
    newRow.size = 0;   // this is set later when the text is added
    newRow.firstTextChunk = 0;
    newRow.nextRowChunk = 0;

    // If the new row will be the first row, that's handled differently.

    if (at == 0) {
        newRow.nextRowChunk = E.cf.firstRowChunk;
        E.cf.firstRowChunk = newRowChunk;
    } else {
        // Iterate through the rows until we get to the point of insertion.

        curChunk = E.cf.firstRowChunk;
        j = 0;
        while (1) {
            retrieveChunk(curChunk, (unsigned char *)&curRow);
            if (j + 1 == at) {
                newRow.nextRowChunk = curRow.nextRowChunk;
                curRow.nextRowChunk = newRowChunk;
                storeChunk(curChunk, (unsigned char *)&curRow);
                break;
            }
            curChunk = curRow.nextRowChunk;
            ++j;
        }

    }

    // Iterate through the remainder of the rows, adjusting the row numbers
    curChunk = newRow.nextRowChunk;
    while(curChunk) {
        retrieveChunk(curChunk, (unsigned char *)&curRow);
        curRow.idx++;
        editorSetRowDirty(&curRow);
        curChunk = curRow.nextRowChunk;
    }

    E.cf.numrows++;
    E.cf.dirty = 1;
    E.anyDirtyRows = 1;
    updateStatusBarFilename();

    editorRowAppendString(&newRow, s, len);
    storeChunk(newRowChunk, (unsigned char *)&newRow);
}

void editorFreeRow(CHUNKNUM firstTextChunk) {
    CHUNKNUM currChunk, nextChunk;
    echunk chunk;

    currChunk = firstTextChunk;
    while (currChunk) {
        retrieveChunk(currChunk, (unsigned char *)&chunk);
        nextChunk = chunk.nextChunk;
        freeChunk(currChunk);
        currChunk = nextChunk;
    }
}

void editorDelRow(int at) {
    int j;
    erow row, prevRow;
    CHUNKNUM rowChunk, firstTextChunk;

    if (at < 0 || at >= E.cf.numrows) return;

    // Find the row
    if (at == 0) {
        // First row
        rowChunk = E.cf.firstRowChunk;
        retrieveChunk(rowChunk, (unsigned char *)&row);  // retrieve the row
        firstTextChunk = row.firstTextChunk;    // save for later
        E.cf.firstRowChunk = row.nextRowChunk; // set the new first row
    } else {
        editorRowAt(at - 1, &prevRow);          // look up the previous row
        rowChunk = prevRow.nextRowChunk;        // save the chunknum for later
        retrieveChunk(rowChunk, (unsigned char *)&row);
        firstTextChunk = row.firstTextChunk;    // remember for later
        prevRow.nextRowChunk = row.nextRowChunk;
        storeChunk(prevRow.rowChunk, (unsigned char *)&prevRow);
    }

    editorFreeRow(firstTextChunk);
    freeChunk(rowChunk);

    // Make rows dirty
    rowChunk = E.cf.firstRowChunk;
    j = 0;
    while (rowChunk) {
        retrieveChunk(rowChunk, (unsigned char *)&row);
        if (j >= at) {
            row.idx--;
            storeChunk(rowChunk, (unsigned char *)&row);
            editorSetRowDirty(&row);
        }
        rowChunk = row.nextRowChunk;
        ++j;
    }

    E.cf.numrows--;
    E.cf.dirty = 1;
    updateStatusBarFilename();
}

void editorRowAppendString(erow *row, char *s, size_t len) {
    CHUNKNUM curChunk, newChunkNum;
    echunk chunk, newChunk;
    size_t toCopy;

    row->size += len;
    editorSetRowDirty(row);

    // Get the last chunk for the row
    editorRowLastChunk(row, &curChunk, &chunk);

    // If enough room left in the last chunk stuff the bytes there.
    if (curChunk && chunk.bytesUsed + len <= ECHUNK_LEN) {
        memcpy(chunk.bytes + chunk.bytesUsed, s, len);
        chunk.bytesUsed += len;
        storeChunk(curChunk, (unsigned char *)&chunk);
        return;
    }

    // Add chunks to the line until all the bytes are stored

    while (len) {
        allocChunk(&newChunkNum);
        newChunk.nextChunk = 0;
        toCopy = len > ECHUNK_LEN ? ECHUNK_LEN : len;
        memcpy(newChunk.bytes, s, toCopy);
        newChunk.bytesUsed = toCopy;

        if (curChunk == 0) {
            // This is the first text chunk for this row
            row->firstTextChunk = newChunkNum;
            storeChunk(row->rowChunk, (unsigned char *)row);
        } else {
            chunk.nextChunk = newChunkNum;
            storeChunk(curChunk, (unsigned char *)&chunk);
        }

        s += toCopy;
        len -= toCopy;
        curChunk = newChunkNum;
        storeChunk(newChunkNum, (unsigned char *)&newChunk);
        memcpy(&chunk, &newChunk, CHUNK_LEN);
    }

    E.cf.dirty = 1;
    updateStatusBarFilename();
}

void editorSetAllRowsDirty() {
    erow row;
    CHUNKNUM chunkNum = E.cf.firstRowChunk;

    while (chunkNum) {
        retrieveChunk(chunkNum, (unsigned char *)&row);
        row.dirty = 1;
        storeChunk(chunkNum, (unsigned char *)&row);
        chunkNum = row.nextRowChunk;
    }

    E.anyDirtyRows = 1;
}

void editorSetRowDirty(erow *row) {
    row->dirty = 1;
    storeChunk(row->rowChunk, (unsigned char *)row);
}

