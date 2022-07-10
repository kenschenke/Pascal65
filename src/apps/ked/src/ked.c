/*** includes ***/

#include <ctype.h>
#include <errno.h>
#include <conio.h>
#include <c128.h>
// #include <fcntl.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
// #include <sys/ioctl.h>
// #include <sys/types.h>
// #include <termios.h>
#include <time.h>
// #include <unistd.h>

/**
 * TODO:
 * 
 * Load and save files
 * Fix editorUpdateRow
 * Fix find + make case insensitive
 * Drop "Kilo" name
 * Support for 40/80 columns
 * Change the unsaved exit procedure to ask a confirmation question
 * Help page
 * Disable syntax highlighting code on C128
 * Abstract the screen routines behind platform-agnostic functions
 *     and disable C128 code at compile time on Mega65
 * 
 */

void __fastcall__ clearScreen128(void);
void __fastcall__ initScreen128(void);
void __fastcall__ setScreenBg128(char bg);
void __fastcall__ drawRow128(char row, char len,
    char *buf, unsigned char *rev);

/*** defines ***/

#define KILO_VERSION "0.0.1"
#define KILO_TAB_STOP 4
#define KILO_QUIT_TIMES 3

#define CTRL_KEY(k) ((k) & 0x1f)

enum editorKey {
    BACKSPACE = 127,
    DEL_KEY = 1000,
    HOME_KEY,
    END_KEY,
    PAGE_UP,
    PAGE_DOWN,
    DEL_SOL_KEY,
    DEL_EOL_KEY,
    DEL_LINE_KEY,
    INS_LINE_KEY,
    SCROLL_UP_KEY,
    SCROLL_DOWN_KEY,
    SCROLL_TOP_KEY,
    SCROLL_BOTTOM_KEY,
    MARK_KEY,
    PASTE_KEY,
    SELECT_ALL_KEY,
};

enum editorHighlight {
    HL_NORMAL = 0,
    HL_COMMENT,
    HL_MLCOMMENT,
    HL_KEYWORD1,
    HL_KEYWORD2,
    HL_STRING,
    HL_NUMBER,
    HL_MATCH,
};

#define HL_HIGHLIGHT_NUMBERS (1<<0)
#define HL_HIGHLIGHT_STRINGS (1<<1)

/*** data ***/

struct editorSyntax {
    char *filetype;
    char **filematch;
    char **keywords;
    char *singleline_comment_start;
    char *multiline_comment_start;
    char *multiline_comment_end;
    int flags;
};

typedef struct erow {
    int idx;
    int size;
    char *chars;
    unsigned char *hl;
    unsigned char *rev;             // bit 7 is high for highlighted text
    int hl_open_comment;
} erow;

struct editorConfig {
    int cx, cy;                     // cursor X and Y
    int rowoff;                     // top row on screen
    int coloff;                     // left-most column on screen
    int screenrows;                 // # of rows on display
    int screencols;                 // # of columns
    int numrows;                    // # of lines in file
    int in_selection;               // non-zero if selection is on
    int sx, sy;                     // selection anchor point for cursor
                                    // (position of cursor when selection activated)
    int shx, shy;                   // start selection highlight X and Y
    int ehx, ehy;                   // end selection highlight X and Y
    int last_shy, last_ehy;         // shy and ehy before cursor moved
                                    // (used to refresh highlighted rows)
    erow *row;                      // text data (array)
    char *clipboard;
    int dirty;                      // non-zero if file is modified
    char quit;                      // non-zero when user selects quit command
    char *dirtyScreenRows;          // array: non-zero if screen row is dirty
    int last_key_esc;               // non-zero if last key was ESC
    char *filename;
    char statusmsg[80];
    char *statusbar;
    unsigned char *statusbarrev;
    time_t statusmsg_time;
    char statusmsg_dirty;
    struct editorSyntax *syntax;
    // struct termios orig_termios;
};

struct editorConfig E;

