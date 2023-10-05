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

#if 1
#include <stdio.h>
#include <stdlib.h>
#endif

BLOCKNUM		currentBlock;
unsigned char	*blockData;
unsigned		availChunks;

unsigned char	FullBlocks[MAX_BLOCKS / 8];

#if 0
static unsigned char allocReadMasks[] = {
	1,		// 00000001
	2,		// 00000010
	4,		// 00000100
	8,		// 00001000
	16,		// 00010000
	32,		// 00100000
	64,		// 01000000
	128,	// 10000000
};

#if 0
static unsigned char allocClearMasks[] = {
	254,	// 11111110
	253,	// 11111101
	251,	// 11111011
	247,	// 11110111
	239,	// 11101111
	223,	// 11011111
	191,	// 10111111
	127,	// 01111111
};
#endif

#if 0
static char isBlockFull(void);
#endif
static char isChunkAllocInBlock(char c);

void dumpChunkInfo(void)
{
	printf("cB = %d ", currentBlock);
	if (blockData == 0) {
		printf("(null)\n");
	} else {
		printf("%02x %02x\n", blockData[0], blockData[1]);
	}
}

#if 0
static char allocNewBlock(void)
{
	blockData = allocBlock(&currentBlock);
	if (!blockData) {
		currentBlock = 0;
		return 0;
	}
	blockData[0] = blockData[1] = 0;

	return 1;
}
#endif

#if 0
static void clearBlockFull(BLOCKNUM blockNum)
{
	FullBlocks[blockNum / 8] &= allocClearMasks[blockNum % 8];
}

// This function clears a chunk as "allocated" in the current block.
static void clearChunkAlloc(char chunk)
{
	int i = 0;
	if (chunk >= 8) {
		chunk -= 8;
		i = 1;
	}

	blockData[i] &= allocClearMasks[chunk];
}
#endif

#if 0
static void setChunkAlloc(char chunk)
{
	int i = 0;
	if (chunk >= 8) {
		chunk -= 8;
		i = 1;
	}

	blockData[i] |= allocReadMasks[chunk];
}
#endif

#if 0
static void extractBlockAndChunkNum(CHUNKNUM num, BLOCKNUM *pBlock, char *pChunk)
{
	*pBlock = num >> 4;
	*pChunk = num & 0x0f;
}
#endif

#if 0
char allocChunk(CHUNKNUM *chunkNum)
{
	char c;

	if (!blockData) {
		if (!allocNewBlock()) {
			return 0;
		}
	}

	// Is the current block full?
	if (isBlockFull()) {
		BLOCKNUM b, totalBlocks = getTotalBlocks();

		// Yes. Store it and look for other blocks with free chunks
		storeBlock(currentBlock);
		currentBlock = 0;
		blockData = 0;

		for (b = 0; b < totalBlocks; ++b) {
			if (isBlockAllocated(b)) {
				if (!(FullBlocks[b / 8] & allocReadMasks[b % 8])) {
					blockData = retrieveBlock(b);
					currentBlock = b;
					break;
				}
			}
		}

		if (b >= totalBlocks) {
			// Looked through all the blocks.  Allocate a new block.
			if (!allocNewBlock()) {
				return 0;
			}
		}
	}

	// Look for a free chunk in the current block
	for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
		if (!isChunkAllocInBlock(c)) {
			break;
		}
	}

	if (c >= CHUNKS_PER_BLOCK) {
		return 0;
	}

	setChunkAlloc(c);

	if (isBlockFull()) {
		FullBlocks[currentBlock / 8] |= allocReadMasks[currentBlock % 8];
	}

	--availChunks;
	*chunkNum = (currentBlock << 4) | (c + 1);
	return 1;
}
#endif
#endif

void flushChunkBlock(void) {
	if (blockData) {
		storeBlock(currentBlock);
		currentBlock = 0;
		blockData = NULL;
	}
}

#if 0
static char isBlockFull(void)
{
	return blockData[0] == 0xff && blockData[1] == 0x07 ? 1 : 0;
}
#endif

#if 1
#if 0
static void printByte(unsigned char byte)
{
	int i;

	for (i = 7; i >= 0; --i) {
		printf("%c", (byte & allocReadMasks[i]) ? '1' : '0');
	}
}
#endif

#if 0
char retrieveChunkA(CHUNKNUM chunkNum, void *data)
{
	return retrieveChunkX(chunkNum, data, 9999);
}
#endif

