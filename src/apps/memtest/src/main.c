#include <stdio.h>
#include <blocks.h>
#include <chunks.h>
#include "memtest.h"

void floatToStr(FLOAT, char *, char) { }

int main()
{
    int run = 1;

#if 0
    initBlockStorage();
    testAllocateAllBlocks();

    initBlockStorage();
    testReusingFreedBlocks();

    initBlockStorage();
    testRetrieveBlock();

    initBlockStorage();
    testStoreBlock();
#endif

    initBlockStorage();
    testRandomChunks();
    return 0;

    while (1) {
        printf("Run %d\n", run);

        initBlockStorage();
        testAllocateAllChunks();

        ++run;
    }

#if 0
    initBlockStorage();
    testStaggeredAlloc();
#endif

#if 1
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
#endif

#if 1
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