#ifndef EDITOR_H
#define EDITOR_H

#include <stddef.h>
#include <chunks.h>

#define ECHUNK_LEN (CHUNK_LEN - 3)

#define EDITOR_TAB_STOP 4

/*** callbacks ***/

typedef void (*f_showHelpPage)(void);
typedef void (*f_showWelcomePage)(void);
typedef void (*f_updateStatusBar)(void);
typedef char (*f_keyPressed)(int key);  // Return non-zero if key was handled
typedef char (*f_exitRequested)(void);  // Return non-zero if okay to exit

/*** data ***/

typedef unsigned char UCHAR;

typedef struct erow {
    CHUNKNUM rowChunk;          // Chunk address for this erow record
    CHUNKNUM nextRowChunk;      // Chunk address for next erow record
    int idx;
    int size;
    CHUNKNUM firstTextChunk;    // Chunk address of first text data
    char dirty;                 // Non-zero if row is dirty
    char unused[CHUNK_LEN - 11]; // so it fills a chunk
} erow;

typedef struct echunk {
    CHUNKNUM nextChunk;
    UCHAR bytesUsed;
    UCHAR bytes[ECHUNK_LEN];
} echunk;

typedef struct efile {
    CHUNKNUM fileChunk;             // Chunk address for this efile record (2)
    CHUNKNUM nextFileChunk;         // Chunk address for next efile record (2)
    int cx, cy;                     // cursor X and Y (4)
    unsigned rowoff;                // top row on screen (2)
    unsigned coloff;                // left-most column on screen (2)
    CHUNKNUM firstRowChunk;         // Chunk for first erow record (2)
    unsigned numrows;               // # of lines in file (2)
    char readOnly;                  // non-zero if file is read-only (1)
    char dirty;                     // non-zero if file is modified (1)
    CHUNKNUM filenameChunk;         // (2)
    char unused[CHUNK_LEN - 20];    // so it fills a chunk
} efile;

struct editorConfig {
    unsigned screenrows;            // # of rows on display
    unsigned screencols;            // # of columns
    CHUNKNUM firstFileChunk;
    char numOpenFiles;
    struct efile cf;                // point to current file
    unsigned numfiles;              // # of open files
    char *welcomePage;
    char quit;                      // non-zero when user selects quit command
    char last_key_esc;              // non-zero if last key was ESC
    char statusmsg[80];
    char *statusbar;
    unsigned char *statusbarrev;
    char statusmsg_dirty;
    f_showHelpPage cbShowHelpPage;
    f_showWelcomePage cbShowWelcomePage;
    f_updateStatusBar cbUpdateStatusBar;
    f_keyPressed cbKeyPressed;
    f_exitRequested cbExitRequested;
};

extern struct editorConfig E;

#define CTRL_KEY(k) ((k) & 0x1f)

enum editorKey {
    HELP_KEY = 31,
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
    COL40_KEY,
    COL80_KEY,
};

/*** file types ***/

/*** prototypes ***/

void clearCursor(void);
void clearScreen(void);
void clearRow(char row, char startingCol);
void drawRow(char row, char col, char len, char *buf, char isReversed);
void editorDeleteToEndOfLine(void);
void editorDeleteToStartOfLine(void);
void editorDelRow(int at);
void initFile(efile *file);
void editorFreeRow(CHUNKNUM firstTextChunk);
void editorInsertRow(int at, char *s, size_t len);
void editorRowAppendString(erow *row, char *s, size_t len);
char editorRowAt(int at, erow *row);
void editorRowDelChars(erow *row, int at, int length);
void editorRowInsertChar(erow *row, int at, int c);
char editorRowLastChunk(erow *row, CHUNKNUM *chunkNum, echunk *chunk);
char editorChunkAtX(erow *row, int at, int *chunkFirstCol, CHUNKNUM *chunkNum, echunk *chunk);
void editorNewFile(void);
void editorOpen(const char *filename, char readOnly);
void editorSwitchToOpenFile(CHUNKNUM fileChunkNum);
void editorClose(void);  // close current file
int editorReadKey(void);
void editorRetrieveFilename(efile *file, char *buffer);
void editorRun(void);
char editorSave(char *filename);
void editorSetAllRowsDirty(void);
void editorSetRowDirty(erow *row);
void editorSetStatusMessage(const char *fmt, ...);
void editorStoreFilename(efile *file, const char *filename);
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
