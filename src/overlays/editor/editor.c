/**
 * editor.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Main functionality for editor.
 * 
 * Copyright (c) 2024
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
#include <conio.h>
#endif

static void editorDelChar(void);
static void editorInsertChar(int c);
static void editorInsertTab(void);
static void editorInsertNewLine(void);
static void editorMoveCursor(int key, char skipClear);
static char editorProcessKeypress(void);
static void editorSetupEditBuf(void);
static void initTitleScreen(void);

static char hasEditBuf;
static erow currentRow;

extern char editBuf[80];

#ifdef __MEGA65__
void fastcall setscreensize(unsigned char width, unsigned char height);
#endif

/*** editor operations ***/

void closeFile(void) {
    if (E.cf.dirty && E.cf.fileChunk) {
        int ch;

        while (1) {
            drawStatusRow(COLOR_LIGHTRED, 0, "Save changes before closing? Y/N");
            ch = cgetc();
            if (ch == 'y' || ch == 'Y') {
                break;
            } else if (ch == STOP_KEY) {
                clearStatusRow();
                editorSetDefaultStatusMessage();
                return;
            } else if (ch == 'n' || ch == 'N' || ch == CH_ESC) {
                editorClose();
                clearStatusRow();
                editorSetDefaultStatusMessage();
                return;
            }
        }

        if (saveFile() == 0) {
            return;
        }
    }

    editorClose();
}

void editorClose(void) {
    CHUNKNUM chunkNum;
    erow row;
    efile file;

    if (!E.cf.fileChunk) {
        return;  // no file currently open
    }

    // Free the rows
    chunkNum = E.cf.firstRowChunk;
    while (chunkNum) {
        if (retrieveChunk(chunkNum, (unsigned char *)&row) == 0) {
            break;
        }
        chunkNum = row.nextRowChunk;
        editorFreeRow(row.firstTextChunk);
        freeChunk(row.rowChunk);
    }

    // Remove the file from the list
    if (E.firstFileChunk == E.cf.fileChunk) {
        E.firstFileChunk = E.cf.nextFileChunk;
    } else {
        chunkNum = E.firstFileChunk;
        while (chunkNum) {
            retrieveChunk(chunkNum, (unsigned char *)&file);
            if (file.nextFileChunk == E.cf.fileChunk) {
                file.nextFileChunk = E.cf.nextFileChunk;
                storeChunk(chunkNum, (unsigned char *)&file);
                break;
            }
            chunkNum = file.nextFileChunk;
        }
    }

    if (E.cf.filenameChunk) {
        freeChunk(E.cf.filenameChunk);
    }
    freeChunk(E.cf.fileChunk);
    freeChunk(E.cf.selectionChunk);
    E.cf.fileChunk = 0;
    E.cf.firstRowChunk = 0;
    clearScreen();
    
    if (E.firstFileChunk) {
        retrieveChunk(E.firstFileChunk, (unsigned char *)&E.cf);
        editorSetAllRowsDirty();
    }

    updateStatusBarFilename();
}

static void editorDelChar(void) {
    char ch;
    erow row;
    echunk chunk;
    CHUNKNUM chunkNum;
    int beforeSize;

    if (E.cf.cy == E.cf.numrows) return;
    if (E.cf.cx == 0 && E.cf.cy == 0) return;

    if (E.cf.cx > 0) {
        // Cursor not in first column.  Delete the character.
        editorSetupEditBuf();
        editBufDeleteChars(E.cf.cx - 1, 1, currentRow.size);
        ch = currentRow.size - E.cf.coloff > E.screencols ? editBuf[E.screencols + E.cf.coloff - 1] : ' ';
        screenDeleteChar(ch, E.cf.cx-1-E.cf.coloff, E.cf.cy-E.cf.rowoff);
        --currentRow.size;
        storeChunk(currentRow.rowChunk, &currentRow);
        E.cf.cx--;
    } else {
        // Cursor in first column.  Move the contents of the
        // current row to the end of the previous row.
        editorFlushEditBuf();
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
        E.anyDirtyRows = 1;
    }
}

void editorFlushEditBuf(void)
{
    if (!hasEditBuf) {
        return;
    }

    editBufFlush(&currentRow.firstTextChunk, currentRow.size);
    storeChunk(currentRow.rowChunk, &currentRow);
    hasEditBuf = 0;
}