/*** file types ***/

char *C_HL_extensions[] = {".c", ".h", ".cpp", NULL};
char *C_HL_keywords[] = {
  "switch", "if", "while", "for", "break", "continue", "return", "else",
  "struct", "union", "typedef", "static", "enum", "class", "case",
  "int|", "long|", "double|", "float|", "char|", "unsigned|", "signed|",
  "void|", NULL
};

struct editorSyntax HLDB[] = {
    {
        "c",
        C_HL_extensions,
        C_HL_keywords,
        "//", "/*", "*/",
        HL_HIGHLIGHT_NUMBERS | HL_HIGHLIGHT_STRINGS,
    },
};

#define HLDB_ENTRIES (sizeof(HLDB) / sizeof(HLDB[0]))

/*** prototypes ***/

void editorSetRowDirty(erow *row);
void editorSetStatusMessage(const char *fmt, ...);
void editorRefreshScreen();
char *editorPrompt(char *prompt, void (*callback)(char *, int));

/*** terminal ***/

void die(const char *s) {
    clrscr();
    gotoxy(0, 0);

    printf("%s\n", s);
    exit(1);
}

#if 0
int showKeyCodes() {
    int nread;
    char c;
    while ((nread = read(STDIN_FILENO, &c, 1)) != 1) {
        if (nread == -1 && errno != EAGAIN) die("read");
    }

    if (c == '\x1b') {
        char seq[3];
        seq[0] = seq[1] = seq[2] = 0;

        if (read(STDIN_FILENO, &seq[0], 1) != 1) return '\x1b';
        if (read(STDIN_FILENO, &seq[1], 1) != 1) return '\x1b';

        if (seq[0] == '[') {
            if (seq[1] >= '0' && seq[1] <= '9')
                if (read(STDIN_FILENO, &seq[2], 1) != 1) printf("ESC\r\n");
        }

        printf("seq = %d %d %d\r\n", seq[0], seq[1], seq[2]);
    } else {
        printf("%d\r\n", c);
    }

    return c == 'q';
}
#endif

int editorReadKey() {
    char c = cgetc();

    if (c == CH_ESC) {
        E.last_key_esc = 1;
        return c;
    }

    if (E.last_key_esc) {
        E.last_key_esc = 0;
        switch (c) {
            case 'a':
            case 'A':
                return SELECT_ALL_KEY;

            case 'j':
            case 'J':
                return HOME_KEY;
            
            case 'k':
            case 'K':
                return END_KEY;

            case 'p':
            case 'P':
                return DEL_SOL_KEY;

            case 'q':
            case 'Q':
                return DEL_EOL_KEY;
            
            case 'd':
            case 'D':
                return DEL_LINE_KEY;

            case 'i':
            case 'I':
                return INS_LINE_KEY;

            case 'v':
            case 'V':
                return SCROLL_UP_KEY;

            case 'w':
            case 'W':
                return SCROLL_DOWN_KEY;

            case 'b':
            case 'B':
                return SCROLL_TOP_KEY;

            case 'e':
            case 'E':
                return SCROLL_BOTTOM_KEY;

            case 'y':
            case 'Y':
                return MARK_KEY;

            case 'o':
            case 'O':
                return PASTE_KEY;
            
            case CH_CURS_UP:
                return PAGE_UP;
            
            case CH_CURS_DOWN:
                return PAGE_DOWN;
        }
    }

    return c;
}

/*** syntax highlighting ***/

int is_separator(int c) {
    return isspace(c) || c == '\0' || strchr(",.()+-/*=~%<>[];", c) != NULL;
}

