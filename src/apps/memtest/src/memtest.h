#ifndef MEMTEST_H
#define MEMTEST_H

#include <tests.h>

// Blocks
void testAllocateAllBlocks(void);
void testRetrieveBlock(void);
void testReusingFreedBlocks(void);
void testStoreBlock(void);

// Chunks
void testAllocateAllChunks(void);
void testRetrieveChunk(void);
void testReusingFreedChunks(void);

#endif // end of MEMTEST_H
