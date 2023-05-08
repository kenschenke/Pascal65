/**
 * editor.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Main functionality for editor.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include "editor.h"

#include <stdio.h>
#include <string.h>
#include <membuf.h>
#include <stdlib.h>
#include <libcommon.h>

#ifdef __C128__
#include <c128.h>
#endif
#include <conio.h>

#ifdef __MEGA65__
#include <cbm.h>
#endif

struct editorConfig E;

static void editorDelChar(void);
static void editorInsertChar(int c);
static void editorInsertTab(void);
static void editorInsertNewLine(int spaces);
static void editorMoveCursor(int key, char skipClear);
static void editorProcessKeypress(void);
static void initTitleScreen(void);
static void openHelpFile(void);

#ifdef __MEGA65__
void fastcall setscreensize(unsigned char width, unsigned char height);
#endif

/*** editor operations ***/

static void editorDelChar(void) {
    erow row;
    echunk chunk;
    CHUNKNUM chunkNum;
    int beforeSize;

    if (E.cf.cy == E.cf.numrows) return;
    if (E.cf.cx == 0 && E.cf.cy == 0) return;

    if (E.cf.cx > 0) {
        editorRowDelChars(E.cf.cx - 1, 1);
        E.cf.cx--;
    } else {
        if (editorRowAt(E.cf.cy, &row) == 0) {
            return;
        }
        chunkNum = row.firstTextChunk;
        if (editorRowAt(E.cf.cy - 1, &row) == 0) {
            return;
        }
        beforeSize = row.size;
        while (chunkNum) {
            retrieveChunk(chunkNum, (unsigned char *)&chunk);
            chunkNum = chunk.nextChunk;
            editorRowAppendString(&row, (char *)chunk.bytes, chunk.bytesUsed);
        }
        E.cf.cx = beforeSize;
        editorDelRow(E.cf.cy);
        E.cf.cy--;
    }
}

static void editorInsertChar(int c) {
    if (E.cf.cy == E.cf.numrows) {
        editorInsertRow(E.cf.numrows, "", 0);
    }
    editorRowInsertChar(E.cf.cx, c);
    E.cf.cx++;
}

static void editorInsertTab(void) {
    editorInsertChar(' ');
    while (E.cf.cx % EDITOR_TAB_STOP) editorInsertChar(' ');
}

static void editorInsertNewLine(int spaces) {
    erow currentRow, newRow;
    int firstCol, startAt, toCopy;
    CHUNKNUM chunkNum, nextChunk;
    echunk chunk;

    if (E.cf.cx == 0) {
        editorInsertRow(E.cf.cy, "", 0);
    } else {
        clearCursor();
        editorRowAt(E.cf.cy, &currentRow);
        editorChunkAtX(&currentRow, E.cf.cx, &firstCol, &chunkNum, &chunk);
        startAt = E.cf.cx - firstCol;
        toCopy = chunk.bytesUsed - startAt;
        editorInsertRow(E.cf.cy + 1, (char *)chunk.bytes + startAt, toCopy);
        editorRowAt(E.cf.cy, &currentRow);
        editorRowAt(E.cf.cy + 1, &newRow);
        nextChunk = chunk.nextChunk;
        chunk.nextChunk = 0;
        chunk.bytesUsed -= toCopy;
        storeChunk(chunkNum, (unsigned char *)&chunk);
        newRow.size = currentRow.size - E.cf.cx;
        currentRow.size = E.cf.cx;
        storeChunk(currentRow.rowChunk, (unsigned char *)&currentRow);
        storeChunk(newRow.rowChunk, (unsigned char *)&newRow);
        retrieveChunk(newRow.firstTextChunk, (unsigned char *)&chunk);
        chunk.nextChunk = nextChunk;
        storeChunk(newRow.firstTextChunk, (unsigned char *)&chunk);
        editorSetRowDirty(&currentRow);
        editorSetRowDirty(&newRow);
    }
    E.cf.cy++;
    if (E.cf.cx) {
        E.cf.cx = 0;
        while (spaces--) editorInsertChar(' ');
    }
}

/*** input ***/

