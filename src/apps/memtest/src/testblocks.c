#include <blocks.h>
#include "memtest.h"
#ifdef __MEGA65__
#include <memory.h>
#endif
#include <stdio.h>
#include <string.h>

#define MAX_STAGGERED 500

void testAllocateAllBlocks(void)
{
	int i, j;
	BLOCKNUM blockNum;
	unsigned char *p;

	DECLARE_TEST("testAllocateAllBlocks");

	printf("Running test: Allocate All Blocks\n");

	// Allocate each block and set its contents to a unique value
	for (i = 0; i < getTotalBlocks(); ++i) {
		p = allocBlock(&blockNum);
		assertNotNull(p);
		assertEqualByte(i, blockNum);
		memset(p, (i % 254) + 1, BLOCK_LEN);
		assertNonZero(storeBlock(blockNum));
	}

	// Retrieve each block and verify its contents
	for (i = 0; i < getTotalBlocks(); ++i) {
		p = retrieveBlock(i);
		assertNotNull(p);
		for (j = 0; j < BLOCK_LEN; ++j) {
			assertEqualByte((i % 254) + 1, p[j]);
		}
	}

	// Attempt to allocate one more block
	p = allocBlock(&blockNum);
	assertNull(p);

	// Verify each block is allocated, free each block,
	// then verify each block is freed.
	for (i = 0; i < getTotalBlocks(); ++i) {
		assertNonZero(isBlockAllocated(i));
		freeBlock(i);
		assertZero(isBlockAllocated(i));
	}
}

void testRetrieveBlock(void)
{
	unsigned char *p1, *p2;
	BLOCKNUM blockNum;

	DECLARE_TEST("testRetrieveBlock");

	printf("Running test: Retrieve Block\n");

	// Test blockNum out of range
	assertNull(retrieveBlock(0));
	assertNull(retrieveBlock(getTotalBlocks()));

	// Try to retrieve an unallocated block
	assertNull(retrieveBlock(1));

	// Allocate a block and verify it can be retrieved
	p1 = allocBlock(&blockNum);
	assertNotNull(p1);
	p1[0] = 1;	// put something in the block so it's used
	assertEqualInt(0, blockNum);
	
	// Retrieve the same block
	p2 = retrieveBlock(blockNum);
	assertNotNull(p2);
	assertEqualPointer(p1, p2);
}

void testReusingFreedBlocks(void)
{
	int i, j;
	BLOCKNUM blockNums[6];
	unsigned char value;
	unsigned char *p;

	DECLARE_TEST("testReusingFreedBlocks");

	printf("Running test: Reusing Freed Blocks\n");

	// Set the first five blocks to a unique value
	for (i = 0; i < 5; ++i) {
		p = allocBlock(&blockNums[i]);
		assertNotNull(p);
		memset(p, i + 1, BLOCK_LEN);
		assertNonZero(storeBlock(blockNums[i]));
	}

	// Free two of those blocks
	freeBlock(blockNums[2]);
	assertZero(isBlockAllocated(blockNums[2]));
	freeBlock(blockNums[4]);
	assertZero(isBlockAllocated(blockNums[4]));

	// Reallocate two blocks
	p = allocBlock(&blockNums[2]);
	assertNotNull(p);
	p[0] = 1;	// put something in the block so it's used
	assertNonZero(isBlockAllocated(blockNums[2]));
	memset(p, 20, BLOCK_LEN);
	assertNonZero(storeBlock(blockNums[2]));

	p = allocBlock(&blockNums[4]);
	assertNotNull(p);
	p[0] = 1;	// put something in the block so it's used
	assertNonZero(isBlockAllocated(blockNums[4]));
	memset(p, 40, BLOCK_LEN);
	assertNonZero(storeBlock(blockNums[4]));

	// Allocate one more block
	p = allocBlock(&blockNums[5]);
	assertNotNull(p);
	memset(p, 6, BLOCK_LEN);
	assertNonZero(storeBlock(blockNums[5]));

	// Verify each of the blocks
	for (i = 0; i < 6; ++i) {
		p = retrieveBlock(blockNums[i]);
		assertNotNull(p);

		value = i + 1;
		if (i == 2) value = 20;
		if (i == 4) value = 40;
		for (j = 0; j < BLOCK_LEN; ++j) {
			assertEqualByte(value, p[j]);
		}
	}
}

void testStaggeredAlloc(void)
{
	unsigned char *p;
	int i, j;
	char phrase[8 + 1];
	BLOCKNUM blockNum;

	printf("Allocating blocks\n");
	for (i = 1; i < MAX_STAGGERED; ++i) {
		sprintf(phrase, "BLK%05d", i);
		p = allocBlock(&blockNum);
		for (j = 0; j < BLOCK_LEN; j += 8) {
			memcpy(p, phrase, 8);
			p += 8;
		}
		storeBlock(blockNum);
	}

	printf("Freeing every 3rd block\n");
	for (i = 1; i < MAX_STAGGERED; i += 3) {
		freeBlock(i - 1);
	}

	printf("Reallocating every 3rd block\n");
	for (i = 1; i < MAX_STAGGERED; i += 3) {
		sprintf(phrase, "RAB%05d", i);
		p = allocBlock(&blockNum);
		if (blockNum != i - 1) {
			printf("Gaaa!\n");
		}
		for (j = 0; j < BLOCK_LEN; j += 8) {
			memcpy(p, phrase, 8);
			p += 8;
		}
		storeBlock(blockNum);
	}

	printf("Checking every block\n");
	for (i = 1; i < MAX_STAGGERED; ++i) {
		p = retrieveBlock(i - 1);
		if (!((i + 2) % 3)) {
			sprintf(phrase, "RAB%05d", i);
		} else {
			sprintf(phrase, "BLK%05d", i);
		}
		for (j = 0; j < BLOCK_LEN; j += 8) {
			if (memcmp(p, phrase, 8)) {
				printf("Blah!\n");
			}
			p += 8;
		}
	}
}

void testStoreBlock(void)
{
	unsigned char *p;
	BLOCKNUM blockNum;

	DECLARE_TEST("testStoreBlock");

	printf("Running test: Store Block\n");

	// Test blockNum out of range
	assertZero(storeBlock(0));
	assertZero(storeBlock(getTotalBlocks()));

	// Try to store an unallocated block
	assertZero(storeBlock(1));

	// Allocate a block and verify it can be stored
	p = allocBlock(&blockNum);
	p[1] = 1;	// put something in the block so it's used
	assertNotNull(p);

	// Store the same block
	assertNonZero(storeBlock(blockNum));
}

