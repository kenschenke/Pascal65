#include <stdio.h>
#include <blocks.h>
#include <chunks.h>
#include "memtest.h"

int main()
{
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

    initBlockStorage();
    testRetrieveChunk();

    initBlockStorage();
    testFreeChunk();

    initBlockStorage();
    testReusingFreedChunks();

    if (wasBankMemoryCorrupted()) {
        printf("*********** Bank memory got corrupted ************\n");
    }

    printf("Done with tests\n");

	return 0;
}