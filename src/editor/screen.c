#include "editor.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>

#define KILO_VERSION "0.0.1"

void __fastcall__ clearScreen80(void);
void __fastcall__ initScreen80(void);
void __fastcall__ setScreenBg80(char bg);
void __fastcall__ drawRow80(char row, char len,
    char *buf, unsigned char *rev);

void __fastcall__ clearScreen40(void);
void __fastcall__ initScreen40(void);
void __fastcall__ setScreenBg40(char bg);
void __fastcall__ drawRow40(char row, char len,
    char *buf, unsigned char *rev);

static void freeWelcomePage(char **rows, int numRows);
static void prepWelcomePage(char ***rows, int *numRows);

void clearScreen(void) {
    if (E.screencols == 40)
        clearScreen40();
    else
        clearScreen80();
}

void drawRow(char row, char len, char *buf, unsigned char *rev) {
    if (E.screencols == 40)
        drawRow40(row, len, buf, rev);
    else
        drawRow80(row, len, buf, rev);
}

static void freeWelcomePage(char **rows, int numRows) {
    int i;

    for (i = 0; i < numRows; ++i) {
        free(rows[i]);
    }
    free(rows);
}

static void prepWelcomePage(char ***rows, int *numRows) {
    char **r;
    char *p = E.welcomePage, *n;
    int len, num;

    r = NULL;
    num = 0;

    while (1) {
        n = strchr(p, '\r');
        len = n == NULL ? strlen(p) : n - p;
        if (len > E.screencols) len = E.screencols;
        r = realloc(r, sizeof(char *) * (num+1));
        r[num] = malloc(len + 1);
        memcpy(r[num], p, len);
        r[num][len] = '\0';
        ++num;
        if (n == NULL) {
            break;
        }
        p = n + 1;
    }

    *rows = r;
    *numRows = num;
}

void initScreen(void) {
    if (E.screencols == 40)
        initScreen40();
    else
        initScreen80();
}

void setScreenBg(char bg) {
    if (E.screencols == 40)
        setScreenBg40(bg);
    else
        setScreenBg80(bg);
}

void editorScroll() {
    int willScroll = 0;

    if (E.cy < E.rowoff) {
        E.rowoff = E.cy;
        willScroll = 1;
    }
    if (E.cy >= E.rowoff + E.screenrows) {
        E.rowoff = E.cy - E.screenrows + 1;
        willScroll = 1;
    }
    if (E.cx < E.coloff) {
        E.coloff = E.cx;
        willScroll = 1;
    }
    if (E.cx >= E.coloff + E.screencols) {
        E.coloff = E.cx - E.screencols + 1;
        willScroll = 1;
    }

    if (willScroll) {
        editorSetAllRowsDirty();
    }
}

void editorDrawRows(void) {
    int y, padding;

#if 1
    if (E.numrows == 0) {
        char **rows, *buffer;
        int i, numRows, x, y;

        prepWelcomePage(&rows, &numRows);
        y = (E.screenrows - numRows) / 2;
        for (i = 0; i < y; ++i) {
            drawRow(i, 0, "", NULL);
        }
        buffer = malloc(E.screencols + 1);
        for (i = 0; i < numRows; ++i, ++y) {
            x = (E.screencols - strlen(rows[i])) / 2;
            if (x < 0) x = 0;
            if (x > 0) memset(buffer, ' ', x);
            strcpy(buffer + x, rows[i]);
            drawRow(y, strlen(buffer), buffer, NULL);
        }

        free(buffer);
        freeWelcomePage(rows, numRows);

        return;
    }
#endif

    for (y = 0; y < E.screenrows; y++) {
        int filerow = y + E.rowoff;
        if (filerow >= E.numrows) {
            if (E.numrows == 0 && y == E.screenrows / 3) {
                char welcome[80], *banner, *p;
                int buflen;
                int welcomelen = snprintf(welcome, sizeof(welcome),
                "Kilo editor -- version %s", KILO_VERSION);
                if (welcomelen > E.screencols) welcomelen = E.screencols;
                padding = (E.screencols - welcomelen) / 2;
                buflen = welcomelen + padding;
                banner = malloc(buflen);
                p = banner;
                while (padding--) *p++ = ' ';
                memcpy(p, welcome, welcomelen);
                drawRow(y, buflen, banner, NULL);
                free(banner);
            }
        } else if (E.dirtyScreenRows[y]) {
            int len = E.row[filerow].size - E.coloff;
            if (len < 0) len = 0;
            if (len > E.screencols) len = E.screencols;
            drawRow(y, len, &E.row[filerow].chars[E.coloff],
                E.row[filerow].rev ? &E.row[filerow].rev[E.coloff] : NULL);
            E.dirtyScreenRows[y] = 0;
        }
    }
}

void editorDrawStatusBar() {
    char status[80], rstatus[80];
    int len, rlen;

    memset(E.statusbar, ' ', E.screencols);

    len = snprintf(status, sizeof(status), "%.20s - %d lines%s%s",
        E.filename ? E.filename : "[No Name]", E.numrows,
        E.dirty ? " (modified)" : "",
        E.readOnly ? " (read only)" : "");
#ifdef SYNTAX_HIGHLIGHT
    rlen = snprintf(rstatus, sizeof(rstatus), "%s | %d/%d",
        E.syntax ? E.syntax->filetype : "no ft", E.cy + 1, E.numrows);
#else
    rlen = snprintf(rstatus, sizeof(rstatus), "%d/%d", E.cy + 1, E.numrows);
#endif
    if (len > E.screencols) len = E.screencols;
    memcpy(E.statusbar, status, len);
    memcpy(E.statusbar + E.screencols - rlen, rstatus, rlen);

    drawRow(E.screenrows, E.screencols, E.statusbar, E.statusbarrev);
}

void editorDrawMessageBar(void) {
    unsigned char *rev;
    int msglen = strlen(E.statusmsg);

    if (!E.statusmsg_dirty && E.statusmsg_time == 0) return;

    if (msglen > E.screencols) msglen = E.screencols;
    if (msglen && time(NULL) - E.statusmsg_time < 5) {
        rev = malloc(msglen);
        memset(rev, 0, msglen);
        drawRow(E.screenrows+1, msglen, E.statusmsg, rev);
        free(rev);
    } else {
        rev = malloc(E.screencols);
        memset(rev, 0, E.screencols);
        memset(E.statusmsg, ' ', E.screencols);
        drawRow(E.screenrows+1, E.screencols, E.statusmsg, rev);
        free(rev);
        E.statusmsg_time = 0;
    }
    
    E.statusmsg_dirty = 0;
}

void editorRefreshScreen(void) {
    cursor(0);  // turn cursor off during drawing

    editorScroll();

    editorDrawRows();
    editorDrawStatusBar();
    editorDrawMessageBar();

    cursor(1);  // turn the cursor back on
    gotoxy(E.cx - E.coloff, E.cy - E.rowoff);
}

void editorSetStatusMessage(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(E.statusmsg, sizeof(E.statusmsg), fmt, ap);
    va_end(ap);
    E.statusmsg_time = time(NULL);
    E.statusmsg_dirty = 1;
}

