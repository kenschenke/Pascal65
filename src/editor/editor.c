#include "editor.h"

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifdef __C128__
#include <c128.h>
#endif
#include <conio.h>

struct editorConfig E;

static void editorDelChar(void);
static void editorInsertChar(int c);
static void editorInsertTab(void);
static void editorInsertNewLine(int spaces);
static void editorMoveCursor(int key);
static void editorProcessKeypress(void);

/*** editor operations ***/

static void editorDelChar(void) {
    erow *row;
    if (E.cf->cy == E.cf->numrows) return;
    if (E.cf->cx == 0 && E.cf->cy == 0) return;

    row = &E.cf->row[E.cf->cy];
    if (E.cf->cx > 0) {
        editorRowDelChars(row, E.cf->cx - 1, 1);
        E.cf->cx--;
    } else {
        E.cf->cx = E.cf->row[E.cf->cy - 1].size;
        editorRowAppendString(&E.cf->row[E.cf->cy - 1], row->chars, row->size);
        editorDelRow(E.cf->cy);
        E.cf->cy--;
    }
}

static void editorInsertChar(int c) {
    if (E.cf->cy == E.cf->numrows) {
        editorInsertRow(E.cf->numrows, "", 0);
    }
    editorRowInsertChar(&E.cf->row[E.cf->cy], E.cf->cx, c);
    E.cf->cx++;
}

static void editorInsertTab(void) {
    editorInsertChar(' ');
    while (E.cf->cx % EDITOR_TAB_STOP) editorInsertChar(' ');
}