void editorUpdateSyntax(erow *row) {
    char **keywords;
    char *scs, *mcs, *mce;
    int scs_len, mcs_len, mce_len;
    int prev_sep, in_string, in_comment, i, changed;

    row->hl = realloc(row->hl, row->size);
    memset(row->hl, HL_NORMAL, row->size);

    if (E.syntax == NULL) return;

    keywords = E.syntax->keywords;

    scs = E.syntax->singleline_comment_start;
    mcs = E.syntax->multiline_comment_start;
    mce = E.syntax->multiline_comment_end;

    scs_len = scs ? strlen(scs) : 0;
    mcs_len = mcs ? strlen(mcs) : 0;
    mce_len = mce ? strlen(mce) : 0;

    prev_sep = 1;
    in_string = 0;
    in_comment = (row->idx > 0 && E.row[row->idx - 1].hl_open_comment);

    i = 0;
    while (i < row->size) {
        char c = row->chars[i];
        unsigned char prev_hl = (i > 0) ? row->hl[i - 1] : HL_NORMAL;

        if (scs_len && !in_string && !in_comment) {
            if (!strncmp(&row->chars[i], scs, scs_len)) {
                memset(&row->hl[i], HL_COMMENT, row->size - i);
                break;
            }
        }

        if (mcs_len && mce_len && !in_string) {
            if (in_comment) {
                row->hl[i] = HL_MLCOMMENT;
                if (!strncmp(&row->chars[i], mce, mce_len)) {
                    memset(&row->hl[i], HL_MLCOMMENT, mce_len);
                    i += mce_len;
                    in_comment = 0;
                    prev_sep = 1;
                    continue;
                } else {
                    ++i;
                    continue;
                }
            } else if (!strncmp(&row->chars[i], mcs, mcs_len)) {
                memset(&row->hl[i], HL_MLCOMMENT, mcs_len);
                i += mcs_len;
                in_comment = 1;
                continue;
            }
        }

        if (E.syntax->flags & HL_HIGHLIGHT_STRINGS) {
            if (in_string) {
                row->hl[i] = HL_STRING;
                if (c == '\\' && i + 1 < row->size) {
                    row->hl[i + 1] = HL_STRING;
                    i += 2;
                    continue;
                }
                if (c == in_string) in_string = 0;
                ++i;
                prev_sep = 1;
                continue;
            } else {
                if (c == '"' || c == '\'') {
                    in_string = c;
                    row->hl[i] = HL_STRING;
                    ++i;
                    continue;
                }
            }
        }

        if (E.syntax->flags & HL_HIGHLIGHT_NUMBERS) {
            if ((isdigit(c) && (prev_sep || prev_hl == HL_NUMBER)) ||
                (c == '.' && prev_hl == HL_NUMBER)) {
                row->hl[i] = HL_NUMBER;
                ++i;
                prev_sep = 0;
                continue;
            }
        }

        if (prev_sep) {
            int j;
            for (j = 0; keywords[j]; ++j) {
                int klen = strlen(keywords[j]);
                int kw2 = keywords[j][klen - 1] == '|';
                if (kw2) klen--;

                if (!strncmp(&row->chars[i], keywords[j], klen) &&
                    is_separator(row->chars[i + klen])) {
                        memset(&row->hl[i], kw2 ? HL_KEYWORD2 : HL_KEYWORD1, klen);
                        i += klen;
                        break;
                    }
            }
            if (keywords[j] != NULL) {
                prev_sep = 0;
                continue;
            }
        }

        prev_sep = is_separator(c);
        ++i;
    }

    changed = (row->hl_open_comment != in_comment);
    row->hl_open_comment = in_comment;
    if (changed && row->idx + 1 < E.numrows)
        editorUpdateSyntax(&E.row[row->idx + 1]);
}

int editorSyntaxToColor(int hl) {
    switch (hl) {
        case HL_COMMENT:
        case HL_MLCOMMENT: return 36;
        case HL_KEYWORD1: return 33;
        case HL_KEYWORD2: return 32;
        case HL_STRING: return 35;
        case HL_NUMBER: return 31;
        case HL_MATCH: return 34;
        default: return 37;
    }
}

