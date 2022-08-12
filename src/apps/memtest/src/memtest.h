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
void testFreeChunk(void);
void testGetAvailChunks(void);
void testGetTotalChunks(void);
void testRetrieveChunk(void);
void testReusingFreedChunks(void);
void testFreeingAllChunksInABlock(void);

#endif // end of MEMTEST_H
