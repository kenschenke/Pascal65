#include "editor.h"

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifdef __C128__
#include <c128.h>
#endif
#include <conio.h>

struct editorConfig E;

/*** editor operations ***/

void editorInsertChar(int c) {
    if (E.cy == E.numrows) {
        editorInsertRow(E.numrows, "", 0);
    }
    editorRowInsertChar(&E.row[E.cy], E.cx, c);
    E.cx++;
}

void editorInsertTab() {
    editorInsertChar(' ');
    while (E.cx % EDITOR_TAB_STOP) editorInsertChar(' ');
}

void editorInsertNewLine(int spaces) {
    if (E.cx == 0) {
        editorInsertRow(E.cy, "", 0);
    } else {
        erow *row = &E.row[E.cy];
        editorInsertRow(E.cy + 1, &row->chars[E.cx], row->size - E.cx);
        row = &E.row[E.cy];
        row->size = E.cx;
        row->chars[row->size] = '\0';
        editorUpdateRow(row);
    }
    E.cy++;
    if (E.cx) {
        E.cx = 0;
        while (spaces--) editorInsertChar(' ');
    }
}

void editorDelChar() {
    erow *row;
    if (E.cy == E.numrows) return;
    if (E.cx == 0 && E.cy == 0) return;

    row = &E.row[E.cy];
    if (E.cx > 0) {
        editorRowDelChars(row, E.cx - 1, 1);
        E.cx--;
    } else {
        E.cx = E.row[E.cy - 1].size;
        editorRowAppendString(&E.row[E.cy - 1], row->chars, row->size);
        editorDelRow(E.cy);
        E.cy--;
    }
}

/*** input ***/

char *editorPrompt(char *prompt, void (*callback)(char *, int)) {
    size_t bufsize = 128;
    char *buf = malloc(bufsize);

    size_t buflen = 0;
    int c;

    buf[0] = '\0';

    while (1) {
        editorSetStatusMessage(prompt, buf);
        editorRefreshScreen();
        c = editorReadKey();
        if (c == DEL_KEY || c == CTRL_KEY('h') || c == CH_DEL) {
            if (buflen != 0) buf[--buflen] = '\0';
        } else if (c == '\x1b') {
            editorSetStatusMessage("");
            if (callback) callback(buf, c);
            free(buf);
            return NULL;
        } else if (c == '\r') {
            if (buflen != 0) {
                editorSetStatusMessage("");
                if (callback) callback(buf, c);
                return buf;
            }
        } else if (!iscntrl(c) && c < 128) {
            if (buflen == bufsize - 1) {
                bufsize *= 2;
                buf = realloc(buf, bufsize);
            }
            buf[buflen++] = c;
            buf[buflen] = '\0';
        }

        if (callback) callback(buf, c);
    }
}

void editorMoveCursor(int key) {
    int rowlen;
    erow *row = (E.cy >= E.numrows) ? NULL : &E.row[E.cy];

    switch (key) {
        case CH_CURS_LEFT:
            if (E.cx != 0) {
                E.cx--;
            } else if (E.cy > 0) {
                E.cy--;
                E.cx = E.row[E.cy].size;
            }
            break;
        case CH_CURS_RIGHT:
            if (row && E.cx < row->size) {
                E.cx++;
            } else if (row && E.cx == row->size) {
                E.cy++;
                E.cx = 0;
            }
            break;
        case CH_CURS_UP:
            if (E.cy != 0) {
                E.cy--;
            }
            break;
        case CH_CURS_DOWN:
            if (E.cy < E.numrows - 1) {
                E.cy++;
            }
            break;
    }

    row = (E.cy >= E.numrows) ? NULL : &E.row[E.cy];
    rowlen = row ? row->size : 0;
    if (E.cx > rowlen) {
        E.cx = rowlen;
    }

    if (E.in_selection) editorCalcSelection();
}