void editorSelectSyntaxHighlight() {
    char *ext;
    unsigned int j;
    int filerow;

    E.syntax = NULL;
    if (E.filename == NULL) return;

    ext = strrchr(E.filename, '.');

    for (j = 0; j < HLDB_ENTRIES; ++j) {
        struct editorSyntax *s = &HLDB[j];
        unsigned int i = 0;
        while (s->filematch[i]) {
            int is_ext = (s->filematch[i][0] == '.');
            if ((is_ext && ext && !strcmp(ext, s->filematch[i])) ||
                (!is_ext && strstr(E.filename, s->filematch[i]))) {
                    E.syntax = s;

                    for (filerow = 0; filerow < E.numrows; ++filerow) {
                        editorUpdateSyntax(&E.row[filerow]);
                    }

                    return;
                }
            ++i;
        }
    }
}

/*** row operations ***/

void editorUpdateRow(erow *row) {
#if 0
    int tabs = 0;
    int j, idx;
    char *buf;

    for (j = 0; j < row->size; ++j) {
        if (row->chars[j] == '\t') tabs++;
    }

    buf = malloc(row->size + tabs*(KILO_TAB_STOP-1) + 1);

    idx = 0;
    for (j = 0; j < row->size; ++j) {
        if (row->chars[j] == '\t') {
            buf[idx++] = ' ';
            while (idx % KILO_TAB_STOP != 0) buf[idx++] = ' ';
        } else {
            buf[idx++] = row->chars[j];
        }
    }
    buf[idx] = '\0';

    row->chars = realloc(row->chars, idx);
    memcpy(row->chars, buf, idx);

    editorUpdateSyntax(row);
#endif
}

void editorDeleteToStartOfLine() {
    erow *row = &E.row[E.cy];
    int pos = E.cx;
    if (pos < 0 || pos >= row->size) {
        pos = 0;
    }

    memmove(row->chars, &row->chars[pos], row->size - pos);
    row->size -= pos;
    E.cx = 0;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.dirty++;
}

void editorDeleteToEndOfLine() {
    erow *row = &E.row[E.cy];
    int pos = E.cx;
    if (pos < 0 || pos >= row->size) {
        pos = row->size - 1;
    }

    row->size = pos;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.dirty++;
}

void editorInsertRow(int at, char *s, size_t len) {
    int j;

    if (at < 0 || at > E.numrows) return;
    
    E.row = realloc(E.row, sizeof(erow) * (E.numrows + 1));
    memmove(&E.row[at + 1], &E.row[at], sizeof(erow) * (E.numrows - at));
    for (j = at + 1; j < E.numrows; ++j) {
        E.row[j].idx++;
        editorSetRowDirty(&E.row[j]);
    }

    E.row[at].idx = at;

    E.row[at].size = len;
    E.row[at].chars = malloc(len + 1);
    memcpy(E.row[at].chars, s, len);
    E.row[at].chars[len] = '\0';

    E.row[at].rev = NULL;

    E.row[at].hl = NULL;
    E.row[at].hl_open_comment = 0;
    editorSetRowDirty(&E.row[at]);
    editorUpdateRow(&E.row[at]);

    E.numrows++;
    E.dirty++;
}

void editorFreeRow(erow *row) {
    free(row->chars);
    free(row->rev);
    free(row->hl);
}

void editorDelRow(int at) {
    int j;

    if (at < 0 || at >= E.numrows) return;
    editorFreeRow(&E.row[at]);
    memmove(&E.row[at], &E.row[at + 1], sizeof(erow) * (E.numrows - at  - 1));
    for (j = at; j < E.numrows - 1; j++) {
        E.row[j].idx--;
        editorSetRowDirty(&E.row[j]);
    }
    E.numrows--;
    E.dirty++;
}

void editorRowInsertChar(erow *row, int at, int c) {
    if (at < 0 || at > row->size) at = row->size;
    row->chars = realloc(row->chars, row->size + 2);
    row->rev = realloc(row->rev, row->size + 1);
    memset(row->rev, 0, row->size + 1);
    memmove(&row->chars[at + 1], &row->chars[at], row->size - at + 1);
    row->size++;
    row->chars[at] = c;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.dirty++;
}

