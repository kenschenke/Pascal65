#include <blocks.h>
#include "memtest.h"
#include <memory.h>
#include <stdio.h>
#include <string.h>

void testAllocateAllBlocks(void)
{
	int i, j;
	BLOCKNUM blockNum;
	unsigned char *p;

	DECLARE_TEST("testAllocateAllBlocks");

	printf("Running test: Allocate All Blocks\n");

	// Allocate each block and set its contents to a unique value
	for (i = 0; i < TOTAL_BLOCKS; ++i) {
		p = allocBlock(&blockNum);
		assertNotNull(p);
		assertEqualByte(i + 1, blockNum);
		memset(p, i + 1, BLOCK_LEN);
		assertNonZero(storeBlock(blockNum));
	}

	// Retrieve each block and verify its contents
	for (i = 0; i < TOTAL_BLOCKS; ++i) {
		p = retrieveBlock(i + 1);
		assertNotNull(p);
		for (j = 0; j < BLOCK_LEN; ++j) {
			assertEqualByte(i + 1, p[j]);
		}
	}

	// Attempt to allocate one more block
	p = allocBlock(&blockNum);
	assertNull(p);

	// Verify each block is allocated, free each block,
	// then verify each block is freed.
	for (i = 0; i < TOTAL_BLOCKS; ++i) {
		assertNonZero(isBlockAllocated(i + 1));
		freeBlock(i + 1);
		assertZero(isBlockAllocated(i + 1));
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
	assertNull(retrieveBlock(TOTAL_BLOCKS + 1));

	// Try to retrieve an unallocated block
	assertNull(retrieveBlock(1));

	// Allocate a block and verify it can be retrieved
	p1 = allocBlock(&blockNum);
	assertNotNull(p1);
	assertEqualByte(1, blockNum);
	
	// Retrieve the same block
	p2 = retrieveBlock(blockNum);
	assertNotNull(p2);
	assertEqualPointer(p1, p2);
}

void testReusingFreedBlocks(void)
{
	int i, j;
	BLOCKNUM blockNum;
	unsigned char value;
	unsigned char *p;

	DECLARE_TEST("testReusingFreedBlocks");

	printf("Running test: Reusing Freed Blocks\n");

	// Set the first five blocks to a unique value
	for (i = 0; i < 5; ++i) {
		p = allocBlock(&blockNum);
		assertNotNull(p);
		assertEqualByte(i + 1, blockNum);
		memset(p, i + 1, BLOCK_LEN);
		assertNonZero(storeBlock(blockNum));
	}

	// Free two of those blocks
	freeBlock(2);
	assertZero(isBlockAllocated(2));
	freeBlock(4);
	assertZero(isBlockAllocated(4));

	// Reallocate two blocks
	p = allocBlock(&blockNum);
	assertNotNull(p);
	assertEqualByte(2, blockNum);
	assertNonZero(isBlockAllocated(2));
	memset(p, 20, BLOCK_LEN);
	assertNonZero(storeBlock(2));

	p = allocBlock(&blockNum);
	assertNotNull(p);
	assertEqualByte(4, blockNum);
	assertNonZero(isBlockAllocated(4));
	memset(p, 40, BLOCK_LEN);
	assertNonZero(storeBlock(4));

	// Allocate one more block
	p = allocBlock(&blockNum);
	assertNotNull(p);
	assertEqualByte(6, blockNum);
	memset(p, 6, BLOCK_LEN);
	assertNonZero(storeBlock(6));

	// Verify each of the blocks
	for (i = 0; i < 6; ++i) {
		p = retrieveBlock(i + 1);
		assertNotNull(p);

		value = i + 1;
		if (i == 1) value = 20;
		if (i == 3) value = 40;
		for (j = 0; j < BLOCK_LEN; ++j) {
			assertEqualByte(value, p[j]);
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
	assertZero(storeBlock(TOTAL_BLOCKS + 1));

	// Try to store an unallocated block
	assertZero(storeBlock(1));

	// Allocate a block and verify it can be stored
	p = allocBlock(&blockNum);
	assertNotNull(p);
	assertEqualByte(1, blockNum);

	// Store the same block
	assertNonZero(storeBlock(blockNum));
}