void editorProcessKeypress() {
    static int quit_times = EDITOR_QUIT_TIMES;

    int times;
    int c = editorReadKey();

    // Some keys have special meaning if selection mode is on.
    if (E.in_selection) {
        switch (c) {
            case '\x1b':    // ESC
                editorClearSelection();
                editorSetStatusMessage("");
                break;
            
            case 'c':
            case 'C':       // copy
                editorCopySelection();
                editorClearSelection();
                editorSetStatusMessage("Selection copied");
                return;
            
            case 'x':
            case 'X':       // cut
                editorCopySelection();
                editorDeleteSelection();
                editorClearSelection();
                editorSetStatusMessage("Selection cut");
                return;
        }
    }

    switch (c) {
        case CH_ENTER:
            {
                // Count the number of spaces at the beginning of this line
                int i = 0;
                erow *row = &E.row[E.cy];
                if (E.cx < row->size) editorSetRowDirty(row);
                while (row->chars[i] && row->chars[i] == ' ') ++i;
                editorInsertNewLine(i);
            }
            break;
        
        case COL40_KEY:
            clearScreen();
            E.screencols = 40;
            setupScreenCols();
            editorSetAllRowsDirty();
            break;

        case COL80_KEY:
            clearScreen();
            E.screencols = 80;
            setupScreenCols();
            editorSetAllRowsDirty();
            break;

        case CH_F1:
            clearScreen();
            E.screencols = E.screencols == 80 ? 40 : 80;
            setupScreenCols();
            editorSetAllRowsDirty();
            break;
            break;
        
        case '\t':
            editorInsertTab();
            break;

        case CH_INS:
            editorInsertChar(' ');
            E.cx--;
            break;

        case CTRL_KEY('x'):
            if (E.dirty && quit_times > 0) {
                editorSetStatusMessage("WARNING!!! File has unsaved changes. "
                "Press Ctrl-E %d more times to quit.", quit_times);
                --quit_times;
                return;
            }
            E.quit = 1;
            break;
        
        case BACKARROW:
            editorSetStatusMessage("You pressed back arrow!");
            break;

#if 0
        case CTRL_KEY('s'):
            // editorSave();
            break;
#endif

        case CTRL_KEY('j'):
        case HOME_KEY:
            E.cx = 0;
            break;

        case CH_HOME:
            if (E.cx == 0 && E.cy == E.rowoff) {
                if (E.rowoff != 0) {
                    E.rowoff = 0;
                    editorSetAllRowsDirty();
                }
                E.cy = 0;
            } else {
                E.cx = 0;
                E.cy = E.rowoff;
            }
            break;

        case CTRL_KEY('k'):
        case END_KEY:
            if (E.cy < E.numrows)
                E.cx = E.row[E.cy].size;
            break;

        case DEL_SOL_KEY:
            editorDeleteToStartOfLine();
            break;

        case DEL_EOL_KEY:
            editorDeleteToEndOfLine();
            break;
        
        case CTRL_KEY('d'):
        case DEL_LINE_KEY:
            E.cx = 0;
            editorDelRow(E.cy);
            break;

        case INS_LINE_KEY:
            E.cx = 0;
            editorInsertNewLine(0);
            E.cy--;
            break;

        case CTRL_KEY('v'):
        case SCROLL_UP_KEY:
            if (E.rowoff > 0) {
                --E.rowoff;
                if (E.cy - E.rowoff > E.screenrows - 1) {
                    E.cy = E.rowoff + E.screenrows - 1;
                }
                editorSetAllRowsDirty();
            }
            break;

        case CTRL_KEY('w'):
        case SCROLL_DOWN_KEY:
            if (E.rowoff + E.screenrows < E.numrows) {
                ++E.rowoff;
                if (E.cy < E.rowoff) {
                    E.cy = E.rowoff;
                }
                editorSetAllRowsDirty();
            }
            break;
        
        case CTRL_KEY('b'):
        case SCROLL_TOP_KEY:
            if (E.rowoff != 0) {
                E.rowoff = 0;
                E.cy = 0;
                editorSetAllRowsDirty();
            }
            break;

        case CTRL_KEY('e'):
        case SCROLL_BOTTOM_KEY:
            {
                int newoff = E.numrows - E.screenrows;
                if (newoff < 0) newoff = 0;
                if (E.rowoff != newoff) {
                    E.rowoff = newoff;
                    editorSetAllRowsDirty();
                }
                E.cy = E.numrows - 1;
            }
            break;

        case CTRL_KEY('f'):
            editorFind();
            break;

        case CH_DEL:
        case CTRL_KEY('h'):
        case DEL_KEY:
            if (c == DEL_KEY) editorMoveCursor(CH_CURS_RIGHT);
            editorDelChar();
            break;

        case CH_CURS_UP:
        case CH_CURS_DOWN:
        case CH_CURS_LEFT:
        case CH_CURS_RIGHT:
            editorMoveCursor(c);
            break;

        case CTRL_KEY('l'):
        case '\x1b':
            break;

        case CTRL_KEY('n'):
        case CTRL_KEY('p'):
        case PAGE_UP:
        case PAGE_DOWN:
            {
                if (c == CTRL_KEY('n')) c = PAGE_DOWN;
                if (c == CTRL_KEY('p')) c = PAGE_UP;
                if (c == PAGE_UP) {
                    E.cy = E.rowoff;
                } else if (c == PAGE_DOWN) {
                    E.cy = E.rowoff + E.screenrows - 1;
                    if (E.cy > E.numrows) E.cy = E.numrows;
                }

                times = E.screenrows;
                while (times--)
                    editorMoveCursor(c == PAGE_UP ? CH_CURS_UP : CH_CURS_DOWN);
            }
            break;

        case CTRL_KEY('y'):
        case MARK_KEY:
            E.in_selection = 1;
            E.sx = E.cx;
            E.sy = E.cy;
            editorSetStatusMessage("'C' = copy, 'X' = cut, ESC = cancel");
            break;

        case CTRL_KEY('o'):
        case PASTE_KEY:
            editorPasteClipboard();
            break;
        
        case CTRL_KEY('a'):
        case SELECT_ALL_KEY:
            E.in_selection = 1;
            E.shx = E.shy = 0;
            E.cy = E.numrows - 1;
            E.cx = E.row[E.numrows-1].size;
            editorCalcSelection();
            break;

        default:
            editorInsertChar(c);
            break;
    }

    quit_times = EDITOR_QUIT_TIMES;
}

