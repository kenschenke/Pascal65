/**
 * chunks.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Memory block chunks.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <string.h>

#include <blocks.h>
#include <chunks.h>

BLOCKNUM		currentBlock;
unsigned char	*blockData;

unsigned char FullBlocks[TOTAL_BLOCKS];

int getTotalChunks(void) {
	return CHUNKS_PER_BLOCK * BLOCKS_PER_BANK * BANKS;
}

#ifdef __TEST__
unsigned char isChunkAllocated(CHUNKNUM chunkNum)
{
	BLOCKNUM blockNum;
	unsigned char c;

	blockNum = GET_BLOCKNUM(chunkNum);
	c = GET_CHUNKNUM(chunkNum);
	if (!isBlockAllocated(blockNum)) {
		return 0;
	}

	if (currentBlock != blockNum) {
		blockData = retrieveBlock(blockNum);
		if (blockData == NULL) {
			return 0;
		}
		currentBlock = blockNum;
	}

	return blockData[c - 1];
}
#endif