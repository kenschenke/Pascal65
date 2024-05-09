/**
 * editor.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for editor.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef EDITOR_H
#define EDITOR_H

#include <stdio.h>
#include <stddef.h>
#include <chunks.h>

#define ECHUNK_LEN (CHUNK_LEN - 3)

#define EDITOR_TAB_STOP 4

#define EDITOR_LOOP_CONTINUE 0
#define EDITOR_LOOP_QUIT 1
#define EDITOR_LOOP_OPENFILE 2
#define EDITOR_LOOP_FILESCREEN 3
#define EDITOR_LOOP_SAVEFILE 4
#define EDITOR_LOOP_OPENHELP 5
#define EDITOR_LOOP_COMPILE 6
#define EDITOR_LOOP_RUN 7

#define FILESCREEN_BACK 1          // Exit file screen and return to editor
#define FILESCREEN_OPENFILE 2
#define FILESCREEN_CLOSEFILE 3
#define FILESCREEN_NEWFILE 4
#define FILESCREEN_SAVEFILE 5
#define FILESCREEN_SAVEASFILE 6
#define FILESCREEN_SWITCHTOFILE 7
#define FILESCREEN_NOOP 8

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
    int numrows;                    // # of lines in file (2)
    char readOnly;                  // non-zero if file is read-only (1)
    char dirty;                     // non-zero if file is modified (1)
    char inSelection;               // non-zero if text is selected
    CHUNKNUM filenameChunk;         // (2)
    CHUNKNUM selectionChunk;        // Chunk for fileselection (2)
} efile;

typedef struct fileselection {
    int selectionX, selectionY;     // anchor point for selection
    int startHX, startHY;           // start of selection highlighting
    int endHX, endHY;               // end of selection highlighting
} fileselection;

struct editorConfig {
    unsigned screenrows;            // # of rows on display
    unsigned screencols;            // # of columns
    CHUNKNUM firstFileChunk;
    CHUNKNUM titleChunk;            // membuf for the title screen contents
    CHUNKNUM clipboard;             // membuf for the clipboard contents
    struct efile cf;                // point to current file
    struct fileselection selection; // clipboard selection for current file
    char loopCode;                  // non-zero when processing loop exits
                                    // one of EDITOR_LOOP_*
    char last_key_esc;              // non-zero if last key was ESC
    char statusmsg[80];
    char statusbar[80];
    char statusmsg_dirty;
    char anyDirtyRows;              // non-zero if any rows are dirty
    f_showHelpPage cbShowHelpPage;
    f_showWelcomePage cbShowWelcomePage;
    f_updateStatusBar cbUpdateStatusBar;
    f_keyPressed cbKeyPressed;
    f_exitRequested cbExitRequested;
};

extern struct editorConfig E;

#define CTRL_KEY(k) ((k) & 0x1f)

enum editorKey {
    STOP_KEY = 3,
    HELP_KEY = 31,
    BACKARROW = 95,
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
};

/*** prototypes ***/

#ifdef __C64__
void __fastcall__ clearCursor64(char x, char y);
void __fastcall__ clearScreen40(void);
void __fastcall__ initScreen40(void);
void __fastcall__ renderCursor64(char x, char y);
void __fastcall__ setRowColor(char row, char color);
void __fastcall__ setScreenBg40(char bg);
void __fastcall__ drawRow40(char row, char col, char len,
    const char *buf, char isReversed);
#endif

#ifdef __C128__
void __fastcall__ clearScreen80(void);
void __fastcall__ initScreen80(void);
void __fastcall__ setScreenBg80(char bg);
void __fastcall__ drawRow80(char row, char len,
    char *buf, unsigned char *rev);

void __fastcall__ clearScreen40(void);
void __fastcall__ initScreen40(void);
void __fastcall__ setScreenBg40(char bg);
void __fastcall__ drawRow40(char row, char len,
    char *buf, unsigned char *rev);
#endif

void clearCursor(void);
void clearRow(char row, char startingCol);
void clearScreen(void);
void clearStatusRow(void);
void closeFile(void);
void cursorOff(void);
char doesFileExist(char *filename);
void drawScreenRaw(char row, char col, char len, const unsigned char *buf);
void drawRow(char row, char col, char len, const char *buf, char isReversed);
void drawStatusRow(char color, char center, const char *msg);
char editorAnyUnsavedFiles(void);
void editorCalcSelection(void);
void editorClearSelection(void);
void editorCopySelection(void);
void editorDeleteSelection(void);
void editorDeleteToEndOfLine(void);
void editorDeleteToStartOfLine(void);
void editorDelRow(int at);
void editorFreeRow(CHUNKNUM firstTextChunk);
void editorInsertRow(int at, char *s, size_t len);
void editorPasteClipboard(void);
char editorPrompt(char *buf, size_t bufsize, char *prompt);
void editorRowAppendString(erow *row, char *s, size_t len);
char editorRowAt(int at, erow *row);
char editorRowLastChunk(erow *row, CHUNKNUM *chunkNum, echunk *chunk);
char editorChunkAtX(erow *row, int at, int *chunkFirstCol, CHUNKNUM *chunkNum, echunk *chunk);
void editorNewFile(void);
char editorOpen(const char *filename, char readOnly);
void editorClose(void);  // close current file
void editorReadFileContents(efile *file, FILE *fp);
int editorReadKey(void);
void editorRetrieveFilename(char *buffer);
char editorRun(void);       // returns EDITOR_LOOP_*
void editorSetAllRowsDirty(void);
void editorSetRowDirty(erow *row);
void editorSetDefaultStatusMessage(void);
void editorSetStatusMessage(const char *msg);
void editorStoreFilename(const char *filename);
void editorRefreshScreen();
char editorHasState(void);
void editorLoadState(void);
void editorSaveState(void);
char handleFiles(char *filename);
void initEditor(void);
void initFile(void);
void loadFilesFromState(void);
void unInitFile(void);
char saveAs(void);
char saveFile(void);
char showDirScreen(char *filename);
#if __C128__
void setScreenBg(char bg);
#endif
void initScreen(void);
char promptForOpenFilename(char *filename, size_t filenameLen);
void renderCursor(char x, char y);
void setupScreenCols(void);
void updateStatusBarFilename(void);

void editBufInsertChar(char ch, char lineLength, char pos);
void editBufDeleteChars(char pos, char numToDelete, char lineLength);
void editBufCopyChars(char pos, char charsToCopy, char *buffer);
void editBufPopulate(CHUNKNUM chunkNum);
void editBufFlush(CHUNKNUM *firstChunkNum, char lineLength);
void editorFlushEditBuf(void);
void screenInsertChar(char ch, char col, char row);
void screenDeleteChar(char ch, char col, char row);

#endif // end of EDITOR_H
