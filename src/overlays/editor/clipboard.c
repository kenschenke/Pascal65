#include <editor.h>
#include <membuf.h>
#include <string.h>

extern char editBuf[80];

/*
    Six values control text selection, copy, and cutting.  All six are stored in
    a selection struct, which is attached to an open file.  Those values are:

    selectionX/Y  The cursor X/Y position when selection is turned on.  The
                  code refers to this as the anchor point.
    startHX/Y     The X/Y position of the start of the selected region.
    endHX/Y       The X/Y position of the end of the selected region.

    selectionX/Y are set when the user turns on selection and do not change.
    startHX/Y and endHX/Y change as the user moves the cursor.  
*/

void editorCalcSelection(void)
{
    if (!E.cf.inSelection) return;

    if (E.cf.cy < E.selection.selectionY ||
        (E.cf.cy == E.selection.selectionY && E.cf.cx < E.selection.selectionX)) {
        // The cursor is before the anchor point.
        // The cursor is the starting point of highlight
        // and the anchor point is the end.
        E.selection.startHX = E.cf.cx;
        E.selection.startHY = E.cf.cy;
        E.selection.endHX = E.selection.selectionX;
        E.selection.endHY = E.selection.selectionY;
    } else {
        // The cursor is after the anchor point.
        // The anchor point is the starting point of highlight
        // and the cursor is the end.
        E.selection.startHX = E.selection.selectionX;
        E.selection.startHY = E.selection.selectionY;
        E.selection.endHX = E.cf.cx;
        E.selection.endHY = E.cf.cy;
    }
    // If the last character of selection is in the first column, do not include the
    // first character of that line.
    if (E.selection.endHX == 0) {
        erow row;
        --E.selection.endHY;
        editorRowAt(E.selection.endHY, &row);
        E.selection.endHX = row.size - 1;
    }

    editorSetAllRowsDirty();
}

void editorClearSelection(void)
{
    E.cf.inSelection = 0;
    E.selection.selectionX = E.selection.selectionY = 0;
    E.selection.startHX = E.selection.startHY = 0;
    E.selection.endHX = E.selection.endHY = 0;

    editorSetAllRowsDirty();
}

void editorCopySelection(void)
{
    int x1, x2, y;
    char newline = '\n';
    erow row;

    // First, clear the clipboard (if any contents)
    if (E.clipboard) {
        freeMemBuf(E.clipboard);
    }

    // Allocate a new memory buffer for the clipboard
    allocMemBuf(&E.clipboard);

    // Copy text into the clipboard
    editorRowAt(E.selection.startHY, &row);
    for (y = E.selection.startHY; y <= E.selection.endHY; ++y) {
        // If this is the first row of the selection, start at startHX,
        // otherwise start at the first column
        x1 = y == E.selection.startHY ? E.selection.startHX : 0;
        // If this is the last row of the selection, stop counting at
        // endHX, otherwise stop at the last column
        x2 = y == E.selection.endHY ? E.selection.endHX : row.size - 1;
        editBufPopulate(row.firstTextChunk);
        writeToMemBuf(E.clipboard, editBuf+x1, x2-x1+1);
        // If this is not the last row, write a newline.
        // Also write a newline if the entire row is being copied.
        if (y < E.selection.endHY || x1 == 0 && x2 == row.size - 1) {
            writeToMemBuf(E.clipboard, &newline, 1);
        }
        if (row.nextRowChunk) {
            retrieveChunk(row.nextRowChunk, &row);
        } else {
            break;
        }
    }
}

void editorDeleteSelection(void)
{
    int y = E.selection.endHY, x1, x2;
    erow row;

    clearCursor();

    do {
        editorRowAt(y, &row);
        // If this is the starting or ending row of the selection,
        // see if all or only part of the row is being deleted.
        if (y == E.selection.startHY || y == E.selection.endHY) {
            x1 = y == E.selection.startHY && E.selection.startHX > 0 ? E.selection.startHX : 0;
            x2 = y == E.selection.endHY && E.selection.endHX < row.size - 1 ? E.selection.endHX : row.size - 1;
            if (x1 == 0 && x2 == row.size - 1) {
                // delete the entire row
                editorDelRow(y);
            } else {
                editBufPopulate(row.firstTextChunk);
                editBufDeleteChars(x1, x2-x1+1, row.size);
                row.size -= x2 - x1 + 1;
                editBufFlush(&row.firstTextChunk, row.size);
                storeChunk(row.rowChunk, &row);
            }
        } else {
            editorDelRow(y);
        }
        --y;
    } while (y >= E.selection.startHY);

    // If the last row was not completely deleted,
    // append the remainder to the row above.
    editorRowAt(E.selection.startHY, &row);
    if (E.selection.startHY != E.selection.endHY &&
        E.selection.endHX > 0 && E.selection.endHX != row.size - 1) {
        char buf[80];
        int size;
        editorRowAt(E.selection.startHY+1, &row);
        size = row.size;
        editBufPopulate(row.firstTextChunk);
        memcpy(buf, editBuf, size);
        editorRowAt(E.selection.startHY, &row);
        editBufPopulate(row.firstTextChunk);
        memcpy(editBuf+row.size, buf, size);
        row.size += size;
        editBufFlush(&row.firstTextChunk, row.size);
        storeChunk(row.rowChunk, &row);
        editorDelRow(E.selection.startHY+1);
    }

    E.cf.cx = E.selection.startHX;
    E.cf.cy = E.selection.startHY;
}

void editorPasteClipboard(void)
{
    char c;
    erow row;
    char buf[80];
    int bufsize;

    if (E.clipboard == 0) {
        return;
    }

    // When the contents of the clipboard were copied, newline characters
    // were placed at new lines.  To paste, loop through the clipboard and
    // when a newline character is found, insert a new line into the file.

    setMemBufPos(E.clipboard, 0);
    clearCursor();

    if (E.cf.cy == E.cf.numrows) {
        // The cursor is at the end of the file on a non-existant row.
        // Create an empty row.
        editorInsertRow(E.cf.numrows, "", 0);
    }
    editorRowAt(E.cf.cy, &row);

    editBufPopulate(row.firstTextChunk);
    while (!isMemBufAtEnd(E.clipboard)) {
        readFromMemBuf(E.clipboard, &c, 1);
        if (c == '\n') {
            if (E.cf.cx < row.size) {
                bufsize = row.size - E.cf.cx;
                memcpy(buf, editBuf+E.cf.cx, bufsize);
                row.size -= bufsize;
            } else {
                bufsize = 0;
            }
            editBufFlush(&row.firstTextChunk, row.size);
            row.dirty = 1;
            storeChunk(row.rowChunk, &row);
            editorInsertRow(++E.cf.cy, buf, bufsize);
            editorRowAt(E.cf.cy, &row);
            editBufPopulate(row.firstTextChunk);
            E.cf.cx = 0;
        } else {
            editBufInsertChar(c, row.size++, E.cf.cx++);
        }
    }

    editBufFlush(&row.firstTextChunk, row.size);
    row.dirty = 1;
    storeChunk(row.rowChunk, &row);
    E.anyDirtyRows = 1;
}