#if 0
char retrieveChunkX(CHUNKNUM chunkNum, void *data, int line)
{
	BLOCKNUM block;
	char chunk;

#if 1
	if (chunkNum == 0) {
		// printf("ChunkNum is zero from line %d!\n", line);
		printf(" D %d\n", line);
		exit(0);
	}
#endif

	extractBlockAndChunkNum(chunkNum, &block, &chunk);
	--chunk;

	if (!blockData || block != currentBlock) {
		if (blockData) {
			storeBlock(currentBlock);
			blockData = 0;
			currentBlock = 0;
		}

		blockData = retrieveBlock(block);
		if (!blockData) {
#if 1
			printf("chunkNum %04x block not allocated from line %d\n", chunkNum, line);
			printf(" C %d\n", line);
			exit(0);
#endif
			return 0;
		}
		currentBlock = block;
	}

#if 1
	if (!isChunkAllocInBlock(chunk)) {
		// printf("chunkNum %04x not allocated in block from line %d\n", chunkNum, line);
		printf(" B %d\n", line);
		exit(0);
	}
#endif

	memcpy(data, blockData + 2 + chunk * CHUNK_LEN, CHUNK_LEN);

	return 1;
}
#endif

#if 0
char storeChunk(CHUNKNUM chunkNum, void *data)
{
	BLOCKNUM block;
	char chunk;

	extractBlockAndChunkNum(chunkNum, &block, &chunk);
	--chunk;

	if (!blockData || block != currentBlock) {
		if (blockData) {
			storeBlock(currentBlock);
			blockData = 0;
			currentBlock = 0;
		}

		blockData = retrieveBlock(block);
		if (!blockData) {
			return 0;
		}
		currentBlock = block;
	}

	memcpy(blockData + 2 + chunk * CHUNK_LEN, data, CHUNK_LEN);

	return 1;
}
#endif

#if 0
void testChunkStuff(void)
{
	// int i;
	char chunk, c;
	BLOCKNUM block, b;
	CHUNKNUM chunkNum;

#if 0
	allocChunk(&chunkNum);
	extractBlockAndChunkNum(chunkNum, &block, &chunk);

	printf("block: %d\n", block);
	printf("chunk: %d\n", chunk);

	printf("byte 0 %3d: ", blockData[0]);
	printByte(blockData[0]);
	printf("\nbyte 1 %3d: ", blockData[1]);
	printByte(blockData[1]);
	printf("\n");

	for (chunk = 0; chunk < CHUNKS_PER_BLOCK; ++chunk) {
		printf("isAlloc %2d - %s\n", chunk, isChunkAllocInBlock(chunk) ? "yes" : "no");
	}

	for (i = 0; i < CHUNKS_PER_BLOCK - 1; ++i) {
		allocChunk(&chunkNum);
		extractBlockAndChunkNum(chunkNum, &block, &chunk);
		if (block != 0) {
			printf("block != 1\n");
		}
		if (chunk != i + 2) {
			printf("chunk wrong\n");
		}
	}

	printf("byte 0 %3d: ", blockData[0]);
	printByte(blockData[0]);
	printf("\nbyte 1 %3d: ", blockData[1]);
	printByte(blockData[1]);
	printf("\n");

	for (i = 0; i < CHUNKS_PER_BLOCK - 1; ++i) {
		freeChunk(i + 1);
		printByte(blockData[1]);
		printf(" ");
		printByte(blockData[0]);
		if (!isBlockAllocated(0)) {
			printf(" no block!\n");
		}
		printf("\n");
	}

	freeChunk(CHUNKS_PER_BLOCK);
	if (isBlockAllocated(0)) {
		printf("block still allocated\n");
	}
#endif

	for (b = 0; b < 3; ++b) {
		for (c = 1; c <= CHUNKS_PER_BLOCK; ++c) {
			if (c > 1 && isChunkAllocInBlock(c - 1)) {
				printf("Chunk %d (block %d) should not be allocated\n", c, b);
			}
			allocChunk(&chunkNum);
			if (c == 1 && !isBlockAllocated(b)) {
				printf("block should be allocated\n");
			}
			extractBlockAndChunkNum(chunkNum, &block, &chunk);
			if (block != b) {
				printf("block was %d -- expected %d\n", block, b);
			}
			if (chunk != c) {
				printf("chunk was %d -- expected %d %d\n", chunk, c, chunkNum);
			}
			if (!isChunkAllocInBlock(c - 1)) {
				printf("chunk %d (block %d) should be allocated\n", chunk, block);
			}
		}
	}

	for (b = 0; b < 3; ++b) {
		if (!isBlockAllocated(b)) {
			printf("Block %d should be allocated\n", b);
		}
		for (c = 1; c <= CHUNKS_PER_BLOCK; ++c) {
			if (!isChunkAllocInBlock(c - 1)) {
				printf("Chunk %d should be allocated\n", c);
			}
#if 0
			printf("%c ", isChunkAllocInBlock(c - 1) ? '1' : '0');
			printByte(blockData[1]);
			printf(" ");
			printByte(blockData[0]);
			printf(":");
#endif
			freeChunk(b << 4 | c);
#if 0
			if (c < CHUNKS_PER_BLOCK) {
				printByte(blockData[1]);
				printf(" ");
				printByte(blockData[0]);
				printf(" %c\n", isChunkAllocInBlock(c - 1) ? '1' : '0');
			}
#endif
			if (c < CHUNKS_PER_BLOCK && isChunkAllocInBlock(c - 1)) {
				printf("Chunk %d should not be allocated\n", c);
			}
		}
		if (isBlockAllocated(b)) {
			printf("Block %d should not be allocated\n", b);
		}
	}
}
#endif
#endif

