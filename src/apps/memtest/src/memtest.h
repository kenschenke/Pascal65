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

// Dynamic Memory Buffers
void testAllocateSmallBuffer(void);
void testAllocateBufferOfOneChunkSize(void);
void testAllocateBufferOfTwoChunks(void);
void testAllocateBufferTwice(void);
void testExpandBuffer(void);
void testFreeBuffer(void);
void testSetBufferPosition(void);
void testBufferReadAndWrite(void);
void testBufferMultiByteReadAndWrite(void);
void testBufferReadAtChunkBoundary(void);

#endif // end of MEMTEST_H