void editorRowInsertString(erow *row, int at, char *s, size_t len) {
    row->chars = realloc(row->chars, row->size + len + 1);
    row->rev = realloc(row->rev, row->size + len);
    memset(row->rev, 0, row->size + len);
    memmove(&row->chars[at + len], &row->chars[at], row->size - at + 1);
    memcpy(&row->chars[at + 1], s, len);
    row->size += len;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.dirty++;
}

void editorRowAppendString(erow *row, char *s, size_t len) {
    row->chars = realloc(row->chars, row->size + len + 1);
    row->rev = realloc(row->rev, row->size + len);
    memset(row->rev, 0, row->size + len);
    memcpy(&row->chars[row->size], s, len);
    row->size += len;
    row->chars[row->size] = '\0';
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.dirty++;
}

void editorRowDelChars(erow *row, int at, int length) {
    if (at < 0 || at + length - 1 >= row->size) return;
    memmove(&row->chars[at], &row->chars[at + length], row->size - at - length);
    row->size -= length;
    editorUpdateRow(row);
    editorSetRowDirty(row);
    E.dirty++;
}

void editorSetAllRowsDirty() {
    int i;
    for (i = 0; i < E.screenrows; ++i) E.dirtyScreenRows[i] = 1;
}

void editorSetRowDirty(erow *row) {
    int i = row->idx - E.rowoff;
    if (i < 0 || i >= E.screenrows) {
        // row is not visible - ignore
        return;
    }

    E.dirtyScreenRows[i] = 1;
}

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
    while (E.cx % KILO_TAB_STOP) editorInsertChar(' ');
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

/*** editor selection, copy, paste ***/

void editorCalcSelection() {
    int y;
    erow *row;

    if (!E.in_selection) return;

    if (E.cy < E.sy || (E.cy == E.sy && E.cx < E.sx)) {
        // The cursor is before the anchor point.
        // The cursor is the starting point of highlight
        // and the anchor point is the end.
        E.shx = E.cx;
        E.shy = E.cy;
        E.ehx = E.sx;
        E.ehy = E.sy;
    } else {
        // The cursor is after the anchor point.
        // The anchor point is the starting point of highlight
        // and the cursor is the end.
        E.shx = E.sx;
        E.shy = E.sy;
        E.ehx = E.cx;
        E.ehy = E.cy;
    }

    // Mark the highlighted rows

    // Start by un-marking rows before the starting and
    // after the ending row.
    if (E.last_shy != -1 && E.last_shy < E.shy) {
        for (y = E.last_shy; y < E.shy; ++y) {
            if (E.row[y].rev) memset(E.row[y].rev, 0, E.row[y].size);
            editorSetRowDirty(&E.row[y]);
        }
    }
    if (E.last_ehy > E.ehy) {
        for (y = E.ehy + 1; y <= E.last_ehy; ++y) {
            if (E.row[y].rev) memset(E.row[y].rev, 0, E.row[y].size);
            editorSetRowDirty(&E.row[y]);
        }
    }

    // Do the first selected row

    row = &E.row[E.shy];
    if (row->rev == NULL) row->rev = malloc(row->size);
    memset(row->rev, 0, row->size);
    memset(row->rev + E.shx, 128,
        E.shy == E.ehy ? E.ehx - E.shx + 1 : row->size - E.shx);
    editorSetRowDirty(&E.row[E.shy]);

    // Do the rows up through the last

    for (y = E.shy + 1; y <= E.ehy; ++y) {
        if (E.row[y].rev == NULL) E.row[y].rev = malloc(E.row[y].size);
        memset(E.row[y].rev, 128, E.row[y].size);
        editorSetRowDirty(&E.row[y]);
    }

    // Clear the highlight after the last selected character on the last line

    row = &E.row[E.ehy];
    y = row->size - E.ehx - 1;
    if (y > 0 && row->rev) memset(row->rev + E.ehx + 1, 0, y);
    editorSetRowDirty(&E.row[E.ehy]);

    // Finally, save this selection as the last selected

    E.last_shy = E.shy;
    E.last_ehy = E.ehy;
}

