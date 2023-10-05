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
unsigned		availChunks;

unsigned char	FullBlocks[MAX_BLOCKS / 8];

void flushChunkBlock(void) {
	if (blockData) {
		storeBlock(currentBlock);
		currentBlock = 0;
		blockData = NULL;
	}
}

unsigned getTotalChunks(void) {
#ifdef __MEGA65__
	return CHUNKS_PER_BLOCK * BLOCKS_PER_BANK * BANKS;
#else
	return CHUNKS_PER_BLOCK * getTotalBlocks();
#endif
}
