/**
 * chunks.c
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
#include <string.h>
#include <common.h>
#include <stdlib.h>

BLOCKNUM		currentBlock;
unsigned char	*blockData;
unsigned		availChunks;

unsigned char	FullBlocks[MAX_BLOCKS / 8];

static void clearBlockFull(BLOCKNUM b);
static char isAlloc(char c);
static char isBlockFull(BLOCKNUM b);
static void setAlloc(char c);
static void setBlockFull(BLOCKNUM b);

void allocChunk(CHUNKNUM *pChunkNum)
{
	BLOCKNUM b;
	char c;

	if (blockData) {
		for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
			if (!isAlloc(c)) {
				break;
			}
		}

		if (c < CHUNKS_PER_BLOCK) {
			setAlloc(c);
			--availChunks;
			*pChunkNum = TO_BLOCK_AND_CHUNK(currentBlock, (c+1));
			for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
				if (!isAlloc(c)) {
					break;
				}
			}
			if (c == CHUNKS_PER_BLOCK) {
				setBlockFull(currentBlock);
			}
			return;
		}

		storeBlock(currentBlock);
		blockData = 0;
		currentBlock = 0;
	}

	for (b = 0; b < MAX_BLOCKS; ++b) {
		if (isBlockAllocated(b) && !isBlockFull(b)) {
			blockData = retrieveBlock(b);
			currentBlock = b;
			break;
		}
	}

	if (b == MAX_BLOCKS) {
		blockData = allocBlock(&b);
		if (!blockData) {
			*pChunkNum = 0;
			return;
		}
        blockData[0] = blockData[1] = 0;
		currentBlock = b;
		setAlloc(0);
		--availChunks;
		*pChunkNum = TO_BLOCK_AND_CHUNK(currentBlock, 1);
		return;
	}

	for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
		if (!isAlloc(c)) {
			setAlloc(c);
			--availChunks;
			*pChunkNum = TO_BLOCK_AND_CHUNK(currentBlock, (c+1));
			for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
				if (!isAlloc(c)) {
					break;
				}
			}
			if (c == CHUNKS_PER_BLOCK) {
				setBlockFull(currentBlock);
			}
			return;
		}
	}
}

void freeChunk(CHUNKNUM chunkNum)
{
	char c, i=0;
	BLOCKNUM blockNum = GET_BLOCKNUM(chunkNum);

	if (!blockData || blockNum != currentBlock) {
		if (blockData) {
			storeBlock(currentBlock);
		}
		blockData = retrieveBlock(blockNum);
		if (!blockData) {
			return;
		}
		currentBlock = blockNum;
	}

	c = GET_CHUNKNUM(chunkNum) - 1;
	if (!isAlloc(c)) {
		return;
	}
#if 1
	i = 0;
	if (c > 7) {
		++i;
		c -= 8;
	}
	blockData[i] &= (unsigned char)(~((unsigned char )1 << c));
#else
	clearChunkAlloc(c);
#endif
	clearBlockFull(blockNum);

	for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
		if (isAlloc(c)) {
			break;
		}
	}
	if (c == CHUNKS_PER_BLOCK) {
		freeBlock(currentBlock);
		currentBlock = 0;
		blockData = 0;
	}

	++availChunks;
}

unsigned short getAvailChunks(void)
{
	return availChunks;
}

unsigned getTotalChunks(void)
{
	return CHUNKS_PER_BLOCK * getTotalBlocks();
}

void *getChunk(CHUNKNUM chunkNum)
{
	char c = GET_CHUNKNUM(chunkNum) - 1;
	BLOCKNUM blockNum = GET_BLOCKNUM(chunkNum);

	if (!blockData || blockNum != currentBlock) {
		if (blockData) {
			storeBlock(currentBlock);
		}
		blockData = retrieveBlock(blockNum);
		if (!blockData) {
			return 0;
		}
		currentBlock = blockNum;
	}

	if (c>=CHUNKS_PER_BLOCK || !isAlloc(c)) {
		return 0;
	}

	return blockData+2+(c*CHUNK_LEN);
}

#if 0
char getChunkCopy(CHUNKNUM chunkNum, void *buffer)
{
    return 0;
}
#endif

char retrieveChunk(CHUNKNUM chunkNum, void *chunk)
{
	char c = GET_CHUNKNUM(chunkNum) - 1;
	BLOCKNUM blockNum = GET_BLOCKNUM(chunkNum);

	if (!blockData || blockNum != currentBlock) {
		if (blockData) {
			storeBlock(currentBlock);
		}
		blockData = retrieveBlock(blockNum);
		if (!blockData) {
			printf("Invalid block number\n");
			printStackTrace();
			exit(5);
		}
		currentBlock = blockNum;
	}

	if (c>=CHUNKS_PER_BLOCK || !isAlloc(c)) {
		printf("Chunk %04x not allocated\n", chunkNum);
		printStackTrace();
		exit(5);
	}

	memcpy(chunk, blockData+2+(c*CHUNK_LEN), CHUNK_LEN);
	return 1;
}

char storeChunk(CHUNKNUM chunkNum, void *chunk)
{
	char c = GET_CHUNKNUM(chunkNum) - 1;
	BLOCKNUM blockNum = GET_BLOCKNUM(chunkNum);

	if (!blockData || blockNum != currentBlock) {
		if (blockData) {
			storeBlock(currentBlock);
		}
		blockData = retrieveBlock(blockNum);
		if (!blockData) {
#if 0
			printz("CN:");
			printz(formatInt16(chunkNum));
			printz(" B:");
			printz(formatInt16(blockNum));
			printlnz(" (3)");
			exit(5);
#endif
			return 0;
		}
		currentBlock = blockNum;
	}

	if (c>=CHUNKS_PER_BLOCK || !isAlloc(c)) {
#if 0
		printlnz("(4)");
		exit(5);
#endif
		return 0;
	}

	memcpy(blockData+2+(c*CHUNK_LEN), chunk, CHUNK_LEN);
	return 1;
}

void initChunkStorage(void)
{
	currentBlock = 0;
	blockData = 0;
	memset(FullBlocks, 0, sizeof(FullBlocks));
	availChunks = getTotalBlocks() * CHUNKS_PER_BLOCK;
}

unsigned char isChunkAllocated(CHUNKNUM chunkNum)
{
	BLOCKNUM blockNum = GET_BLOCKNUM(chunkNum);

	if (!isBlockAllocated(blockNum)) {
		return 0;
	}

	if (blockNum != currentBlock) {
		if (blockData) {
			storeBlock(currentBlock);
		}
		blockData = retrieveBlock(blockNum);
		if (!blockData) {
			return 0;
		}
		currentBlock = blockNum;
	}

	return isAlloc(GET_CHUNKNUM(chunkNum)-1);
}

static void setAlloc(char c)
{
#if 1
	int i = 0;

	if (!blockData) {
		return;
	}

	if (c > 7) {
		++i;
		c -= 8;
	}

	blockData[i] |= ((unsigned char)1 << c);
#else
	setChunkAlloc(c);
#endif
}

static char isAlloc(char c)
{
#if 1
	int i = 0;

	if (!blockData) {
		return 0;
	}

	if (c > 7) {
		++i;
		c -= 8;
	}

	if (!blockData) {
		return 0;
	}

	return (blockData[i] & ((unsigned char)1 << c)) ? 1 : 0;
#else
	return isChunkAlloc(c);
#endif
}

static void setBlockFull(BLOCKNUM b)
{
	int i = b / 8;
	int x = b % 8;

	FullBlocks[i] |= ((unsigned char)1 << x);
}

static char isBlockFull(BLOCKNUM b)
{
	int i = b / 8;
	int x = b % 8;

	return (FullBlocks[i] & ((unsigned char)1 << x) ? 1 : 0);
}

static void clearBlockFull(BLOCKNUM b)
{
	int i = b / 8;
	int x = b % 8;

	FullBlocks[i] &= ~((unsigned char)1 << x);
}