void editorClearSelection() {
    int y;
    for (y = E.shy; y <= E.ehy; ++y) {
        if (E.row[y].rev) memset(E.row[y].rev, 0, E.row[y].size);
        editorSetRowDirty(&E.row[y]);
    }

    E.in_selection = 0;
    E.sx = E.sy = 0;
    E.shx = E.shy = 0;
    E.ehx = E.ehy = 0;
    E.last_shy = E.last_ehy = -1;  // -1 means invalid value
}

// Copies the contents of the selected text
// to a buffer supplied by the caller.  If
// the selection continues to another line,
// a newline is placed in the buffer.

int editorCopyClipboard(char *buf) {
    int len = 0, x1, x2, y = E.shy;
    int boff = 0;  // buffer offset
    erow *row;

    do {
        row = &E.row[y];
        // If this is the first row of the selection
        // start counting at shx, otherwise start at
        // the first column.
        x1 = y == E.shy ? E.shx : 0;
        // If this is the last row of the selection
        // stop counting at ehx, otherwise stop at
        // the last column.
        x2 = y == E.ehy ? E.ehx : row->size;
        len += x2 - x1;
        // If the caller supplied a buffer, copy
        // the contents of this row into the buffer.
        if (buf) {
            memcpy(buf+boff, row->chars+x1, x2-x1);
            boff += x2 - x1;
            // Add a newline if this is not the last row
            // in the selection.
            if (y != E.ehy) buf[boff++] = '\n';
        }
        // Account for the newline if the selection
        // continues to the next row.
        len += y == E.ehy ? 0 : 1;
        y++;
    } while (y <= E.ehy);

    if (buf) buf[boff] = 0; 
    return len + 1;     // add one for the NULL terminator
}

void editorCopySelection() {
    int len = editorCopyClipboard(NULL);
    E.clipboard = realloc(E.clipboard, len);
    editorCopyClipboard(E.clipboard);
}

void editorDeleteSelection() {
    int y = E.ehy, x1, x2;
    erow *row;

    do {
        row = &E.row[y];
        // If this is the starting or ending row of the selection,
        // see if all or only part of the row is being deleted.
        if (y == E.shy || y == E.ehy) {
            x1 = y == E.shy && E.shx > 0 ? E.shx : 0;
            x2 = y == E.ehy && E.ehx < row->size ? E.ehx : row->size;
            if (x1 == 0 && x2 == row->size) {
                // delete the entire row
                editorDelRow(y);
            } else {
                editorRowDelChars(row, x1, x2 - x1);
                E.cx = E.shx;
            }
        } else {
            editorDelRow(y);
        }
        --y;
    } while (y >= E.shy);

    E.cy = E.shy;

    // If the last row was not completely deleted,
    // append the remainder to the row above.
    if (y > 0 && E.shy != E.ehy && E.ehx > 0 && E.ehx != E.row[y].size) {
        row = &E.row[E.shy+1];
        editorRowAppendString(&E.row[E.shy], row->chars, row->size);
        editorDelRow(E.shy+1);
    }
}

void editorPasteClipboard() {
    char *s = E.clipboard, *e;  // start and end of current line
    int x = E.cx, y = E.cy;
    erow *row;

    if (E.clipboard == NULL) return;

    // When the contents of the clipboard were copied, newline
    // characters were placed at new lines.  To paste, the loop
    // will iterate through the clipboard and when it sees a newline,
    // it inserts a new line into the file.

    while (*s) {
        row = &E.row[y];
        e = strchr(s, '\n');
        if (e == NULL) {
            // Last line in the clipboard.  Insert the remaining
            // characters and stop.
            editorRowInsertString(row, x-1, s, strlen(s));
            E.cx += strlen(s);
            break;
        }

        // editorRowInsertString(row, x, s, e-s);
        editorInsertRow(y++, s, e-s);
        E.cy++;
        s = e + 1;
    }
}

