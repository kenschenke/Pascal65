/**
 * blocks.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <blocks.h>
#include <chunks.h>
#include <stdlib.h>
#include <string.h>

static unsigned char *blocks[MAX_BLOCKS];

unsigned char *allocBlock(BLOCKNUM *blockNum)
{
    for (int i = 0; i < MAX_BLOCKS; i++) {
        if (!blocks[i]) {
            blocks[i] = malloc(BLOCK_LEN);
            *blockNum = i;
            return blocks[i];
        }
    }

    return 0;
}

void freeBlock(BLOCKNUM blockNum)
{
    if (blocks[blockNum]) {
        free(blocks[blockNum]);
        blocks[blockNum] = 0;
    }
}

unsigned getTotalBlocks(void)
{
    return MAX_BLOCKS;
}

void initBlockStorage(void)
{
    for (int i = 0; i < MAX_BLOCKS; i++) {
        if (blocks[i]) free(blocks[i]);
    }
    
    memset(blocks, 0, sizeof(blocks));

    initChunkStorage();
}

char isBlockAllocated(BLOCKNUM blockNum)
{
    return blocks[blockNum] ? 1 : 0;
}


unsigned char *retrieveBlock(BLOCKNUM blockNum)
{
#if 0
    if (!isBlockAllocated(blockNum)) {
        fprintf(stderr, "Block %d not allocated\n", blockNum);
        exit(5);
    }
#endif

    return blocks[blockNum];
}

unsigned char storeBlock(BLOCKNUM blockNum)
{
	// Make sure the block is allocated
	if (!isBlockAllocated(blockNum)) {
		return 0;
	}

	return 1;
}

