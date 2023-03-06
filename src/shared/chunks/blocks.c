/**
 * blocks.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Memory block allocation.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <blocks.h>
#include <chunks.h>
#include <string.h>
#include <stdlib.h>

#ifdef __MEGA65__
#include <memory.h>
#include <blocks_mega65.h>
#else
#include <em.h>
#endif

#define BLOCK_ALLOC_INDEX(BLOCK) (BLOCK / 8)
#define BLOCK_ALLOC_MASK(BLOCK) (1 << (BLOCK % 8))

#ifdef __MEGA65__
// nothing to do
#elif defined(__C128__)
#define EM_DRIVER "c128-reu.emd"
#define USE_EMD
#elif defined(__C64__)
#define EM_DRIVER "c64-reu.emd"
#define USE_EMD
#else
#error Platform not implemented
#endif

static unsigned pages;	// max pages per REU
static unsigned lastPageToAllocate;

static unsigned char BlocksUsed[MAX_BLOCKS / 8];

#ifdef __MEGA65__
unsigned char sharedBlock[BLOCK_LEN];
#elif defined(USE_EMD)
unsigned char *sharedBlock;
#endif

#ifdef __MEGA65__
// Mega65 banks 4 and 5
static long banks[] = {
    0x40000,
    0x50000
};	// bank memory addresses

static void transferFromBank(BLOCKNUM blockNum);
static void transferToBank(BLOCKNUM blockNum);

static void transferFromBank(BLOCKNUM blockNum)
{
	unsigned char bank = blockNum / BLOCKS_PER_BANK;
	unsigned char block = blockNum % BLOCKS_PER_BANK;
    lcopy(
        banks[bank] + (long)block * BLOCK_LEN,  // source
        (long)sharedBlock,				        // destination
        BLOCK_LEN                               // bytes to copy
    );
}

static void transferToBank(BLOCKNUM blockNum)
{
	unsigned char bank = blockNum / BLOCKS_PER_BANK;
	unsigned char block = blockNum % BLOCKS_PER_BANK;
    lcopy(
        (long)sharedBlock,				        // source
        banks[bank] + (long)block * BLOCK_LEN,  // destination
        BLOCK_LEN                               // bytes to copy
    );
}
#endif

unsigned getTotalBlocks(void) {
	return pages;
}

void initBlockStorage(void)
{
	unsigned i, b;

#ifdef __MEGA65__
	static char blockInit = 0;
	pages = TOTAL_BLOCKS;
	// memset(sharedBlock, 0, BLOCK_LEN);
	if (!blockInit) {
		lastPageToAllocate = pages;
		blockInit = 1;
	}
#elif defined(USE_EMD)
	char ret;
	static char emLoaded = 0;

	if (!emLoaded) {
		ret = em_load_driver(EM_DRIVER);
		if (ret == EM_ERR_NO_DEVICE) {
			printf("Expanded memory hardware not detected.\n");
			exit(0);
		}
		if (ret != EM_ERR_OK) {
			printf("Failed to load extended memory driver - code %d\n", ret);
			exit(0);
		}

		pages = em_pagecount();
		if (pages > MAX_BLOCKS) {
			pages = MAX_BLOCKS;
		}
		lastPageToAllocate = pages;
		emLoaded = 1;
	}
#endif

    b = MAX_BLOCKS / 8;
    for (i = 0; i < b; ++i) {
        BlocksUsed[i] = 0;
    }
#ifdef USE_EMD
	sharedBlock = NULL;
#endif
	initChunkStorage();
}

char isBlockAllocated(BLOCKNUM blockNum) {
	return (BlocksUsed[BLOCK_ALLOC_INDEX(blockNum)] & BLOCK_ALLOC_MASK(blockNum)) ? 1 : 0;
}

unsigned char *allocBlock(BLOCKNUM *blockNum)
{
	unsigned i;

#ifdef USE_EMD
	if (sharedBlock) {
		em_commit();
	}
#endif

	for (i = 0; i < lastPageToAllocate; ++i) {
		if (!isBlockAllocated(i)) {
			// printf("blockNum = %d\n", i);
			BlocksUsed[BLOCK_ALLOC_INDEX(i)] |= BLOCK_ALLOC_MASK(i);
			*blockNum = i;
#ifdef USE_EMD
			sharedBlock = em_map(i);
#endif
#ifdef __MEGA65__
			memset(sharedBlock, 0, BLOCK_LEN);
#endif
			return sharedBlock;
		}
	}

	return NULL;
}

char allocBlockGroup(BLOCKNUM *blockNum, unsigned numBlocks) {
#ifdef __MEGA65__
#error allocBlockGroup not implemented on MEGA 65
#endif

	unsigned i;

	// Block groups are pulled from the top of extended memory.
	// Make sure there are enough consecutive, un-allocated blocks
	// at the top of memory.
	if (numBlocks > lastPageToAllocate) {
		return 0;
	}
	for (i = lastPageToAllocate - numBlocks; i < lastPageToAllocate; ++i) {
		if (isBlockAllocated(i)) {
			// block is allocated
			return 0;
		}
	}

	*blockNum = lastPageToAllocate - numBlocks;
	lastPageToAllocate -= numBlocks;

	return 1;
}

void freeBlock(BLOCKNUM blockNum)
{
	unsigned index = BLOCK_ALLOC_INDEX(blockNum);

	BlocksUsed[index] &= ~BLOCK_ALLOC_MASK(blockNum);
}

unsigned char *retrieveBlock(BLOCKNUM blockNum)
{
	// Make sure the block is allocated
	if (!isBlockAllocated(blockNum)) {
		return NULL;
	}

#ifdef __MEGA65__
	transferFromBank(blockNum);
#elif defined(USE_EMD)
	if (sharedBlock) {
		em_commit();
	}
	sharedBlock = em_map(blockNum);
#endif

	return sharedBlock;
}

unsigned char storeBlock(BLOCKNUM blockNum)
{
	// Make sure the block is allocated
	if (!isBlockAllocated(blockNum)) {
		return 0;
	}

#ifdef __MEGA65__
	transferToBank(blockNum);
#elif defined(USE_EMD)
	if (sharedBlock == NULL) {
		return 0;
	}

	em_commit();
	sharedBlock = NULL;
#endif

	return 1;
}

#if 0
#ifdef __TEST__
unsigned char wasBankMemoryCorrupted(void)
{
	char testbytes[TEST_OFFSET];
	memset(testbytes, 'X', TEST_OFFSET);

	if (memcmp(SharedBlock, testbytes, TEST_OFFSET))
		return 1;
	if (memcmp(SharedBlock + TEST_OFFSET + BLOCK_LEN, testbytes, TEST_OFFSET))
		return 1;

	return 0;
}
#endif
#endif