static void editorInsertNewLine(int spaces) {
    if (E.cf->cx == 0) {
        editorInsertRow(E.cf->cy, "", 0);
    } else {
        erow *row = &E.cf->row[E.cf->cy];
        editorInsertRow(E.cf->cy + 1, &row->chars[E.cf->cx], row->size - E.cf->cx);
        row = &E.cf->row[E.cf->cy];
        row->size = E.cf->cx;
        row->chars[row->size] = '\0';
        editorUpdateRow(row);
    }
    E.cf->cy++;
    if (E.cf->cx) {
        E.cf->cx = 0;
        while (spaces--) editorInsertChar(' ');
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

static void editorMoveCursor(int key) {
    int rowlen;
    erow *row = (E.cf->cy >= E.cf->numrows) ? NULL : &E.cf->row[E.cf->cy];

    switch (key) {
        case CH_CURS_LEFT:
            if (E.cf->cx != 0) {
                E.cf->cx--;
            } else if (E.cf->cy > 0) {
                E.cf->cy--;
                E.cf->cx = E.cf->row[E.cf->cy].size;
            }
            break;
        case CH_CURS_RIGHT:
            if (row && E.cf->cx < row->size) {
                E.cf->cx++;
            } else if (row && E.cf->cx == row->size) {
                E.cf->cy++;
                E.cf->cx = 0;
            }
            break;
        case CH_CURS_UP:
            if (E.cf->cy != 0) {
                E.cf->cy--;
            }
            break;
        case CH_CURS_DOWN:
            if (E.cf->cy < E.cf->numrows - 1) {
                E.cf->cy++;
            }
            break;
    }

    row = (E.cf->cy >= E.cf->numrows) ? NULL : &E.cf->row[E.cf->cy];
    rowlen = row ? row->size : 0;
    if (E.cf->cx > rowlen) {
        E.cf->cx = rowlen;
    }

    if (E.cf->in_selection) editorCalcSelection();
}

static void editorProcessKeypress(void) {
    static int quit_times = EDITOR_QUIT_TIMES;

    int times;
    int c = editorReadKey();

    // Some keys have special meaning if selection mode is on.
    if (E.cf && E.cf->in_selection) {
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
            if (E.cf) {
                // Count the number of spaces at the beginning of this line
                int i = 0;
                erow *row = &E.cf->row[E.cf->cy];
                if (E.cf->cx < row->size) editorSetRowDirty(row);
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
            if (E.cf) editorInsertTab();
            break;

        case CH_INS:
            if (E.cf) {
                editorInsertChar(' ');
                E.cf->cx--;
            }
            break;

        case CTRL_KEY('x'):
            if (E.cf && E.cf->dirty && quit_times > 0) {
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
            if (E.cf) E.cf->cx = 0;
            break;

        case CH_HOME:
            if (E.cf) {
                if (E.cf->cx == 0 && E.cf->cy == E.cf->rowoff) {
                    if (E.cf->rowoff != 0) {
                        E.cf->rowoff = 0;
                        editorSetAllRowsDirty();
                    }
                    E.cf->cy = 0;
                } else {
                    E.cf->cx = 0;
                    E.cf->cy = E.cf->rowoff;
                }
            }
            break;

        case CTRL_KEY('k'):
        case END_KEY:
            if (E.cf && E.cf->cy < E.cf->numrows)
                E.cf->cx = E.cf->row[E.cf->cy].size;
            break;

        case DEL_SOL_KEY:
            if (E.cf) editorDeleteToStartOfLine();
            break;

        case DEL_EOL_KEY:
            if (E.cf) editorDeleteToEndOfLine();
            break;
        
        case CTRL_KEY('d'):
        case DEL_LINE_KEY:
            if (E.cf) {
                E.cf->cx = 0;
                editorDelRow(E.cf->cy);
            }
            break;

        case INS_LINE_KEY:
            if (E.cf) {
                E.cf->cx = 0;
                editorInsertNewLine(0);
                E.cf->cy--;
            }
            break;

        case CTRL_KEY('v'):
        case SCROLL_UP_KEY:
            if (E.cf && E.cf->rowoff > 0) {
                --E.cf->rowoff;
                if (E.cf->cy - E.cf->rowoff > E.screenrows - 1) {
                    E.cf->cy = E.cf->rowoff + E.screenrows - 1;
                }
                editorSetAllRowsDirty();
            }
            break;

        case CTRL_KEY('w'):
        case SCROLL_DOWN_KEY:
            if (E.cf && E.cf->rowoff + E.screenrows < E.cf->numrows) {
                ++E.cf->rowoff;
                if (E.cf->cy < E.cf->rowoff) {
                    E.cf->cy = E.cf->rowoff;
                }
                editorSetAllRowsDirty();
            }
            break;
        
        case CTRL_KEY('b'):
        case SCROLL_TOP_KEY:
            if (E.cf && E.cf->rowoff != 0) {
                E.cf->rowoff = 0;
                E.cf->cy = 0;
                editorSetAllRowsDirty();
            }
            break;

        case CTRL_KEY('e'):
        case SCROLL_BOTTOM_KEY:
            if (E.cf) {
                int newoff = E.cf->numrows - E.screenrows;
                if (newoff < 0) newoff = 0;
                if (E.cf->rowoff != newoff) {
                    E.cf->rowoff = newoff;
                    editorSetAllRowsDirty();
                }
                E.cf->cy = E.cf->numrows - 1;
            }
            break;

        case CTRL_KEY('f'):
            if (E.cf) editorFind();
            break;

        case CH_DEL:
        case CTRL_KEY('h'):
        case DEL_KEY:
            if (E.cf) {
                if (c == DEL_KEY) editorMoveCursor(CH_CURS_RIGHT);
                editorDelChar();
            }
            break;

        case CH_CURS_UP:
        case CH_CURS_DOWN:
        case CH_CURS_LEFT:
        case CH_CURS_RIGHT:
            if (E.cf) editorMoveCursor(c);
            break;

        case CTRL_KEY('l'):
        case '\x1b':
            break;

        case CTRL_KEY('n'):
        case CTRL_KEY('p'):
        case PAGE_UP:
        case PAGE_DOWN:
            if (E.cf) {
                if (c == CTRL_KEY('n')) c = PAGE_DOWN;
                if (c == CTRL_KEY('p')) c = PAGE_UP;
                if (c == PAGE_UP) {
                    E.cf->cy = E.cf->rowoff;
                } else if (c == PAGE_DOWN) {
                    E.cf->cy = E.cf->rowoff + E.screenrows - 1;
                    if (E.cf->cy > E.cf->numrows) E.cf->cy = E.cf->numrows;
                }

                times = E.screenrows;
                while (times--)
                    editorMoveCursor(c == PAGE_UP ? CH_CURS_UP : CH_CURS_DOWN);
            }
            break;

        case CTRL_KEY('y'):
        case MARK_KEY:
            if (E.cf) {
                E.cf->in_selection = 1;
                E.cf->sx = E.cf->cx;
                E.cf->sy = E.cf->cy;
                editorSetStatusMessage("'C' = copy, 'X' = cut, ESC = cancel");
            }
            break;

        case CTRL_KEY('o'):
        case PASTE_KEY:
            if (E.cf) editorPasteClipboard();
            break;
        
        case CTRL_KEY('a'):
        case SELECT_ALL_KEY:
            if (E.cf) {
                E.cf->in_selection = 1;
                E.cf->shx = E.cf->shy = 0;
                E.cf->cy = E.cf->numrows - 1;
                E.cf->cx = E.cf->row[E.cf->numrows-1].size;
                editorCalcSelection();
            }
            break;

        default:
            if (E.cf) editorInsertChar(c);
            break;
    }

    quit_times = EDITOR_QUIT_TIMES;
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
    E.clipboard = NULL;
    E.welcomePage = NULL;
    E.statusmsg[0] = '\0';
    E.statusmsg_time = 0;
    E.statusmsg_dirty = 0;
#ifdef SYNTAX_HIGHLIGHT
    E.cf->syntax = NULL;
#endif

    E.files = NULL;
    E.numfiles = 0;

    E.screenrows = 25;
    E.screencols = 80;
    E.screenrows -= 2;

    E.statusbar = malloc(E.screencols);
    memset(E.statusbar, ' ', E.screencols);
    E.statusbarrev = malloc(E.screencols);
    memset(E.statusbarrev, 128, E.screencols);

    fast();
    setupScreenCols();

    editorSetStatusMessage("HELP: Ctrl-S = save | Ctrl-Q = quit | Ctrl-F = find");
}

void initFile(struct editorFile *file) {
    file->cx = 0;
    file->cy = 0;
    file->rowoff = 0;
    file->coloff = 0;
    file->numrows = 0;
    file->row = NULL;
    file->dirty = 0;
    file->in_selection = 0;
    file->sx = 0;
    file->sy = 0;
    file->shx = file->shy = 0;
    file->ehx = file->ehy = 0;
    file->last_shy = file->last_ehy = -1;  // -1 means invalid value
    file->filename = NULL;
    file->readOnly = 0;

    file->dirtyScreenRows = malloc(E.screenrows);
    memset(file->dirtyScreenRows, 1, E.screenrows);
}

void setupScreenCols(void) {
    if (E.screencols == 80)
        videomode(VIDEOMODE_80x25);
    else
        videomode(VIDEOMODE_40x25);

    initScreen();
    setScreenBg(E.screencols == 40 ? COLOR_BLUE : 2);
}

