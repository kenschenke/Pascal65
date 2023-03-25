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
#include <ctype.h>
#include <int16.h>

#ifdef __MEGA65__
#include <cbm.h>
#endif

#define KILO_VERSION "0.0.1"

#define STATUSCOL_RO 18
#define STATUSCOL_MEM 23
#define STATUSCOL_X 31
#define STATUSCOL_X_LABEL 29
#define STATUSCOL_Y 37
#define STATUSCOL_Y_LABEL 35

static void editorDrawMessageBar(void);
static void editorDrawRows(void);
static void editorDrawStatusBar(void);
static void editorScroll(void);
static void setCursor(unsigned char value, unsigned char color);

#ifdef __MEGA65__
static void drawRow65(char row, char col, char len, char *buf, char isReversed);

char * SCREEN = (char*)0x0800;
#endif

#ifdef __C64__
char * SCREEN = (char*)0x0400;
#endif

void clearScreen(void) {
#ifdef __C128__
    if (E.screencols == 40)
        clearScreen40();
    else
        clearScreen80();
#elif defined(__C64__)
    clearScreen40();
#else
    clrscr();
#endif
}

#ifdef __C64__
void clearRow(char row, char startingCol) {
    int offset = row * 40 + startingCol;
    memset(SCREEN+offset, ' ', 40-startingCol);
}
#endif

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
void clearCursor(void) {
#ifdef __C64__
    clearCursor64(E.cf.cx-E.cf.coloff, E.cf.cy-E.cf.rowoff);
#endif
}
#endif

void clearStatusRow(void) {
    drawStatusRow(COLOR_WHITE, 0, "");
}

void drawRow(char row, char col, char len, const char *buf, char isReversed) {
#ifdef __MEGA65__
    drawRow65(row, col, len, buf, isReversed);
#elif defined(__C64__)
    drawRow40(row, col, len, buf, isReversed);
#else
    if (E.screencols == 40)
        drawRow40(row, len, buf, isReversed);
    else
        drawRow80(row, len, buf, isReversed);
#endif
}

void drawStatusRow(char color, char center, const char *msg) {
    int x;
#if 0
    for (x = 0; x < E.screencols; ++x) {
        cellcolor(x, E.screenrows + 1, color);
    }
#endif

    clearRow(E.screenrows + 1, 0);
    x = center ? E.screencols / 2 - strlen(msg) / 2 : 0;
    drawRow(E.screenrows + 1, x, strlen(msg), msg, 0);

#ifdef __C64__
    setRowColor(E.screenrows + 1, color);
#endif
}

char editorPrompt(char *prompt, char *buf, size_t bufsize, int promptLength) {
    char msg[81];
    size_t buflen = 0;
    int c, x = promptLength;

    buf[0] = '\0';

    clearCursor();
    while (1) {
        strcpy(msg, prompt);
        strcat(msg, buf);
        drawStatusRow(COLOR_WHITE, 0, msg);
#ifdef __C64__
        renderCursor64(x, E.screenrows + 1);
#endif
        c = editorReadKey();
        if (c == DEL_KEY || c == CTRL_KEY('h') || c == CH_DEL) {
            if (buflen != 0) {
                buf[--buflen] = '\0';
                --x;
            }
        } else if (c == 3) {
            clearStatusRow();
            clearCursor();
            return 0;
        } else if (c == CH_ENTER) {
            if (buflen != 0) {
                clearStatusRow();
                clearCursor();
                return 1;
            }
        } else if (buflen + 1 < bufsize && !iscntrl(c) && c < 128) {
            buf[buflen++] = c;
            buf[buflen] = '\0';
            ++x;
        }
    }

    clearCursor();
    return 0;
}

void initScreen(void) {
#ifdef __MEGA65__
    conioinit();
    clearScreen();
#elif defined(__C64__)
    initScreen40();
    clearCursor();
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
    echunk *chunk;

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

        if (nextRowChunk == 0) {
            break;
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

    editorDrawRows();
    editorDrawStatusBar();
    editorDrawMessageBar();

    if (E.cf.fileChunk) {
#ifdef __MEGA65__
        renderCursor();
#elif defined(__C64__)
        renderCursor64(E.cf.cx-E.cf.coloff, E.cf.cy-E.cf.rowoff);
#endif
    } else {
        clearCursor();
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
        editorRetrieveFilename(&E.cf, filename);
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