/*** init ***/

void initEditor() {
    E.cx = 0;
    E.cy = 0;
    E.rowoff = 0;
    E.coloff = 0;
    E.numrows = 0;
    E.row = NULL;
    E.dirty = 0;
    E.quit = 0;
    E.last_key_esc = 0;
    E.in_selection = 0;
    E.sx = 0;
    E.sy = 0;
    E.shx = E.shy = 0;
    E.ehx = E.ehy = 0;
    E.last_shy = E.last_ehy = -1;  // -1 means invalid value
    E.filename = NULL;
    E.clipboard = NULL;
    E.welcomePage = NULL;
    E.readOnly = 0;
    E.statusmsg[0] = '\0';
    E.statusmsg_time = 0;
    E.statusmsg_dirty = 0;
#ifdef SYNTAX_HIGHLIGHT
    E.syntax = NULL;
#endif

    E.screenrows = 25;
    E.screencols = 80;
    E.screenrows -= 2;

    E.dirtyScreenRows = malloc(E.screenrows);
    memset(E.dirtyScreenRows, 1, E.screenrows);

    E.statusbar = malloc(E.screencols);
    memset(E.statusbar, ' ', E.screencols);
    E.statusbarrev = malloc(E.screencols);
    memset(E.statusbarrev, 128, E.screencols);

    fast();
    setupScreenCols();
}

void setupScreenCols(void) {
    if (E.screencols == 80)
        videomode(VIDEOMODE_80x25);
    else
        videomode(VIDEOMODE_40x25);

    initScreen();
    setScreenBg(E.screencols == 40 ? COLOR_BLUE : 2);
}

