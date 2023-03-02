#include <stdio.h>
#include <blocks.h>
#include <chunks.h>
#include "memtest.h"

int main()
{
#if 0
    initBlockStorage();
    testAllocateAllBlocks();

    initBlockStorage();
    testReusingFreedBlocks();

    initBlockStorage();
    testRetrieveBlock();

    initBlockStorage();
    testStoreBlock();

    initBlockStorage();
    testAllocateAllChunks();
#endif

    initBlockStorage();
    testRetrieveChunk();

    initBlockStorage();
    testFreeChunk();

    initBlockStorage();
    testReusingFreedChunks();

    initBlockStorage();
    testGetTotalChunks();

    initBlockStorage();
    testGetAvailChunks();

    initBlockStorage();
    testFreeingAllChunksInABlock();

#if 0
    initBlockStorage();
    testAllocateSmallBuffer(); 
    
    initBlockStorage();
    testAllocateBufferOfOneChunkSize();

    initBlockStorage();
    testAllocateBufferOfTwoChunks();

    initBlockStorage();
    testAllocateBufferTwice();

    initBlockStorage();
    testExpandBuffer();

    initBlockStorage();
    testFreeBuffer();

    initBlockStorage();
    testSetBufferPosition();

    initBlockStorage();
    testBufferReadAndWrite();

    initBlockStorage();
    testBufferMultiByteReadAndWrite();

    initBlockStorage();
    testBufferReadAtChunkBoundary();

    // if (wasBankMemoryCorrupted()) {
    //     printf("*********** Bank memory got corrupted ************\n");
    // }
#endif

    printf("Done with tests\n");

	return 0;
}