static void editorMoveCursor(int key, char skipClear) {
    char hasRow = 0;
    int rowlen;
    erow row;
    
    if (E.cf.cy < E.cf.numrows) {
        if (editorRowAt(E.cf.cy, &row) == 0) {
            return;
        }
        hasRow = 1;
    }

    switch (key) {
        case CH_CURS_LEFT:
            if (E.cf.cx != 0) {
                if (!skipClear) clearCursor();
                E.cf.cx--;
            } else if (E.cf.cy > 0) {
                if (!skipClear) clearCursor();
                E.cf.cy--;
                editorRowAt(E.cf.cy, &row);
                E.cf.cx = row.size;
            }
            break;
        case CH_CURS_RIGHT:
            if (hasRow && E.cf.cx < row.size) {
                if (!skipClear) clearCursor();
                E.cf.cx++;
            } else if (hasRow && row.size && E.cf.cx == row.size && E.cf.cy < E.cf.numrows - 1) {
                if (!skipClear) clearCursor();
                E.cf.cy++;
                E.cf.cx = 0;
                if (E.cf.coloff) {
                    E.cf.coloff = 0;
                    editorSetAllRowsDirty();
                }
            }
            break;
        case CH_CURS_UP:
            if (E.cf.cy != 0) {
                if (!skipClear) clearCursor();
                E.cf.cy--;
            }
            break;
        case CH_CURS_DOWN:
            if (E.cf.cy < E.cf.numrows - 1) {
                if (!skipClear) clearCursor();
                E.cf.cy++;
            }
            break;
    }

    if (E.cf.cy < E.cf.numrows) {
        editorRowAt(E.cf.cy, &row);
    }
    rowlen = hasRow ? row.size : 0;
    if (E.cf.cx > rowlen) {
        E.cf.cx = rowlen;
        if (E.cf.cx < 0) E.cf.cx = 0;
    }

    if (E.cf.cx < E.cf.coloff + E.screencols && E.cf.cy < E.cf.rowoff + E.screenrows) {
        renderCursor(E.cf.cx-E.cf.coloff, E.cf.cy-E.cf.rowoff);
#ifdef __MEGA65__
        gotoxy(E.cf.cx, E.cf.cy);
#endif
    }
}

