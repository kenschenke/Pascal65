#ifndef EDITOR_H
#define EDITOR_H

#include <stddef.h>
#include <chunks.h>

#define ECHUNK_LEN (CHUNK_LEN - 3)

#define EDITOR_TAB_STOP 4
#define EDITOR_QUIT_TIMES 3

/*** data ***/

typedef unsigned char UCHAR;

typedef struct erow {
    CHUNKNUM rowChunk;          // Chunk address for this erow record
    CHUNKNUM nextRowChunk;      // Chunk address for next erow record
    int idx;
    int size;
    CHUNKNUM firstTextChunk;    // Chunk address of first text data
    char unused[CHUNK_LEN - 6]; // so it fills a chunk
} erow;

typedef struct echunk {
    CHUNKNUM nextChunk;
    UCHAR bytesUsed;
    UCHAR bytes[ECHUNK_LEN];
} echunk;

struct editorFile {
    int cx, cy;                     // cursor X and Y
    unsigned rowoff;                // top row on screen
    unsigned coloff;                // left-most column on screen
    char in_selection;              // non-zero if selection is on
    int sx, sy;                     // selection anchor point for cursor
                                    // (position of cursor when selection activated)
    int shx, shy;                   // start selection highlight X and Y
    int ehx, ehy;                   // end selection highlight X and Y
    int last_shy, last_ehy;         // shy and ehy before cursor moved
                                    // (used to refresh highlighted rows)
    CHUNKNUM firstRowChunk;         // Chunk for first erow record
    unsigned numrows;               // # of lines in file
    char readOnly;                  // non-zero if file is read-only
    unsigned dirty;                 // non-zero if file is modified
    char *dirtyScreenRows;          // array: non-zero if screen row is dirty
    char *filename;
};

struct editorConfig {
    unsigned screenrows;            // # of rows on display
    unsigned screencols;            // # of columns
    struct editorFile *files;       // array of open files
    struct editorFile *cf;          // point to current file
    unsigned numfiles;              // # of open files
    char *clipboard;
    char *welcomePage;
    char quit;                      // non-zero when user selects quit command
    char last_key_esc;              // non-zero if last key was ESC
    char statusmsg[80];
    char *statusbar;
    unsigned char *statusbarrev;
    char statusmsg_dirty;
};

extern struct editorConfig E;

#define CTRL_KEY(k) ((k) & 0x1f)

enum editorKey {
    BACKARROW = 95,
    BACKSPACE = 127,
    F1_KEY = 241,
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
    COL40_KEY,
    COL80_KEY,
};

/*** file types ***/

/*** prototypes ***/

void clearCursor(void);
void clearScreen(void);
void drawRow(char row, char col, char len, char *buf, char isReversed);
void editorCalcSelection(void);
void editorClearSelection(void);
void editorCopySelection(void);
void editorDeleteSelection(void);
void editorDeleteToEndOfLine(void);
void editorDeleteToStartOfLine(void);
void editorDelRow(int at);
void initFile(struct editorFile *file);
void editorFind(void);
void editorInsertRow(int at, char *s, size_t len);
void editorPasteClipboard(void);
char *editorPrompt(char *prompt, void (*callback)(char *, int));
void editorRowAppendString(erow *row, char *s, size_t len);
char editorRowAt(int at, erow *row);
void editorRowDelChars(erow *row, int at, int length);
void editorRowInsertChar(erow *row, int at, int c);
void editorRowInsertString(erow *row, int at, char *s, size_t len);
char editorRowLastChunk(erow *row, CHUNKNUM *chunkNum, echunk *chunk);
char editorChunkAtX(erow *row, int at, int *chunkFirstCol, CHUNKNUM *chunkNum, echunk *chunk);
void editorOpen(const char *filename);
int editorReadKey(void);
void editorRun(void);
void editorSave(void);
void editorSetAllRowsDirty(void);
void editorSetRowDirty(erow *row);
void editorSetStatusMessage(const char *fmt, ...);
void editorRefreshScreen();
void editorUpdateRow(erow *row);
void initEditor(void);
#if __C128__
void setScreenBg(char bg);
#endif
void initScreen(void);
void renderCursor(void);
void setupScreenCols(void);

#if 0
typedef void (*f_updateStatusBar)(edstate *state);
typedef void (*f_keyPressed)(edstate *state, int key);
typedef void (*f_newFile)(edstate *state);
typedef void (*f_closeFile)(edstate *state, int file);
typedef void (*f_openFile)(edstate *state, char *filename);

typedef struct edstate {
    int mLeft, mRight, mTop, mBottom;   // margins
    int cx, cy;     // cursor X and Y (zero based)
    f_updateStatusBar updateStatusBar;
    f_keyPressed keyPressed;
    char *leftStatusMsg;
    char *rightStatusMsg;
    char *centerStatusMsg;
} edstate;

void initEditor(edstate *state);
#endif

#endif // end of EDITOR_H
