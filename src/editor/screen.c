#include "editor.h"

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>
#include <chunks.h>

#ifdef __MEGA65__
#include <cbm.h>
#endif

#define KILO_VERSION "0.0.1"

#ifdef __C128__
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
#endif

static void editorDrawMessageBar(void);
static void editorDrawRows(void);
static void editorDrawStatusBar(void);
static void editorScroll(void);
static void freeWelcomePage(char **rows, int numRows);
static void prepWelcomePage(char ***rows, int *numRows);
static void setCursor(unsigned char value, unsigned char color);

#ifdef __MEGA65__
static void clearRow(char row, char startingCol);
static void drawRow65(char row, char col, char len, char *buf, char isReversed);

char * SCREEN = (char*)0x0800;
#endif

void clearScreen(void) {
#ifdef __MEGA65__
    clrscr();
#else
    if (E.screencols == 40)
        clearScreen40();
    else
        clearScreen80();
#endif
}

#ifdef __MEGA65__
static void clearRow(char row, char startingCol) {
    int offset = row * E.screencols + startingCol;
    memset(SCREEN+offset, ' ', E.screencols-startingCol);
}

static void drawRow65(char row, char col, char len, char *buf, char isReversed) {
    char i;
    int offset = row * E.screencols + col;
    for (i = 0; i < len; ++i) {
        SCREEN[offset++] = petsciitoscreencode(buf[i]) | (isReversed ? 128 : 0);
    }
}

void clearCursor(void) {
    setCursor(1, COLOUR_WHITE);
}

void renderCursor(void) {
    setCursor(0, COLOUR_ORANGE);
}

static void setCursor(unsigned char clear, unsigned char color) {
    unsigned int offset;

    offset = (E.cf->cy - E.cf->rowoff) * E.screencols + E.cf->cx - E.cf->coloff;
    if (clear) {
        SCREEN[offset] &= 0x7f;
    } else {
        SCREEN[offset] |= 0x80;
    }
    cellcolor(E.cf->cx - E.cf->coloff, E.cf->cy - E.cf->rowoff, color);
}
#else
void clearCursor(void) {}
#endif

void drawRow(char row, char col, char len, char *buf, char isReversed) {
#ifdef __MEGA65__
    drawRow65(row, col, len, buf, isReversed);
#else
    if (E.screencols == 40)
        drawRow40(row, len, buf, NULL);
    else
        drawRow80(row, len, buf, NULL);
#endif
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
#ifdef __MEGA65__
    conioinit();
    clearScreen();
#else
    if (E.screencols == 40)
        initScreen40();
    else
        initScreen80();
#endif
}

#ifdef __C128__
void setScreenBg(char bg) {
    if (E.screencols == 40)
        setScreenBg40(bg);
    else
        setScreenBg80(bg);
}
#endif

static void editorScroll(void) {
    int willScroll = 0;

    if (E.cf->cy < E.cf->rowoff) {
        E.cf->rowoff = E.cf->cy;
        willScroll = 1;
    }
    if (E.cf->cy >= E.cf->rowoff + E.screenrows) {
        E.cf->rowoff = E.cf->cy - E.screenrows + 1;
        willScroll = 1;
    }
    if (E.cf->cx < E.cf->coloff) {
        E.cf->coloff = E.cf->cx;
        willScroll = 1;
    }
    if (E.cf->cx >= E.cf->coloff + E.screencols) {
        E.cf->coloff = E.cf->cx - E.screencols + 1;
        willScroll = 1;
    }

    if (willScroll) {
        editorSetAllRowsDirty();
    }
}

static void editorDrawRows(void) {
    int y, padding, len, startAt;
    erow row;
    char col;
    CHUNKNUM c, nextRowChunk;
    echunk chunk;

    if (E.cf == NULL) {
        char **rows, *buffer;
        int i, numRows, x, y;

        prepWelcomePage(&rows, &numRows);
        y = (E.screenrows - numRows) / 2;
        for (i = 0; i < y; ++i) {
            drawRow(i, 0, 0, "", 0);
        }
        buffer = malloc(E.screencols + 1);
        for (i = 0; i < numRows; ++i, ++y) {
            x = (E.screencols - strlen(rows[i])) / 2;
            if (x < 0) x = 0;
            if (x > 0) memset(buffer, ' ', x);
            strcpy(buffer + x, rows[i]);
            drawRow(y, 0, strlen(buffer), buffer, 0);
        }

        free(buffer);
        freeWelcomePage(rows, numRows);

        return;
    }

    editorRowAt(E.cf->rowoff, &row);
    nextRowChunk = row.nextRowChunk;
    for (y = 0; y < E.screenrows; y++) {
        if (E.cf->dirtyScreenRows[y]) {
            c = row.firstTextChunk;
            len = row.size - E.cf->coloff;
            startAt = E.cf->coloff;
            col = 0;
            while (len && c) {
                retrieveChunk(c, (unsigned char *)&chunk);
                c = chunk.nextChunk;
                if (startAt < chunk.bytesUsed) {
                    drawRow(y, col, chunk.bytesUsed, (char *)chunk.bytes + startAt, 0);
                    len -= chunk.bytesUsed;
                    startAt = 0;
                } else {
                    startAt -= chunk.bytesUsed;
                }
                col += chunk.bytesUsed;
            }

            E.cf->dirtyScreenRows[y] = 0;
            clearRow(y, col);
        }

        if (nextRowChunk == 0) {
            break;
        }

        retrieveChunk(nextRowChunk, (unsigned char *)&row);
        nextRowChunk = row.nextRowChunk;
    }
}

static void editorDrawStatusBar(void) {
    char status[80], rstatus[80];
    int len, rlen;

    memset(E.statusbar, ' ', E.screencols);

    if (E.cf == NULL) {
        strcpy(status, "Welcome");
        len = strlen(status);
        rlen = 0;
    } else {
        len = snprintf(status, sizeof(status), "%.20s - %d lines%s%s (%ldk free mem)",
            E.cf->filename ? E.cf->filename : "[No Name]", E.cf->numrows,
            E.cf->dirty ? " (modified)" : "",
            E.cf->readOnly ? " (read only)" : "",
            ((long)getAvailChunks() * CHUNK_LEN) / 1024);
        rlen = snprintf(rstatus, sizeof(rstatus), "%d/%d", E.cf->cy + 1, E.cf->numrows);
        if (len > E.screencols) len = E.screencols;
    }
    memcpy(E.statusbar, status, len);
    memcpy(E.statusbar + E.screencols - rlen, rstatus, rlen);

    drawRow(E.screenrows, 0, E.screencols, E.statusbar, 1);
}

static void editorDrawMessageBar(void) {
    int msglen = strlen(E.statusmsg);

    if (!E.statusmsg_dirty) return;

    if (msglen > E.screencols) msglen = E.screencols;
    if (msglen) {
        drawRow(E.screenrows+1, 0, msglen, E.statusmsg, 0);
    } else {
        memset(E.statusmsg, ' ', E.screencols);
        drawRow(E.screenrows+1, 0, E.screencols, E.statusmsg, 0);
    }
    
    E.statusmsg_dirty = 0;
}

void editorRefreshScreen(void) {
    if (E.cf)
        editorScroll();

    editorDrawRows();
    editorDrawStatusBar();
    editorDrawMessageBar();

    renderCursor();
}

void editorSetStatusMessage(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(E.statusmsg, sizeof(E.statusmsg), fmt, ap);
    va_end(ap);
    E.statusmsg_dirty = 1;
}