static void editorProcessKeypress(void) {
    int times;
    int c = editorReadKey();

    if (E.cbKeyPressed && E.cbKeyPressed(c)) {
        return;
    }

    switch (c) {
        case CH_ENTER:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                // Count the number of spaces at the beginning of this line
                erow row;
                int i, spaces = 0;
                echunk chunk;
                CHUNKNUM chunkNum;
                editorRowAt(E.cf.cy, &row);
                if (E.cf.cx < row.size) editorSetRowDirty(&row);
                chunkNum = row.firstTextChunk;
                while (chunkNum) {
                    retrieveChunk(chunkNum, (unsigned char *)&chunk);
                    for (i = 0; i < chunk.bytesUsed; ++i) {
                        if (chunk.bytes[i] == ' ') {
                            ++spaces;
                        } else {
                            break;
                        }
                    }
                    if (i < chunk.bytesUsed) {
                        break;
                    }
                    chunkNum = chunk.nextChunk;
                }
                editorInsertNewLine(spaces);
            }
            break;
        
        case '\t':
            if (E.cf.fileChunk && !E.cf.readOnly) editorInsertTab();
            break;

        case CH_INS:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                editorInsertChar(' ');
                E.cf.cx--;
            }
            break;

        case CH_F7:
            clearCursor();
            drawStatusRow(COLOR_WHITE, 0, "Loading Help File...");
            openHelpFile();
            editorSetDefaultStatusMessage();
            break;

        case BACKARROW:
            handleFiles();
            editorSetDefaultStatusMessage();
            break;

        case CH_F1:
            openFile();
            if (E.cf.fileChunk) {
                clearScreen();
                editorSetAllRowsDirty();
            }
            break;

        case CH_F2:
            saveFile();
            break;

        case CTRL_KEY('x'):
            if (E.cbExitRequested && !E.cbExitRequested()) {
                break;
            }
            E.quit = 1;
            break;
        
        case CTRL_KEY('j'):
        case HOME_KEY:
            if (E.cf.fileChunk) {
                clearCursor();
                E.cf.cx = 0;
            }
            break;

        case CH_HOME:
            if (E.cf.fileChunk) {
                clearCursor();
                if (E.cf.cx == 0 && E.cf.cy == E.cf.rowoff) {
                    if (E.cf.rowoff != 0) {
                        E.cf.rowoff = 0;
                        editorSetAllRowsDirty();
                    }
                    E.cf.cy = 0;
                } else {
                    E.cf.cx = 0;
                    E.cf.cy = E.cf.rowoff;
                }
            }
            break;

        case CTRL_KEY('k'):
        case END_KEY:
            if (E.cf.fileChunk && E.cf.cy < E.cf.numrows) {
                erow row;
                clearCursor();
                editorRowAt(E.cf.cy, &row);
                E.cf.cx = row.size;
            }
            break;

        case DEL_SOL_KEY:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                clearCursor();
                editorDeleteToStartOfLine();
            }
            break;

        case DEL_EOL_KEY:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                clearCursor();
                editorDeleteToEndOfLine();
            }
            break;
        
        case CTRL_KEY('d'):
        case DEL_LINE_KEY:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                clearCursor();
                E.cf.cx = 0;
                editorDelRow(E.cf.cy);
            }
            break;

        case INS_LINE_KEY:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                clearCursor();
                E.cf.cx = 0;
                editorInsertNewLine(0);
                E.cf.cy--;
            }
            break;

        case CTRL_KEY('v'):
        case SCROLL_UP_KEY:
            if (E.cf.fileChunk && E.cf.rowoff > 0) {
                clearCursor();
                --E.cf.rowoff;
                if (E.cf.cy - E.cf.rowoff > E.screenrows - 1) {
                    E.cf.cy = E.cf.rowoff + E.screenrows - 1;
                }
                editorSetAllRowsDirty();
            }
            break;

        case CTRL_KEY('w'):
        case SCROLL_DOWN_KEY:
            if (E.cf.fileChunk && E.cf.rowoff + E.screenrows < E.cf.numrows) {
                clearCursor();
                ++E.cf.rowoff;
                if (E.cf.cy < E.cf.rowoff) {
                    E.cf.cy = E.cf.rowoff;
                }
                editorSetAllRowsDirty();
            }
            break;
        
        case CTRL_KEY('b'):
        case SCROLL_TOP_KEY:
            if (E.cf.fileChunk && E.cf.rowoff != 0) {
                clearCursor();
                E.cf.rowoff = 0;
                E.cf.cy = 0;
                editorSetAllRowsDirty();
            }
            break;

        case CTRL_KEY('e'):
        case SCROLL_BOTTOM_KEY:
            if (E.cf.fileChunk) {
                int newoff = E.cf.numrows - E.screenrows;
                if (newoff < 0) newoff = 0;
                if (E.cf.rowoff != newoff) {
                    clearCursor();
                    E.cf.rowoff = newoff;
                    editorSetAllRowsDirty();
                }
                E.cf.cy = E.cf.numrows - 1;
            }
            break;

        case CH_DEL:
        case CTRL_KEY('h'):
        case DEL_KEY:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                clearCursor();
                if (c == DEL_KEY) editorMoveCursor(CH_CURS_RIGHT, 0);
                editorDelChar();
            }
            break;

        case CH_CURS_UP:
        case CH_CURS_DOWN:
        case CH_CURS_LEFT:
        case CH_CURS_RIGHT:
            if (E.cf.fileChunk) editorMoveCursor(c, 0);
            break;

        case CTRL_KEY('n'):
        case CTRL_KEY('p'):
        case PAGE_UP:
        case PAGE_DOWN:
            if (E.cf.fileChunk) {
                clearCursor();
                if (c == CTRL_KEY('n')) c = PAGE_DOWN;
                if (c == CTRL_KEY('p')) c = PAGE_UP;
                if (c == PAGE_UP) {
                    E.cf.cy = E.cf.rowoff;
                } else if (c == PAGE_DOWN) {
                    E.cf.cy = E.cf.rowoff + E.screenrows;
                    if (E.cf.cy >= E.cf.numrows) E.cf.cy = E.cf.numrows - 1;
                }

                times = E.screenrows;
                clearCursor();
                while (times--)
                    editorMoveCursor(c == PAGE_UP ? CH_CURS_UP : CH_CURS_DOWN, 1);
            }
            break;

        case STOP_KEY:
            // do nothing
            break;

        default:
            if (!E.cf.readOnly) {
                clearCursor();
                if (E.cf.fileChunk) editorInsertChar(c);
            }
            break;
    }
}

