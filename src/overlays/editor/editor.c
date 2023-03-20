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

#include <string.h>

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

    if (editorRowAt(E.cf.cy, &row) == 0) {
        return;
    }

    if (E.cf.cx > 0) {
        editorRowDelChars(&row, E.cf.cx - 1, 1);
        E.cf.cx--;
    } else {
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
    erow row;

    if (E.cf.cy == E.cf.numrows) {
        editorInsertRow(E.cf.numrows, "", 0);
    }
    if (editorRowAt(E.cf.cy, &row) == 0) {
        return;
    }
    editorRowInsertChar(&row, E.cf.cx, c);
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
    int rowlen;
    erow rowBuf, *row = NULL;
    
    if (E.cf.cy < E.cf.numrows) {
        if (editorRowAt(E.cf.cy, &rowBuf) == 0) {
            return;
        }
        row = &rowBuf;
    }

    switch (key) {
        case CH_CURS_LEFT:
            if (E.cf.cx != 0) {
                if (!skipClear) clearCursor();
                E.cf.cx--;
            } else if (E.cf.cy > 0) {
                if (!skipClear) clearCursor();
                E.cf.cy--;
                editorRowAt(E.cf.cy, &rowBuf);
                E.cf.cx = rowBuf.size;
            }
            break;
        case CH_CURS_RIGHT:
            if (row && E.cf.cx < row->size) {
                if (!skipClear) clearCursor();
                E.cf.cx++;
            } else if (row && row->size && E.cf.cx == row->size) {
                if (!skipClear) clearCursor();
                E.cf.cy++;
                E.cf.cx = 0;
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
        editorRowAt(E.cf.cy, &rowBuf);
        row = &rowBuf;
    }
    rowlen = row ? row->size : 0;
    if (E.cf.cx > rowlen) {
        E.cf.cx = rowlen;
        if (E.cf.cx < 0) E.cf.cx = 0;
    }

    if (E.cf.cx < E.cf.coloff + E.screencols && E.cf.cy < E.cf.rowoff + E.screenrows) {
#ifdef __MEGA65__
        gotoxy(E.cf.cx, E.cf.cy);
#elif defined(__C64__)
        renderCursor64(E.cf.cx-E.cf.coloff, E.cf.cy-E.cf.rowoff);
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

        case CTRL_KEY('a'):
            clearCursor();
            openHelpFile();
            break;

        case BACKARROW:
            handleFiles();
            break;

        case CTRL_KEY('o'):
            openFile();
            if (E.cf.fileChunk) {
                clearScreen();
                editorSetAllRowsDirty();
            }
            break;

        case CTRL_KEY('u'):
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
    E.welcomePage = NULL;
    E.statusmsg[0] = '\0';
    E.statusmsg_dirty = 0;

    E.firstFileChunk = 0;
    memset(&E.cf, 0, sizeof(efile));

    E.screenrows = 25;
#ifdef __C64__
    E.screencols = 40;
#else
    E.screencols = 80;
#endif
    E.screenrows -= 2;

    E.cbKeyPressed = NULL;
    E.cbShowHelpPage = NULL;
    E.cbShowWelcomePage = NULL;
    E.cbUpdateStatusBar = NULL;
    E.cbExitRequested = NULL;

    memset(E.statusbar, ' ', E.screencols);

#ifdef __C128__
    fast();
#endif
    setupScreenCols();
}

void initFile(efile *file) {
    allocChunk(&file->fileChunk);
    file->nextFileChunk = E.firstFileChunk;
    E.firstFileChunk = file->fileChunk;
    file->cx = 0;
    file->cy = 0;
    file->rowoff = 0;
    file->coloff = 0;
    file->numrows = 0;
    file->firstRowChunk = 0;
    file->dirty = 0;
    file->filenameChunk = 0;
    file->readOnly = 0;
}

void editorNewFile(void) {
    if (E.cf.fileChunk) {
        storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    }

    initFile(&E.cf);
#ifdef __C64__
    renderCursor64(E.cf.cx-E.cf.coloff, E.cf.cy-E.cf.rowoff);
#endif
}

void editorStoreFilename(efile *file, const char *filename) {
    char bytes[CHUNK_LEN];

    if (file->filenameChunk == 0) {
        allocChunk(&file->filenameChunk);
    }

    strcpy(bytes, filename);
    storeChunk(file->filenameChunk, (unsigned char *)bytes);
}

void editorRetrieveFilename(efile *file, char *buffer) {
    if (file->filenameChunk == 0) {
        memset(buffer, 0, CHUNK_LEN);
    } else {
        retrieveChunk(file->filenameChunk, (unsigned char *)buffer);
    }
}

static void openHelpFile(void) {
    char buf[CHUNK_LEN];

    editorOpen("help.txt", 1);
    strcpy(buf, "Help File");
    allocChunk(&E.cf.filenameChunk);
    storeChunk(E.cf.filenameChunk, (unsigned char *)buf);
    storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
}

void setupScreenCols(void) {
#ifdef __C128__
    if (E.screencols == 80)
        videomode(VIDEOMODE_80x25);
    else
        videomode(VIDEOMODE_40x25);
#elif defined(__MEGA65__)
    if (E.screencols == 80)
        setscreensize(80, 25);
    else
        setscreensize(40, 25);
#endif

    initScreen();
#ifdef __C128__
    setScreenBg(E.screencols == 40 ? COLOR_BLUE : 2);
#endif
}

