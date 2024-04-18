/**
 * screen.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Render screen.
 * 
 * Copyright (c) 2024
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
#include <ctype.h>
#include <int16.h>
#include <membuf.h>

#ifdef __MEGA65__
#include <cbm.h>
#endif

#define KILO_VERSION "0.0.1"

#ifdef __MEGA65__
#define STATUSCOL_RO 57
#define STATUSCOL_MEM 62
#define STATUSCOL_X 71
#define STATUSCOL_X_LABEL 69
#define STATUSCOL_Y 77
#define STATUSCOL_Y_LABEL 75
#else
#define STATUSCOL_RO 18
#define STATUSCOL_MEM 23
#define STATUSCOL_X 31
#define STATUSCOL_X_LABEL 29
#define STATUSCOL_Y 37
#define STATUSCOL_Y_LABEL 35
#endif

static void editorDrawMessageBar(void);
static void editorDrawRows(void);
static void editorDrawStatusBar(void);
static void editorScroll(void);

#ifdef __MEGA65__
#elif defined(__C64__)
char * SCREEN = (char*)0x0400;
void clearRow(char row, char startingCol) {
    int offset = row * 40 + startingCol;
    memset(SCREEN+offset, ' ', 40-startingCol);
}
#endif

void clearStatusRow(void) {
    drawStatusRow(COLOR_WHITE, 0, "");
}

void drawStatusRow(char color, char center, const char *msg) {
    int x;

    clearRow(E.screenrows + 1, 0);
    x = center ? E.screencols / 2 - strlen(msg) / 2 : 0;
    drawRow(E.screenrows + 1, x, strlen(msg), msg, 0);

    setRowColor(E.screenrows + 1, color);
}

void printz(char *str);

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
    echunk *chunk;

    if (E.cf.fileChunk == 0) {
        char ch, buf[41];
        char *p;
        int rows = 0, x;
        // First, count the rows for the welcome screen.
        setMemBufPos(E.titleChunk, 0);
        while (!isMemBufAtEnd(E.titleChunk)) {
            readFromMemBuf(E.titleChunk, &ch, 1);
            if (ch == '\n') {
                ++rows;
            }
        }
        setMemBufPos(E.titleChunk, 0);
        // Center the rows vertically
        y = E.screenrows / 2 - rows / 2;
        p = buf;
        while (!isMemBufAtEnd(E.titleChunk)) {
            readFromMemBuf(E.titleChunk, p, 1);
            if (*p == '\n') {
                // printf("?");
                *p = 0;
                len = strlen(buf);
                if (len < 1) {
                    ++y;
                    p = buf;
                    continue;
                }
                x = E.screencols / 2 - len / 2;
                drawRow(y++, x, len, buf, 0);
                p = buf;
            } else {
                // printf("%c", *p);
                ++p;
            }
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
                chunk = getChunk(c);
                c = chunk->nextChunk;
                // If the screen is scrolled to the right (coloff > 0)
                // and any part of the chunk is visible, draw the visible part.
                if (startAt < chunk->bytesUsed) {
                    toDraw = chunk->bytesUsed - startAt;
                    if (col + chunk->bytesUsed > E.screencols) {
                        toDraw = E.screencols - col;
                    }
                    drawRow(y, col, toDraw, (char *)chunk->bytes + startAt, 0);
                    len -= toDraw;
                    startAt = 0;
                    col += toDraw;
                } else {
                    // None of the chunk is visible - skip it.
                    startAt -= chunk->bytesUsed;
                }
            }

            row.dirty = 0;
            storeChunk(row.rowChunk, (unsigned char *)&row);
            clearRow(y, col);
        }

        if (nextRowChunk == 0 && E.cf.cy != y + E.cf.rowoff) {
            row.dirty = 0;
            clearRow(y, 0);
            continue;
        }

        retrieveChunk(nextRowChunk, (unsigned char *)&row);
        nextRowChunk = row.nextRowChunk;
    }
}

static void editorDrawStatusBar(void) {
    char num[10];

    if (E.cf.fileChunk) {
        strcpy(num, formatInt16((int)(((long)getAvailChunks() * CHUNK_LEN) / 1024)));
        strcat(num, "k  ");
        memcpy(E.statusbar + STATUSCOL_MEM, num, strlen(num));
        
        strcpy(num, formatInt16(E.cf.cx + 1));
        strcat(num, "  ");
        memcpy(E.statusbar + STATUSCOL_X, num, strlen(num));

        strcpy(num, formatInt16(E.cf.cy + 1));
        strcat(num, "  ");
        memcpy(E.statusbar + STATUSCOL_Y, num, strlen(num));
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

    if (E.anyDirtyRows) {
        editorDrawRows();
        E.anyDirtyRows = 0;
    }
    editorDrawStatusBar();
    editorDrawMessageBar();

    if (E.cf.fileChunk) {
        renderCursor(E.cf.cx-E.cf.coloff, E.cf.cy-E.cf.rowoff);
    } else {
        clearCursor();
    }
}

void editorRetrieveFilename(char *buffer) {
    if (E.cf.filenameChunk == 0) {
        memset(buffer, 0, CHUNK_LEN);
    } else {
        retrieveChunk(E.cf.filenameChunk, (unsigned char *)buffer);
    }
}

void editorSetStatusMessage(const char *msg) {
    strcpy(E.statusmsg, msg);
    E.statusmsg_dirty = 1;
}

void updateStatusBarFilename(void) {
    if (E.cf.fileChunk == 0) {
        memcpy(E.statusbar, "Welcome", 7);
        memset(E.statusbar + 7, ' ', sizeof(E.statusbar)-7);
    } else {
        char filename[CHUNK_LEN];
        int n;
        editorRetrieveFilename(filename);
        filename[16] = 0;
        n = strlen(filename);
        if (n == 0) {
            strcpy(filename, "[No Name]");
            n = 9;
        }
        if (E.cf.dirty) {
            filename[strlen(filename)] = '*';
            ++n;
        }
        memcpy(E.statusbar, filename, n);
        memset(E.statusbar+n, ' ', 18-n);

        if (E.cf.readOnly) {
            memcpy(E.statusbar + STATUSCOL_RO, "R/O", 3);
        } else {
            memset(E.statusbar + STATUSCOL_RO, ' ', 3);
        }

        memcpy(E.statusbar + STATUSCOL_X_LABEL, "C:", 2);
        memcpy(E.statusbar + STATUSCOL_Y_LABEL, "R:", 2);
    }
}

