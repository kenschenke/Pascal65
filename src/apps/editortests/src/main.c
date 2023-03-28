#include <stdio.h>
#include <real.h>
#include "editortests.h"

// stubs for code not part of the tests

void clearCursor(void) { }
void clearScreen(void) { }
void drawStatusRow(char, char, const char *) { }
void editorCalcSelection(void) { }
void editorClearSelection(void) { }
void editorCopySelection(void) { }
void editorDeleteSelection(void) { }
void editorFind(void) { }
void editorOpen(const char *, char) { }
void editorPasteClipboard(void) { }
int editorReadKey(void) { return 0; }
void editorRefreshScreen(void) { }
void editorSetStatusMessage(const char *) { }
void floatToStr(FLOAT, char *, char) { }
const char *formatInt16(int) { return NULL; }
void handleFiles(void) { }
void initScreen(void) { }
void openFile(void) { }
void printlnz(const char *) { }
void printz(const char *) { }
void renderCursor64(char, char) { }
char saveFile(void) { return 0; }
FLOAT strToFloat(const char *) { return 0; }
void updateStatusBarFilename(void) { }

int main()
{
    printf("Starting tests\n");

    testEditorRowAt();
    testEditorChunkAtX();
    testEditorDelRow();
    testEditorInsertRow();
    testEditorRowInsertChar();
    testEditorRowDelChars();
    testEditorRowAppendString();

    printf("Done with tests\n");

	return 0;
}