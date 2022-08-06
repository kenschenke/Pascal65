#ifndef EDITORTESTS_H
#define EDITORTESTS_H

#include <editor.h>

#define TEST_ROWS 5
#define TEST_CHUNKS_PER_ROW 5
#define TEST_CHUNK_LEN 13

extern CHUNKNUM rowChunkNums[TEST_ROWS];
extern CHUNKNUM textChunkNums[TEST_ROWS][TEST_CHUNKS_PER_ROW];

void setupTestData(void);

void testEditorChunkAtX(void);
void testEditorDelRow(void);
void testEditorInsertRow(void);
void testEditorRowAppendString(void);
void testEditorRowAt(void);
void testEditorRowDelChars(void);
void testEditorRowInsertChar(void);

#endif // end of EDITORTESTS_H