static void editorInsertChar(int c) {
    if (E.cf.cy == E.cf.numrows) {
        // The cursor is at the end of the file on a non-existant row.
        // Since the user started typing, create an empty row.
        editorInsertRow(E.cf.numrows, "", 0);
    }
    editorSetupEditBuf();
    editBufInsertChar(c, currentRow.size++, E.cf.cx);
    screenInsertChar(c, E.cf.cx-E.cf.coloff, E.cf.cy-E.cf.rowoff);
    currentRow.dirty = 0;
    storeChunk(currentRow.rowChunk, &currentRow);
    E.cf.dirty = 1;
    updateStatusBarFilename();
    E.cf.cx++;
}

static void editorInsertTab(void) {
    editorInsertChar(' ');
    while (E.cf.cx % EDITOR_TAB_STOP) editorInsertChar(' ');
}

static void editorInsertNewLine(void) {
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
    E.cf.cx = 0;
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
                editorFlushEditBuf();
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
                editorFlushEditBuf();
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
                editorFlushEditBuf();
                E.cf.cy--;
            }
            break;
        case CH_CURS_DOWN:
            if (E.cf.cy < E.cf.numrows - 1) {
                if (!skipClear) clearCursor();
                editorFlushEditBuf();
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

    if (E.cf.inSelection) {
        editorCalcSelection();
        updateStatusBarFilename();
    }
}

