/**
 * screen.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Render screen.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

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
static void setCursor(unsigned char value, unsigned char color);

#ifdef __MEGA65__
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
 void clearRow(char row, char startingCol) {
    int offset = row * 80 + startingCol;
    memset(SCREEN+offset, ' ', 80-startingCol);
}

static void drawRow65(char row, char col, char len, char *buf, char isReversed) {
    char i;
    int offset = row * 80 + col;
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

    offset = (E.cf.cy - E.cf.rowoff) * 80 + E.cf.cx - E.cf.coloff;
    if (clear) {
        SCREEN[offset] &= 0x7f;
    } else {
        SCREEN[offset] |= 0x80;
    }
    cellcolor(E.cf.cx - E.cf.coloff, E.cf.cy - E.cf.rowoff, color);
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

    if (E.cf.cy < E.cf.rowoff) {
        E.cf.rowoff = E.cf.cy;
        willScroll = 1;
    }
    if (E.cf.cy >= E.cf.rowoff + E.screenrows) {
        E.cf.rowoff = E.cf.cy - E.screenrows + 1;
        willScroll = 1;
    }
    if (E.cf.cx < E.cf.coloff) {
        E.cf.coloff = E.cf.cx;
        willScroll = 1;
    }
    if (E.cf.cx >= E.cf.coloff + E.screencols) {
        E.cf.coloff = E.cf.cx - E.screencols + 1;
        willScroll = 1;
    }

    if (willScroll) {
        editorSetAllRowsDirty();
    }
}

static void editorDrawRows(void) {
    int y, len, startAt, toDraw;
    erow row;
    char col;
    CHUNKNUM c, nextRowChunk;
    echunk chunk;

    if (E.cf.fileChunk == 0) {
        char *n, *p;
        int rows = 0, x;
        // First, count the rows for the welcome screen.
        p = E.welcomePage;
        while (1) {
            n = strchr(p, '\r');
            ++rows;
            if (n == NULL) {
                break;
            }
            p = n + 1;
        }
        p = E.welcomePage;
        // Center the rows vertically
        y = E.screenrows / 2 - rows / 2;
        while (1) {
            n = strchr(p, '\r');
            len = n == NULL ? strlen(p) : n - p;
            x = E.screencols / 2 - len / 2;
            drawRow(y++, x, len, p, 0);
            if (n == NULL) {
                break;
            }
            p = n + 1;
        }

        return;
    }

    if (E.cf.firstRowChunk == 0) {
        return;
    }

    editorRowAt(E.cf.rowoff, &row);
    nextRowChunk = row.nextRowChunk;
    for (y = 0; y < E.screenrows; y++) {
        if (row.dirty) {
            c = row.firstTextChunk;
            len = row.size - E.cf.coloff;
            startAt = E.cf.coloff;
            col = 0;
            // Draw the text chunks for this row
            while (len && c) {
                retrieveChunk(c, (unsigned char *)&chunk);
                c = chunk.nextChunk;
                // If the screen is scrolled to the right (coloff > 0)
                // and any part of the chunk is visible, draw the visible part.
                if (startAt < chunk.bytesUsed) {
                    toDraw = chunk.bytesUsed - startAt;
                    if (col + chunk.bytesUsed > E.screencols) {
                        toDraw = E.screencols - col;
                    }
                    drawRow(y, col, toDraw, (char *)chunk.bytes + startAt, 0);
                    len -= toDraw;
                    startAt = 0;
                    col += toDraw;
                } else {
                    // None of the chunk is visible - skip it.
                    startAt -= chunk.bytesUsed;
                }
            }

            row.dirty = 0;
            storeChunk(row.rowChunk, (unsigned char *)&row);
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
    char status[80], rstatus[80], filename[CHUNK_LEN];
    int len, rlen;

    memset(E.statusbar, ' ', E.screencols);

    if (E.cf.fileChunk == 0) {
        strcpy(status, "Welcome");
        len = strlen(status);
        rlen = 0;
    } else {
        editorRetrieveFilename(&E.cf, filename);
        if (filename[0] == 0) {
            strcpy(filename, "[No Name]");
        }
        len = snprintf(status, sizeof(status), "%.16s%s %d line%s%s (%ldk free)",
            filename, E.cf.dirty ? "*": "",
            E.cf.numrows, E.cf.numrows == 1 ? "" : "s",
            E.cf.readOnly ? " R/O" : "",
            ((long)getAvailChunks() * CHUNK_LEN) / 1024);
        rlen = snprintf(rstatus, sizeof(rstatus), "C:%d R:%d", E.cf.cx + 1, E.cf.cy + 1);
        if (len > E.screencols) len = E.screencols;
    }
    memcpy(E.statusbar, status, len);
    if (E.screencols >= 80) {
        memcpy(E.statusbar + E.screencols - rlen, rstatus, rlen);
    }

    drawRow(E.screenrows, 0, E.screencols, E.statusbar, 1);
}

static void editorDrawMessageBar(void) {
    int msglen = strlen(E.statusmsg);

    if (!E.statusmsg_dirty) return;

    if (msglen > E.screencols) msglen = E.screencols;
    if (msglen) {
        drawRow(E.screenrows+1, 0, msglen, E.statusmsg, 0);
        clearRow(E.screenrows+1, msglen);
    } else {
        memset(E.statusmsg, ' ', E.screencols);
        drawRow(E.screenrows+1, 0, E.screencols, E.statusmsg, 0);
    }
    
    E.statusmsg_dirty = 0;
}

void editorRefreshScreen(void) {
    if (E.cf.fileChunk)
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

