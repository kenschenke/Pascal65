#include "editor.h"

#include <conio.h>
#include <stdlib.h>
#include <string.h>

void editorFindCallback(char *query, int key) {
    static int last_match = -1;
    static int direction = 1;

    static int saved_rev_line;
    static unsigned char *saved_rev = NULL;

    int current, i;
    erow *row;
    char *match;

    if (saved_rev) {
        memcpy(E.cf->row[saved_rev_line].rev, saved_rev, E.cf->row[saved_rev_line].size);
        free(saved_rev);
        saved_rev = NULL;
        editorSetAllRowsDirty();
    }

    if (key == '\r' || key == '\x1b') {
        last_match = -1;
        direction = 1;
        return;
    } else if (key == CH_CURS_RIGHT || key == CH_CURS_DOWN) {
        direction = 1;
    } else if (key == CH_CURS_LEFT || key == CH_CURS_UP) {
        direction = -1;
    } else {
        direction = 1;
        last_match = -1;
    }

    if (last_match == -1) direction = 1;
    current = last_match;
    for (i = 0; i < E.cf->numrows; ++i) {
        current += direction;
        if (current == -1) current = E.cf->numrows - 1;
        else if (current == E.cf->numrows) current = 0;

        row = &E.cf->row[current];
        match = strstr(row->chars, query);
        if (match) {
            last_match = current;
            E.cf->cy = current;
            E.cf->cx = match - row->chars;
            E.cf->rowoff = E.cf->numrows;

            if (!row->rev) {
                row->rev = malloc(row->size);
                memset(row->rev, 0, row->size);
            }
            saved_rev_line = current;
            saved_rev = malloc(row->size);
            memcpy(saved_rev, row->rev, row->size);
            memset(&row->rev[match - row->chars], 128, strlen(query));
            editorSetRowDirty(row);
            break;
        }
    }
}

void editorFind() {
    int saved_cx = E.cf->cx;
    int saved_cy = E.cf->cy;
    int saved_coloff = E.cf->coloff;
    int saved_rowoff = E.cf->rowoff;

    char *query = editorPrompt("Search: %s (Use ESC/Arrows/Enter)",
        editorFindCallback);
    if (query) {
        free(query);
    } else {
        E.cf->cx = saved_cx;
        E.cf->cy = saved_cy;
        E.cf->coloff = saved_coloff;
        E.cf->rowoff = saved_rowoff;
    }
}