/*** file i/o ***/

char *editorRowsToString(int *buflen) {
    int totlen = 0;
    int j;
    char *buf, *p;

    for (j = 0; j < E.numrows; ++j) {
        totlen += E.row[j].size + 1;
    }
    *buflen = totlen;

    buf = malloc(totlen);
    p = buf;
    for (j = 0; j < E.numrows; ++j) {
        memcpy(p, E.row[j].chars, E.row[j].size);
        p += E.row[j].size;
        *p = '\n';
        p++;
    }

    return buf;
}

# if 0
void editorOpen(const char *filename) {
    FILE *fp;
    char *line = NULL;
    size_t linecap = 0;
    ssize_t linelen;

    free(E.filename);
    E.filename = strdup(filename);

    editorSelectSyntaxHighlight();

    fp = fopen(filename, "r");
    if (!fp) die("fopen");

    while ((linelen = getline(&line, &linecap, fp)) != -1) {
        while (linelen > 0 && (line[linelen -1] == '\n' ||
                               line[linelen -1] == '\r'))
            linelen--;
        editorInsertRow(E.numrows, line, linelen);
    }
    free(line);
    fclose(fp);
    E.dirty = 0;
}

void editorSave() {
    if (E.filename == NULL) {
        E.filename = editorPrompt("Save as: %s", NULL);
        if (E.filename == NULL) {
            editorSetStatusMessage("Save aborted");
            return;
        }
        editorSelectSyntaxHighlight();
    }

    int len;
    char *buf = editorRowsToString(&len);

    int fd = open(E.filename, O_RDWR | O_CREAT, 0644);
    if (fd != -1) {
        if (ftruncate(fd, len) != -1) {
            if (write(fd, buf, len) == len) {
                close(fd);
                free(buf);
                E.dirty = 0;
                editorSetStatusMessage("%d bytes written to disk", len);
                return;
            }
        }
        close(fd);
    }

    free(buf);
    editorSetStatusMessage("Can't save! I/O error %s", strerror(errno));
}
#endif

/*** find ***/

void editorFindCallback(char *query, int key) {
    static int last_match = -1;
    static int direction = 1;

    static int saved_hl_line;
    static char *saved_hl = NULL;

    int current, i;
    erow *row;
    char *match;

    if (saved_hl) {
        memcpy(E.row[saved_hl_line].hl, saved_hl, E.row[saved_hl_line].size);
        free(saved_hl);
        saved_hl = NULL;
    }

    if (key == '\r' || key == '\x1b') {
        last_match = -1;
        direction = 1;
        return;
    } else if (key == CH_CURS_RIGHT || key == CH_CURS_DOWN) {
        direction = 1;
    } else if (key == CH_CURS_LEFT || key == CH_CURS_UP) {
        direction = -1;
    } else {
        direction = 1;
        last_match = -1;
    }

    if (last_match == -1) direction = 1;
    current = last_match;
    for (i = 0; i < E.numrows; ++i) {
        current += direction;
        if (current == -1) current = E.numrows - 1;
        else if (current == E.numrows) current = 0;

        row = &E.row[current];
        match = strstr(row->chars, query);
        if (match) {
            last_match = current;
            E.cy = current;
            E.cx = match - row->chars;
            E.rowoff = E.numrows;

            saved_hl_line = current;
            saved_hl = malloc(row->size);
            memcpy(saved_hl, row->hl, row->size);
            memset(&row->hl[match - row->chars], HL_MATCH, strlen(query));
            break;
        }
    }
}

