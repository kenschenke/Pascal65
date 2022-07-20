#include "editor.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void editorFreeRow(erow *row);
void editorUpdateRow(erow *row);

/*** row operations ***/

void editorUpdateRow(erow *row) {
    int tabs = 0;
    int j, idx;
    char *buf;

    for (j = 0; j < row->size; ++j) {
        if (row->chars[j] == '\t') tabs++;
    }

    buf = malloc(row->size + tabs*(EDITOR_TAB_STOP-1) + 1);

    idx = 0;
    for (j = 0; j < row->size; ++j) {
        if (row->chars[j] == '\t') {
            buf[idx++] = ' ';
            while (idx % EDITOR_TAB_STOP != 0) buf[idx++] = ' ';
        } else {
            buf[idx++] = row->chars[j];
        }
    }
    buf[idx] = '\0';

    row->chars = realloc(row->chars, idx);
    memcpy(row->chars, buf, idx);

#ifdef SYNTAX_HIGHLIGHT
    editorUpdateSyntax(row);
#endif
}

void editorDeleteToStartOfLine() {
    erow *row = &E.cf->row[E.cf->cy];
    int pos = E.cf->cx;
    if (pos < 0 || pos >= row->size) {
        pos = 0;
    }

    memmove(row->chars, &row->chars[pos], row->size - pos);
    row->size -= pos;
    E.cf->cx = 0;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.cf->dirty++;
}

void editorDeleteToEndOfLine() {
    erow *row = &E.cf->row[E.cf->cy];
    int pos = E.cf->cx;
    if (pos < 0 || pos >= row->size) {
        pos = row->size - 1;
    }

    row->size = pos;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.cf->dirty++;
}

void editorInsertRow(int at, char *s, size_t len) {
    int j;

    if (at < 0 || at > E.cf->numrows) return;
    
    E.cf->row = realloc(E.cf->row, sizeof(erow) * (E.cf->numrows + 1));
    memmove(&E.cf->row[at + 1], &E.cf->row[at], sizeof(erow) * (E.cf->numrows - at));
    for (j = at + 1; j < E.cf->numrows; ++j) {
        E.cf->row[j].idx++;
        editorSetRowDirty(&E.cf->row[j]);
    }

    E.cf->row[at].idx = at;

    E.cf->row[at].size = len;
    E.cf->row[at].chars = malloc(len + 1);
    memcpy(E.cf->row[at].chars, s, len);
    E.cf->row[at].chars[len] = '\0';

    E.cf->row[at].rev = NULL;

#ifdef SYNTAX_HIGHLIGHT
    E.cf->row[at].hl = NULL;
    E.cf->row[at].hl_open_comment = 0;
#endif
    editorSetRowDirty(&E.cf->row[at]);
    editorUpdateRow(&E.cf->row[at]);

    if (E.cf->numrows == 0) {
        for (j = 0; j < E.screenrows; ++j) {
            drawRow(j, 0, "", NULL);
        }
    }

    E.cf->numrows++;
    E.cf->dirty++;
}

static void editorFreeRow(erow *row) {
    free(row->chars);
    free(row->rev);
#ifdef SYNTAX_HIGHLIGHT
    free(row->hl);
#endif
}

void editorDelRow(int at) {
    int j;

    if (at < 0 || at >= E.cf->numrows) return;
    editorFreeRow(&E.cf->row[at]);
    memmove(&E.cf->row[at], &E.cf->row[at + 1], sizeof(erow) * (E.cf->numrows - at  - 1));
    for (j = at; j < E.cf->numrows - 1; j++) {
        E.cf->row[j].idx--;
        editorSetRowDirty(&E.cf->row[j]);
    }
    E.cf->numrows--;
    E.cf->dirty++;
}

void editorRowInsertChar(erow *row, int at, int c) {
    if (at < 0 || at > row->size) at = row->size;
    row->chars = realloc(row->chars, row->size + 2);
    row->rev = realloc(row->rev, row->size + 1);
    memset(row->rev, 0, row->size + 1);
    memmove(&row->chars[at + 1], &row->chars[at], row->size - at + 1);
    row->size++;
    row->chars[at] = c;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.cf->dirty++;
}

void editorRowInsertString(erow *row, int at, char *s, size_t len) {
    row->chars = realloc(row->chars, row->size + len + 1);
    row->rev = realloc(row->rev, row->size + len);
    memset(row->rev, 0, row->size + len);
    memmove(&row->chars[at + len], &row->chars[at], row->size - at + 1);
    memcpy(&row->chars[at + 1], s, len);
    row->size += len;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.cf->dirty++;
}

void editorRowAppendString(erow *row, char *s, size_t len) {
    row->chars = realloc(row->chars, row->size + len + 1);
    row->rev = realloc(row->rev, row->size + len);
    memset(row->rev, 0, row->size + len);
    memcpy(&row->chars[row->size], s, len);
    row->size += len;
    row->chars[row->size] = '\0';
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.cf->dirty++;
}

void editorRowDelChars(erow *row, int at, int length) {
    if (at < 0 || at + length - 1 >= row->size) return;
    memmove(&row->chars[at], &row->chars[at + length], row->size - at - length);
    row->size -= length;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.cf->dirty++;
}

void editorSetAllRowsDirty() {
    int i;
    for (i = 0; i < E.screenrows; ++i) E.cf->dirtyScreenRows[i] = 1;
}

void editorSetRowDirty(erow *row) {
    int i = row->idx - E.cf->rowoff;
    if (i < 0 || i >= E.screenrows) {
        // row is not visible - ignore
        return;
    }

    E.cf->dirtyScreenRows[i] = 1;
}

