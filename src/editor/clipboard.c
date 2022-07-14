#include "editor.h"

#include <stdlib.h>
#include <string.h>

void editorCalcSelection() {
    int y;
    erow *row;

    if (!E.cf->in_selection) return;

    if (E.cf->cy < E.cf->sy || (E.cf->cy == E.cf->sy && E.cf->cx < E.cf->sx)) {
        // The cursor is before the anchor point.
        // The cursor is the starting point of highlight
        // and the anchor point is the end.
        E.cf->shx = E.cf->cx;
        E.cf->shy = E.cf->cy;
        E.cf->ehx = E.cf->sx;
        E.cf->ehy = E.cf->sy;
    } else {
        // The cursor is after the anchor point.
        // The anchor point is the starting point of highlight
        // and the cursor is the end.
        E.cf->shx = E.cf->sx;
        E.cf->shy = E.cf->sy;
        E.cf->ehx = E.cf->cx;
        E.cf->ehy = E.cf->cy;
    }

    // Mark the highlighted rows

    // Start by un-marking rows before the starting and
    // after the ending row.
    if (E.cf->last_shy != -1 && E.cf->last_shy < E.cf->shy) {
        for (y = E.cf->last_shy; y < E.cf->shy; ++y) {
            if (E.cf->row[y].rev) memset(E.cf->row[y].rev, 0, E.cf->row[y].size);
            editorSetRowDirty(&E.cf->row[y]);
        }
    }
    if (E.cf->last_ehy > E.cf->ehy) {
        for (y = E.cf->ehy + 1; y <= E.cf->last_ehy; ++y) {
            if (E.cf->row[y].rev) memset(E.cf->row[y].rev, 0, E.cf->row[y].size);
            editorSetRowDirty(&E.cf->row[y]);
        }
    }

    // Do the first selected row

    row = &E.cf->row[E.cf->shy];
    if (row->rev == NULL) row->rev = malloc(row->size);
    memset(row->rev, 0, row->size);
    memset(row->rev + E.cf->shx, 128,
        E.cf->shy == E.cf->ehy ? E.cf->ehx - E.cf->shx + 1 : row->size - E.cf->shx);
    editorSetRowDirty(&E.cf->row[E.cf->shy]);

    // Do the rows up through the last

    for (y = E.cf->shy + 1; y <= E.cf->ehy; ++y) {
        if (E.cf->row[y].rev == NULL) E.cf->row[y].rev = malloc(E.cf->row[y].size);
        memset(E.cf->row[y].rev, 128, E.cf->row[y].size);
        editorSetRowDirty(&E.cf->row[y]);
    }

    // Clear the highlight after the last selected character on the last line

    row = &E.cf->row[E.cf->ehy];
    y = row->size - E.cf->ehx - 1;
    if (y > 0 && row->rev) memset(row->rev + E.cf->ehx + 1, 0, y);
    editorSetRowDirty(&E.cf->row[E.cf->ehy]);

    // Finally, save this selection as the last selected

    E.cf->last_shy = E.cf->shy;
    E.cf->last_ehy = E.cf->ehy;
}

void editorClearSelection() {
    int y;
    for (y = E.cf->shy; y <= E.cf->ehy; ++y) {
        if (E.cf->row[y].rev) memset(E.cf->row[y].rev, 0, E.cf->row[y].size);
        editorSetRowDirty(&E.cf->row[y]);
    }

    E.cf->in_selection = 0;
    E.cf->sx = E.cf->sy = 0;
    E.cf->shx = E.cf->shy = 0;
    E.cf->ehx = E.cf->ehy = 0;
    E.cf->last_shy = E.cf->last_ehy = -1;  // -1 means invalid value
}

// Copies the contents of the selected text
// to a buffer supplied by the caller.  If
// the selection continues to another line,
// a newline is placed in the buffer.

int editorCopyClipboard(char *buf) {
    int len = 0, x1, x2, y = E.cf->shy;
    int boff = 0;  // buffer offset
    erow *row;

    do {
        row = &E.cf->row[y];
        // If this is the first row of the selection
        // start counting at shx, otherwise start at
        // the first column.
        x1 = y == E.cf->shy ? E.cf->shx : 0;
        // If this is the last row of the selection
        // stop counting at ehx, otherwise stop at
        // the last column.
        x2 = y == E.cf->ehy ? E.cf->ehx : row->size;
        len += x2 - x1;
        // If the caller supplied a buffer, copy
        // the contents of this row into the buffer.
        if (buf) {
            memcpy(buf+boff, row->chars+x1, x2-x1);
            boff += x2 - x1;
            // Add a newline if this is not the last row
            // in the selection.
            if (y != E.cf->ehy) buf[boff++] = '\n';
        }
        // Account for the newline if the selection
        // continues to the next row.
        len += y == E.cf->ehy ? 0 : 1;
        y++;
    } while (y <= E.cf->ehy);

    if (buf) buf[boff] = 0; 
    return len + 1;     // add one for the NULL terminator
}

void editorCopySelection() {
    int len = editorCopyClipboard(NULL);
    E.clipboard = realloc(E.clipboard, len);
    editorCopyClipboard(E.clipboard);
}

void editorDeleteSelection() {
    int y = E.cf->ehy, x1, x2;
    erow *row;

    do {
        row = &E.cf->row[y];
        // If this is the starting or ending row of the selection,
        // see if all or only part of the row is being deleted.
        if (y == E.cf->shy || y == E.cf->ehy) {
            x1 = y == E.cf->shy && E.cf->shx > 0 ? E.cf->shx : 0;
            x2 = y == E.cf->ehy && E.cf->ehx < row->size ? E.cf->ehx : row->size;
            if (x1 == 0 && x2 == row->size) {
                // delete the entire row
                editorDelRow(y);
            } else {
                editorRowDelChars(row, x1, x2 - x1);
                E.cf->cx = E.cf->shx;
            }
        } else {
            editorDelRow(y);
        }
        --y;
    } while (y >= E.cf->shy);

    E.cf->cy = E.cf->shy;

    // If the last row was not completely deleted,
    // append the remainder to the row above.
    if (y > 0 && E.cf->shy != E.cf->ehy && E.cf->ehx > 0 && E.cf->ehx != E.cf->row[y].size) {
        row = &E.cf->row[E.cf->shy+1];
        editorRowAppendString(&E.cf->row[E.cf->shy], row->chars, row->size);
        editorDelRow(E.cf->shy+1);
    }
}

void editorPasteClipboard() {
    char *s = E.clipboard, *e;  // start and end of current line
    int x = E.cf->cx, y = E.cf->cy;
    erow *row;

    if (E.clipboard == NULL) return;

    // When the contents of the clipboard were copied, newline
    // characters were placed at new lines.  To paste, the loop
    // will iterate through the clipboard and when it sees a newline,
    // it inserts a new line into the file.

    while (*s) {
        row = &E.cf->row[y];
        e = strchr(s, '\n');
        if (e == NULL) {
            // Last line in the clipboard.  Insert the remaining
            // characters and stop.
            editorRowInsertString(row, x-1, s, strlen(s));
            E.cf->cx += strlen(s);
            break;
        }

        // editorRowInsertString(row, x, s, e-s);
        editorInsertRow(y++, s, e-s);
        E.cf->cy++;
        s = e + 1;
    }
}