// This function returns non-zero if a chunk is currently allocated in the block
#if 0
char isChunkAllocInBlock(char c)
{
	int i = 0;
	if (c >= 8) {
		c -= 8;
		i = 1;
	}

	return blockData[i] & allocReadMasks[c];
}
#endif

#if 0
void freeChunkA(CHUNKNUM num)
{
	freeChunkX(num, 9999);
}
#endif

#if 0
void freeChunkX(CHUNKNUM num, int /*line*/)
{
	char chunk;
	BLOCKNUM block;

	extractBlockAndChunkNum(num, &block, &chunk);
	--chunk;

	if (!blockData || block != currentBlock) {
		if (currentBlock) {
			storeBlock(currentBlock);
			currentBlock = 0;
			blockData = 0;
		}

		blockData = retrieveBlock(block);
		if (!blockData) {
			return;
		}
		currentBlock = block;
	}

	// Set the chunk to show "free" in the chunk allocation table
	if (!isChunkAllocInBlock(chunk)) {
#if 0
		// printf(" A %d\n", line);
		printf("chunk is not allocated %04x line %d\n", num, line);
		dumpChunkInfo();
		exit(0);
#endif
		return;
	}
	clearChunkAlloc(chunk);
	clearBlockFull(currentBlock);

	// Check if all other chunks in this block are also freed
	for (chunk = 0; chunk < CHUNKS_PER_BLOCK; ++chunk) {
		if (isChunkAllocInBlock(chunk)) {
			break;
		}
	}

	if (chunk >= CHUNKS_PER_BLOCK) {
		// All chunks in this block are free.  Free the block as well.
		freeBlock(block);
		currentBlock = 0;
		blockData = 0;
	}

	++availChunks;
}
#endif

#if 0
void dumpAllocatedChunks(void) {
	char c, i = 0;
	BLOCKNUM blockNum;

	for (blockNum = 0; blockNum < MAX_BLOCKS; ++blockNum) {
		if (!isBlockAllocated(blockNum)) {
			continue;
		}

		blockData = retrieveBlock(blockNum);
		while (1) {
			for (c = 0; c < 8; ++c) {
				if (i == 1 && c > 2) {
					break;
				}
				if (isChunkAllocInBlock(c)) {
					printf("allocated: %04x\n",
						(blockNum << 4) | (i > 0 ? c + 9 : c + 1));
				}
			}

			++i;
			if (i > 1) {
				break;
			}
		}
	}
}
#endif

unsigned getTotalChunks(void) {
#ifdef __MEGA65__
	return CHUNKS_PER_BLOCK * BLOCKS_PER_BANK * BANKS;
#else
	return CHUNKS_PER_BLOCK * getTotalBlocks();
#endif
}

#if 0
unsigned char isChunkAllocated(CHUNKNUM chunkNum)
{
	BLOCKNUM blockNum;
	unsigned char c;

	blockNum = GET_BLOCKNUM(chunkNum);
	c = GET_CHUNKNUM(chunkNum);
	if (!isBlockAllocated(blockNum)) {
		return 0;
	}

	if (blockData == NULL || currentBlock != blockNum) {
		blockData = retrieveBlock(blockNum);
		if (blockData == NULL) {
			return 0;
		}
		currentBlock = blockNum;
	}

	return isChunkAllocInBlock(c - 1);
}
#endif
