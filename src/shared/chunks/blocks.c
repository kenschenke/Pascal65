/**
 * blocks.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Memory block allocation.
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
#include <stdlib.h>
#include <libcommon.h>
#include <int16.h>

#ifdef __MEGA65__
#include <memory.h>
#include <blocks_mega65.h>
#else
#include <em.h>
#endif

#define BLOCK_ALLOC_INDEX(BLOCK) (BLOCK / 64)
#define BLOCK_ALLOC_MASK(BLOCK) (1 << ((BLOCK/8) % 8))

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

// Blocks are allocated eight at a time.
// Each bit represents an eight-block group.
static unsigned char BlocksUsed[MAX_BLOCKS / 64];

static char isBlockGroupAllocated(BLOCKNUM blockNum);
static void setBlockGroupUnallocated(unsigned group);

#ifdef __MEGA65__
unsigned char sharedBlock[BLOCK_LEN];
BLOCKNUM currentBlockNum;
#define BLOCK_NOT_ALLOCATED 0xffff
#elif defined(USE_EMD)
unsigned char *sharedBlock;
#endif

#ifdef __MEGA65__
// Mega65 banks 4 and 5
// IMPORTANT: update the BANKS constant in blocks_mega65.h
static long banks[] = {
    0x0040000,		// chip RAM
    0x0050000,
	0x8000000,		// attic RAM
	0x8010000,
	0x8020000,
	0x8030000,
	0x8040000,
	0x8050000,
	0x8060000,
	0x8070000,
	0x8080000,
	0x8090000,
	0x80a0000,
	0x80b0000,
	0x80c0000,
	0x80d0000,
};	// bank memory addresses

static void transferFromBank(BLOCKNUM blockNum);
static void transferToBank(BLOCKNUM blockNum);

#if 0
struct dma_f018b
{
	char command;
	unsigned int count;
	unsigned int source;
	char source_bank;
	unsigned int destination;
	char destination_bank;
	char command_msb;
	unsigned int mode;
};
static void lcopy_f018b(long source_address, long destination_address,
	unsigned int count)
{
	struct dma_f018b dma;

	dma.command = 0;  // copy
	dma.count = count;
	dma.source = source_address & 0xffff;
	dma.source_bank = (char)(source_address >> 16);
	dma.destination = destination_address & 0xffff;
	dma.destination_bank = (char)(destination_address >> 16);
	dma.command_msb = 0;
	dma.mode = 0;

	POKE(0xd702U, 0);
	POKE(0xd704U, 0x00); // List is in $00xxxxx
	POKE(0xd701U, ((unsigned int)&dma) >> 8);
	POKE(0xd700U, ((unsigned int)&dma) & 0xff); // triggers enhanced DMA
}
#endif

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
	currentBlockNum = BLOCK_NOT_ALLOCATED;
#elif defined(USE_EMD)
	char ret;
	static char emLoaded = 0;

	if (!emLoaded) {
		ret = em_load_driver(EM_DRIVER);
		if (ret == EM_ERR_NO_DEVICE) {
			printlnz("Expanded memory hardware not detected.");
			exit(0);
		}
		if (ret != EM_ERR_OK) {
			printz("Failed to load extended memory driver - code ");
			printlnz(formatInt16(ret));
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

    b = MAX_BLOCKS / 64;
    for (i = 0; i < b; ++i) {
        BlocksUsed[i] = 0;
    }
#ifdef USE_EMD
	sharedBlock = NULL;
#endif
	initChunkStorage();
}

char isBlockAllocated(BLOCKNUM blockNum) {
	unsigned char *p;

	// Check if the eight-block group for this block is allocated
	if (!isBlockGroupAllocated(blockNum)) {
		// It's not
		return 0;
	}

	// Retrieve a pointer to the block and check the first two bytes.  That will
	// indicate if any chunks in that block are allocated.
#ifdef USE_EMD
	em_commit();
	p = em_map(blockNum);
#else
	if (currentBlockNum != blockNum) {
		if (currentBlockNum != BLOCK_NOT_ALLOCATED) {
			transferToBank(currentBlockNum);
		}
		transferFromBank(blockNum);
		currentBlockNum = blockNum;
	}
	p = sharedBlock;
#endif
	return (p[0] || p[1]) ? 1 : 0;
}

static char isBlockGroupAllocated(BLOCKNUM blockNum) {
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
		// If the eight-block group for this block is not allocated,
		// do so and set the first two bytes of each block to zero.
		if (!isBlockGroupAllocated(i)) {
			BlocksUsed[BLOCK_ALLOC_INDEX(i)] |= BLOCK_ALLOC_MASK(i);
			setBlockGroupUnallocated(i);
		}
		else if (isBlockAllocated(i)) {
			continue;
		}

		*blockNum = i;
#ifdef USE_EMD
		sharedBlock = em_map(i);
#endif
#ifdef __MEGA65__
		memset(sharedBlock, 0, BLOCK_LEN);
		currentBlockNum = i;
#endif

		return sharedBlock;
	}

	return NULL;
}

char allocBlockGroup(BLOCKNUM *blockNum, unsigned numBlocks) {
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
	BLOCKNUM b = blockNum;
	unsigned char *p;
	unsigned i;

	// Set the first two bytes to zero in the block.
#ifdef USE_EMD
	if (sharedBlock) {
		em_commit();
	}
	p = em_use(blockNum);
	p[0] = p[1] = 0;
	em_commit();
#else
	if (blockNum != currentBlockNum) {
		if (currentBlockNum != BLOCK_NOT_ALLOCATED) {
			transferToBank(currentBlockNum);
		}
		transferFromBank(blockNum);
	}
	sharedBlock[0] = sharedBlock[1] = 0;
	transferToBank(blockNum);
	currentBlockNum = BLOCK_NOT_ALLOCATED;
#endif

	// Check each of the eight blocks in the group.
	// If they are all now un-allocated, mark the
	// group as such.
	b -= (b % 8);
	for (i = 0; i < 8; ++i,++b) {
#ifdef USE_EMD
		p = em_map(b);
#else
		transferFromBank(b);
		p = sharedBlock;
#endif
		if (p[0] || p[1]) {
			// If either of the first two bytes are non-zero,
			// at least one of the blocks is still in use.
			break;
		}
	}

	if (i >= 8) {
		// All eight blocks are not in use.
		// Set the entire group as unallocated.
		BlocksUsed[BLOCK_ALLOC_INDEX(blockNum)] &= ~BLOCK_ALLOC_MASK(blockNum);
	}
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

static void setBlockGroupUnallocated(unsigned group) {
	int i;
	unsigned char *p;

#ifndef USE_EMD
	if (currentBlockNum != BLOCK_NOT_ALLOCATED) {
		transferToBank(currentBlockNum);
	}
	p = sharedBlock;
#endif

	for (i = 0; i < 8; ++i) {
#ifdef USE_EMD
		p = em_use(group + i);
#else
		transferFromBank(group + i);
#endif
		p[0] = p[1] = 0;
#ifdef USE_EMD
		em_commit();
#else
		transferToBank(group + i);
#endif
	}
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