void editorRun(void) {
    while (!E.quit) {
        editorRefreshScreen();
        editorProcessKeypress();
    }

    clearScreen();
    gotoxy(0, 0);
}

/*** init ***/

void initEditor() {
    E.quit = 0;
    E.last_key_esc = 0;
    E.statusmsg[0] = '\0';
    E.statusmsg_dirty = 0;

    E.firstFileChunk = 0;
    memset(&E.cf, 0, sizeof(efile));

    E.screenrows = 25;
#ifdef __MEGA65
    E.screencols = 80;
#elif defined(__C64__)
    E.screencols = 40;
#endif
    E.screenrows -= 2;

    E.cbKeyPressed = NULL;
    E.cbShowHelpPage = NULL;
    E.cbShowWelcomePage = NULL;
    E.cbUpdateStatusBar = NULL;
    E.cbExitRequested = NULL;

    memset(E.statusbar, ' ', E.screencols);

    initTitleScreen();

#ifdef __C128__
    fast();
#endif
    setupScreenCols();
}

void initFile(void) {
    allocChunk(&E.cf.fileChunk);
    E.cf.nextFileChunk = E.firstFileChunk;
    E.firstFileChunk = E.cf.fileChunk;
    E.cf.cx = 0;
    E.cf.cy = 0;
    E.cf.rowoff = 0;
    E.cf.coloff = 0;
    E.cf.numrows = 0;
    E.cf.firstRowChunk = 0;
    E.cf.dirty = 0;
    E.cf.filenameChunk = 0;
    E.cf.readOnly = 0;
    storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
}

static void initTitleScreen(void) {
    FILE *fp;
    char buf[41];

    allocMemBuf(&E.titleChunk);

    fp = fopen("title.txt", "r");
    if (fp == NULL) {
        printlnz("Unable to locate title.txt");
        exit(5);
    }

    while (!feof(fp)) {
        if (fgets(buf, sizeof(buf), fp) == NULL) {
            break;
        }

        writeToMemBuf(E.titleChunk, buf, strlen(buf));
    }

    fclose(fp);
}

void editorNewFile(void) {
    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    initFile();
    updateStatusBarFilename();
    renderCursor(E.cf.cx-E.cf.coloff, E.cf.cy-E.cf.rowoff);
}

void editorStoreFilename(const char *filename) {
    char bytes[CHUNK_LEN];

    if (E.cf.filenameChunk == 0) {
        allocChunk(&E.cf.filenameChunk);
    }

    strcpy(bytes, filename);
    storeChunk(E.cf.filenameChunk, (unsigned char *)bytes);
}

void editorRetrieveFilename(char *buffer) {
    if (E.cf.filenameChunk == 0) {
        memset(buffer, 0, CHUNK_LEN);
    } else {
        retrieveChunk(E.cf.filenameChunk, (unsigned char *)buffer);
    }
}

void editorSetDefaultStatusMessage(void) {
    editorSetStatusMessage("F1: open  Ctrl-X: quit  F7: help");
}

static void openHelpFile(void) {
    char buf[CHUNK_LEN];

    editorOpen("help.txt", 1);
    strcpy(buf, "Help File");
    allocChunk(&E.cf.filenameChunk);
    storeChunk(E.cf.filenameChunk, (unsigned char *)buf);
    storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    updateStatusBarFilename();
}

void setupScreenCols(void) {
#ifdef __C128__
    if (E.screencols == 80)
        videomode(VIDEOMODE_80x25);
    else
        videomode(VIDEOMODE_40x25);
#elif defined(__MEGA65__)
    setscreensize(80, 25);
#endif

    initScreen();
#ifdef __C128__
    setScreenBg(E.screencols == 40 ? COLOR_BLUE : 2);
#endif
}

