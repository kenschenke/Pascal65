#include <stdio.h>
#include "editortests.h"

// stubs for code not part of the tests

void clearCursor(void) { }
void clearScreen(void) { }
void editorCalcSelection(void) { }
void editorClearSelection(void) { }
void editorCopySelection(void) { }
void editorDeleteSelection(void) { }
void editorFind(void) { }
void editorPasteClipboard(void) { }
int editorReadKey(void) { return 0; }
void editorRefreshScreen(void) { }
void editorSetStatusMessage(const char *fmt, ...) { }
void initScreen(void) { }

int main()
{
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