void editorFind() {
    int saved_cx = E.cx;
    int saved_cy = E.cy;
    int saved_coloff = E.coloff;
    int saved_rowoff = E.rowoff;

    char *query = editorPrompt("Search: %s (Use ESC/Arrows/Enter)",
        editorFindCallback);
    if (query) {
        free(query);
    } else {
        E.cx = saved_cx;
        E.cy = saved_cy;
        E.coloff = saved_coloff;
        E.rowoff = saved_rowoff;
    }
}

/*** output ***/

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
                drawRow128(y, buflen, banner, NULL);
                free(banner);
            }
        } else if (E.dirtyScreenRows[y]) {
            int len = E.row[filerow].size - E.coloff;
            if (len < 0) len = 0;
            if (len > E.screencols) len = E.screencols;
            drawRow128(y, len, &E.row[filerow].chars[E.coloff],
                &E.row[filerow].rev[E.coloff]);
            E.dirtyScreenRows[y] = 0;
        }
    }
}

void editorDrawStatusBar() {
    char status[80], rstatus[80];
    int len, rlen;

    memset(E.statusbar, ' ', E.screencols);

    len = snprintf(status, sizeof(status), "%.20s - %d lines %s",
        E.filename ? E.filename : "[No Name]", E.numrows,
        E.dirty ? "(modified)" : "");
    rlen = snprintf(rstatus, sizeof(rstatus), "%s | %d/%d",
        E.syntax ? E.syntax->filetype : "no ft", E.cy + 1, E.numrows);
    if (len > E.screencols) len = E.screencols;
    memcpy(E.statusbar, status, len);
    memcpy(E.statusbar + E.screencols - rlen, rstatus, rlen);

    drawRow128(E.screenrows, E.screencols, E.statusbar, E.statusbarrev);
}

void editorDrawMessageBar(void) {
    unsigned char *rev;
    int msglen = strlen(E.statusmsg);

    if (!E.statusmsg_dirty && E.statusmsg_time == 0) return;

    if (msglen > E.screencols) msglen = E.screencols;
    if (msglen && time(NULL) - E.statusmsg_time < 5) {
        rev = malloc(msglen);
        memset(rev, 0, msglen);
        drawRow128(E.screenrows+1, msglen, E.statusmsg, rev);
        free(rev);
    } else {
        rev = malloc(E.screencols);
        memset(rev, 0, E.screencols);
        memset(E.statusmsg, ' ', E.screencols);
        drawRow128(E.screenrows+1, E.screencols, E.statusmsg, rev);
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
    static int quit_times = KILO_QUIT_TIMES;

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

    quit_times = KILO_QUIT_TIMES;
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
    E.statusmsg[0] = '\0';
    E.statusmsg_time = 0;
    E.statusmsg_dirty = 0;
    E.syntax = NULL;

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
    videomode(VIDEOMODE_80x25);
    initScreen128();
    setScreenBg128(2);
}

int showKeyCodes(void) {
    char buf[3+1];
    unsigned char rev[3];
    char c = editorReadKey();
    if (c == 'q') {
        return 1;
    }

    sprintf(buf, "%3d", c);
    memset(rev, 0, 3);
    drawRow128(10, 3, buf, rev);
    return 0;
}

int main(int argc, char *argv[])
{
    int i, len;
    char buf[80];

    initEditor();
    if (argc >= 2) {
        // editorOpen(argv[1]);
    }

#if 0
    while (!showKeyCodes());
    return 0;
#endif

#if 1
    for (i = 1; i <= 46; ++i) {
        len = sprintf(buf, "%*sEditor Row %d", i % 50, " ", i);
        editorInsertRow(i-1, buf, len);
    }
    E.dirty = 0;
#endif

    editorSetStatusMessage("HELP: Ctrl-S = save | Ctrl-Q = quit | Ctrl-F = find");

    while (!E.quit) {
        editorRefreshScreen();
        editorProcessKeypress();
    }

    clearScreen128();
    gotoxy(0, 0);

    return 0;
}
