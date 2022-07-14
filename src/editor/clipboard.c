#include "editor.h"

#include <stdlib.h>
#include <string.h>

void editorCalcSelection() {
    int y;
    erow *row;

    if (!E.in_selection) return;

    if (E.cy < E.sy || (E.cy == E.sy && E.cx < E.sx)) {
        // The cursor is before the anchor point.
        // The cursor is the starting point of highlight
        // and the anchor point is the end.
        E.shx = E.cx;
        E.shy = E.cy;
        E.ehx = E.sx;
        E.ehy = E.sy;
    } else {
        // The cursor is after the anchor point.
        // The anchor point is the starting point of highlight
        // and the cursor is the end.
        E.shx = E.sx;
        E.shy = E.sy;
        E.ehx = E.cx;
        E.ehy = E.cy;
    }

    // Mark the highlighted rows

    // Start by un-marking rows before the starting and
    // after the ending row.
    if (E.last_shy != -1 && E.last_shy < E.shy) {
        for (y = E.last_shy; y < E.shy; ++y) {
            if (E.row[y].rev) memset(E.row[y].rev, 0, E.row[y].size);
            editorSetRowDirty(&E.row[y]);
        }
    }
    if (E.last_ehy > E.ehy) {
        for (y = E.ehy + 1; y <= E.last_ehy; ++y) {
            if (E.row[y].rev) memset(E.row[y].rev, 0, E.row[y].size);
            editorSetRowDirty(&E.row[y]);
        }
    }

    // Do the first selected row

    row = &E.row[E.shy];
    if (row->rev == NULL) row->rev = malloc(row->size);
    memset(row->rev, 0, row->size);
    memset(row->rev + E.shx, 128,
        E.shy == E.ehy ? E.ehx - E.shx + 1 : row->size - E.shx);
    editorSetRowDirty(&E.row[E.shy]);

    // Do the rows up through the last

    for (y = E.shy + 1; y <= E.ehy; ++y) {
        if (E.row[y].rev == NULL) E.row[y].rev = malloc(E.row[y].size);
        memset(E.row[y].rev, 128, E.row[y].size);
        editorSetRowDirty(&E.row[y]);
    }

    // Clear the highlight after the last selected character on the last line

    row = &E.row[E.ehy];
    y = row->size - E.ehx - 1;
    if (y > 0 && row->rev) memset(row->rev + E.ehx + 1, 0, y);
    editorSetRowDirty(&E.row[E.ehy]);

    // Finally, save this selection as the last selected

    E.last_shy = E.shy;
    E.last_ehy = E.ehy;
}

void editorClearSelection() {
    int y;
    for (y = E.shy; y <= E.ehy; ++y) {
        if (E.row[y].rev) memset(E.row[y].rev, 0, E.row[y].size);
        editorSetRowDirty(&E.row[y]);
    }

    E.in_selection = 0;
    E.sx = E.sy = 0;
    E.shx = E.shy = 0;
    E.ehx = E.ehy = 0;
    E.last_shy = E.last_ehy = -1;  // -1 means invalid value
}

// Copies the contents of the selected text
// to a buffer supplied by the caller.  If
// the selection continues to another line,
// a newline is placed in the buffer.

int editorCopyClipboard(char *buf) {
    int len = 0, x1, x2, y = E.shy;
    int boff = 0;  // buffer offset
    erow *row;

    do {
        row = &E.row[y];
        // If this is the first row of the selection
        // start counting at shx, otherwise start at
        // the first column.
        x1 = y == E.shy ? E.shx : 0;
        // If this is the last row of the selection
        // stop counting at ehx, otherwise stop at
        // the last column.
        x2 = y == E.ehy ? E.ehx : row->size;
        len += x2 - x1;
        // If the caller supplied a buffer, copy
        // the contents of this row into the buffer.
        if (buf) {
            memcpy(buf+boff, row->chars+x1, x2-x1);
            boff += x2 - x1;
            // Add a newline if this is not the last row
            // in the selection.
            if (y != E.ehy) buf[boff++] = '\n';
        }
        // Account for the newline if the selection
        // continues to the next row.
        len += y == E.ehy ? 0 : 1;
        y++;
    } while (y <= E.ehy);

    if (buf) buf[boff] = 0; 
    return len + 1;     // add one for the NULL terminator
}

void editorCopySelection() {
    int len = editorCopyClipboard(NULL);
    E.clipboard = realloc(E.clipboard, len);
    editorCopyClipboard(E.clipboard);
}

void editorDeleteSelection() {
    int y = E.ehy, x1, x2;
    erow *row;

    do {
        row = &E.row[y];
        // If this is the starting or ending row of the selection,
        // see if all or only part of the row is being deleted.
        if (y == E.shy || y == E.ehy) {
            x1 = y == E.shy && E.shx > 0 ? E.shx : 0;
            x2 = y == E.ehy && E.ehx < row->size ? E.ehx : row->size;
            if (x1 == 0 && x2 == row->size) {
                // delete the entire row
                editorDelRow(y);
            } else {
                editorRowDelChars(row, x1, x2 - x1);
                E.cx = E.shx;
            }
        } else {
            editorDelRow(y);
        }
        --y;
    } while (y >= E.shy);

    E.cy = E.shy;

    // If the last row was not completely deleted,
    // append the remainder to the row above.
    if (y > 0 && E.shy != E.ehy && E.ehx > 0 && E.ehx != E.row[y].size) {
        row = &E.row[E.shy+1];
        editorRowAppendString(&E.row[E.shy], row->chars, row->size);
        editorDelRow(E.shy+1);
    }
}

void editorPasteClipboard() {
    char *s = E.clipboard, *e;  // start and end of current line
    int x = E.cx, y = E.cy;
    erow *row;

    if (E.clipboard == NULL) return;

    // When the contents of the clipboard were copied, newline
    // characters were placed at new lines.  To paste, the loop
    // will iterate through the clipboard and when it sees a newline,
    // it inserts a new line into the file.

    while (*s) {
        row = &E.row[y];
        e = strchr(s, '\n');
        if (e == NULL) {
            // Last line in the clipboard.  Insert the remaining
            // characters and stop.
            editorRowInsertString(row, x-1, s, strlen(s));
            E.cx += strlen(s);
            break;
        }

        // editorRowInsertString(row, x, s, e-s);
        editorInsertRow(y++, s, e-s);
        E.cy++;
        s = e + 1;
    }
}