static char editorProcessKeypress(void) {
    int times;
    int c = editorReadKey();
    char loopCode = EDITOR_LOOP_CONTINUE;

    if (E.cbKeyPressed && E.cbKeyPressed(c)) {
        return loopCode;
    }

    // Some keys have special meaning if selection mode is on.
    if (E.cf.inSelection) {
        switch (c) {
            case BACKARROW:
                editorClearSelection();
                editorSetDefaultStatusMessage();
                return loopCode;

            case 'c':
            case 'C':       // copy
                editorCopySelection();
                editorClearSelection();
                editorSetDefaultStatusMessage();
                return loopCode;
            
            case 'x':
            case 'X':       // cut
                editorCopySelection();
                editorDeleteSelection();
                editorClearSelection();
                editorSetDefaultStatusMessage();
                return loopCode;

            case CH_DEL:
            case CTRL_KEY('h'):
            case DEL_KEY:
                editorDeleteSelection();
                editorClearSelection();
                editorSetDefaultStatusMessage();
                return loopCode;
        }
    }

    switch (c) {
        case CH_ENTER:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                editorFlushEditBuf();
                editorInsertNewLine();
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
#ifdef __MEGA65__
        case 31:
#endif
            editorFlushEditBuf();
            loopCode = EDITOR_LOOP_OPENHELP;
            break;

        case BACKARROW:
            editorFlushEditBuf();
            loopCode = EDITOR_LOOP_FILESCREEN;
            break;

        case CH_F1:
        case CTRL_KEY('o'):
#ifdef __MEGA65__
        case 241:
#endif
            editorFlushEditBuf();
            loopCode = EDITOR_LOOP_OPENFILE;
            break;

        case CH_F2:
#ifdef __MEGA65__
        case 242:
#endif
            loopCode = EDITOR_LOOP_SAVEFILE;
            editorFlushEditBuf();
            break;

        case CH_F3:
#ifdef __MEGA65__
        case 243:
#endif
            loopCode = EDITOR_LOOP_RUN;
            editorFlushEditBuf();
            break;

        case CH_F5:
#ifdef __MEGA65__
        case 245:
#endif
            loopCode = EDITOR_LOOP_COMPILE;
            editorFlushEditBuf();
            break;

        case CTRL_KEY('x'):
            editorFlushEditBuf();
            if (E.cbExitRequested && !E.cbExitRequested()) {
                break;
            }
            loopCode = EDITOR_LOOP_QUIT;
            break;
        
        case CTRL_KEY('j'):
        case HOME_KEY:
            if (E.cf.fileChunk) {
                editorFlushEditBuf();
                clearCursor();
                E.cf.cx = 0;
            }
            break;

        case CH_HOME:
            if (E.cf.fileChunk) {
                editorFlushEditBuf();
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
            if (E.cf.fileChunk && !E.cf.readOnly && E.cf.cx) {
                clearCursor();
                editorSetupEditBuf();
                editBufDeleteChars(0, E.cf.cx - 1, currentRow.size);
                editorSetRowDirty(&currentRow);
                editorFlushEditBuf();
            }
            break;

        case DEL_EOL_KEY:
            editorSetupEditBuf();
            if (E.cf.fileChunk && !E.cf.readOnly && E.cf.cx < currentRow.size) {
                clearCursor();
                editBufDeleteChars(E.cf.cx, currentRow.size - E.cf.cx, currentRow.size);
                editorSetRowDirty(&currentRow);
                editorFlushEditBuf();
            }
            break;
        
        case CTRL_KEY('d'):
        case DEL_LINE_KEY:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                clearCursor();
                editorFlushEditBuf();
                E.cf.cx = 0;
                editorDelRow(E.cf.cy);
            }
            break;

        case INS_LINE_KEY:
            if (E.cf.fileChunk && !E.cf.readOnly) {
                clearCursor();
                editorFlushEditBuf();
                E.cf.cx = 0;
                editorInsertNewLine();
                E.cf.cy--;
            }
            break;

        case CTRL_KEY('v'):
        case SCROLL_UP_KEY:
            if (E.cf.fileChunk && E.cf.rowoff > 0) {
                clearCursor();
                editorFlushEditBuf();
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
                editorFlushEditBuf();
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
                editorFlushEditBuf();
                E.cf.rowoff = 0;
                E.cf.cy = 0;
                editorSetAllRowsDirty();
            }
            break;

        case CTRL_KEY('e'):
        case SCROLL_BOTTOM_KEY:
            if (E.cf.fileChunk) {
                int newoff = E.cf.numrows - E.screenrows;
                editorFlushEditBuf();
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
                editorFlushEditBuf();
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

        case CTRL_KEY('u'):
            editorFlushEditBuf();
            editorPasteClipboard();
            break;

        case CTRL_KEY('y'):
            E.selection.selectionX = E.cf.cx;
            E.selection.selectionY = E.cf.cy;
            E.cf.inSelection = 1;
            editorFlushEditBuf();
            editorSetStatusMessage("'C': copy, 'X': cut, \x1f: cancel");
            break;

        case STOP_KEY:
            // do nothing
            break;

        case '\x1b':
            break;

        default:
            if (!E.cf.readOnly) {
                clearCursor();
                if (E.cf.fileChunk) editorInsertChar(c);
            }
            break;
    }

    return loopCode;
}

char editorRun(void) {
    while (E.loopCode == EDITOR_LOOP_CONTINUE) {
        editorRefreshScreen();
        E.loopCode = editorProcessKeypress();
    }

    if (E.loopCode == EDITOR_LOOP_QUIT) {
        clearScreen();
        gotoxy(0, 0);
    }

    return E.loopCode;
}

static void editorSetupEditBuf(void)
{
    if (!hasEditBuf) {
        editorRowAt(E.cf.cy, &currentRow);
        editBufPopulate(currentRow.firstTextChunk);
        hasEditBuf = 1;
    }
}

/*** init ***/

void initEditor() {
    E.loopCode = EDITOR_LOOP_CONTINUE;
    E.last_key_esc = 0;
    E.statusmsg[0] = '\0';
    E.statusmsg_dirty = 0;
    E.anyDirtyRows = 1;

    E.firstFileChunk = 0;
    memset(&E.cf, 0, sizeof(efile));
    memset(&E.selection, 0, sizeof(fileselection));

    E.screenrows = 25;
#ifdef __MEGA65__
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
    E.clipboard = 0;

    memset(E.statusbar, ' ', E.screencols);

    initTitleScreen();

#ifdef __C128__
    fast();
#endif
    setupScreenCols();
    editorSetDefaultStatusMessage();
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
    E.cf.inSelection = 0;
    allocChunk(&E.cf.selectionChunk);
    E.selection.selectionX = E.selection.selectionY = 0;
    E.selection.startHX = E.selection.startHY = 0;
    E.selection.endHX = E.selection.endHY = 0;
    storeChunk(E.cf.fileChunk, (unsigned char *)&E.cf);
    storeChunk(E.cf.selectionChunk, &E.selection);
}

void unInitFile(void)
{
    freeChunk(E.cf.fileChunk);
    freeChunk(E.cf.selectionChunk);
    E.firstFileChunk = E.cf.nextFileChunk;
    if (E.firstFileChunk) {
        retrieveChunk(E.firstFileChunk, &E.cf);
    } else {
        E.cf.fileChunk = 0;
    }
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

// Returns 0 if STOP was pressed
char promptForOpenFilename(char *filename, size_t filenameLen) {
    clearStatusRow();

    if (editorPrompt(filename, filenameLen, "Open file: ") == 0) {
        editorSetDefaultStatusMessage();
        return 0;
    }

    return 1;
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

