#include <stdio.h>
#include <blocks.h>
#include <chunks.h>
#include "memtest.h"
#ifdef __MEGA65__
#include <memory.h>
#endif
#include <string.h>

void testAllocateAllChunks(void)
{
	int i, b, c;
	unsigned totalBlocks;
	CHUNKNUM chunkNum;
	unsigned char *chunk;

	DECLARE_TEST("testAllocateAllChunks");

	printf("Running test: Allocate All Chunks\n");

	totalBlocks = getTotalBlocks();

	// Allocate each chunk and set its contents to unique values
	for (b = 0; b < totalBlocks; ++b) {
		for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
			assertNonZero(allocChunk(&chunkNum));
			assertEqualByte(b, GET_BLOCKNUM(chunkNum));
			assertEqualByte(c + 1, GET_CHUNKNUM(chunkNum));
			chunk = getChunk(chunkNum);

			for (i = 0; i < CHUNK_LEN - (CHUNK_LEN % 2); i += 2) {
				chunk[i] = (b + 1) % 256;
				chunk[i + 1] = c + 1;
			}
		}
	}

	// Retrieve each chunk and verify its contents
	for (b = 0; b < totalBlocks; ++b) {
		for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
			chunk = getChunk(TO_BLOCK_AND_CHUNK(b, c + 1));
			assertNotNull(chunk);

			for (i = 0; i < CHUNK_LEN - (CHUNK_LEN % 2); i += 2) {
				assertEqualByte(chunk[i], (b + 1) % 256);
				assertEqualByte(chunk[i + 1], c + 1);
			}
		}
	}

	// Verify each chunk is allocated, free each chunk,
	// then verify each chunk is freed.
	for (b = 0; b < totalBlocks; ++b) {
		assertNonZero(isBlockAllocated(b));
		for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
			assertNotNull(getChunk(TO_BLOCK_AND_CHUNK(b, c + 1)));
			freeChunk(TO_BLOCK_AND_CHUNK(b, c + 1));
			assertNull(getChunk(TO_BLOCK_AND_CHUNK(b, c + 1)));
		}
		assertZero(isBlockAllocated(b));
	}
}

void testFreeChunk(void)
{
	CHUNKNUM chunkNum;

	DECLARE_TEST("testFreeChunk");

	printf("Running test: Free Chunk\n");

	// Allocate a chunk
	assertNonZero(allocChunk(&chunkNum));

	// Retrieve the chunk
	assertNotNull(getChunk(chunkNum));

	// Free it
	freeChunk(chunkNum);

	// Attempt to retrieve it again
	assertNull(getChunk(chunkNum));
}

void testGetAvailChunks(void)
{
	CHUNKNUM chunkNum;
	int i, toAlloc = CHUNKS_PER_BLOCK - 5;

	DECLARE_TEST("testGetAvailChunks");

	printf("Running test: Get Avail Chunks\n");

	for (i = 0; i < toAlloc; ++i) {
		assertNonZero(allocChunk(&chunkNum));
	}

	assertEqualInt(toAlloc, getTotalChunks() - getAvailChunks());
}

void testGetTotalChunks(void)
{
	DECLARE_TEST("testGetTotalChunks");

	printf("Running test: Get Total Chunks\n");

	assertEqualInt(getTotalBlocks() * CHUNKS_PER_BLOCK, getTotalChunks());
}

void testRetrieveChunk(void)
{
	CHUNKNUM chunkNum;
	unsigned char *chunk, *chunk2;

	DECLARE_TEST("testRetrieveChunk");

	printf("Running test: Retrieve Chunk\n");

	// Test blockNum out of range
	assertNull(getChunk(TO_BLOCK_AND_CHUNK(getTotalBlocks(), 1)));

	// Test chunkNum out of range
	assertNull(getChunk(TO_BLOCK_AND_CHUNK(1, 0)));
	assertNull(getChunk(TO_BLOCK_AND_CHUNK(1, CHUNKS_PER_BLOCK + 1)));

	// Allocate a chunk and verify it can be retrieved
	assertNonZero(allocChunk(&chunkNum));
	chunk = getChunk(chunkNum);
	assertNotNull(chunk);
	assertEqualByte(0, GET_BLOCKNUM(chunkNum));
	assertEqualByte(1, GET_CHUNKNUM(chunkNum));
	memset(chunk, 1, CHUNK_LEN);

	// Retrieve the same chunk
	chunk2 = getChunk(chunkNum);
	assertNotNull(chunk2);
	assertEqualPointer(chunk, chunk2);

	// Try to retrieve a chunk that was never allocated
	assertNull(getChunk(
		TO_BLOCK_AND_CHUNK(GET_BLOCKNUM(chunkNum), GET_CHUNKNUM(chunkNum) + 1)
	));
}

void testReusingFreedChunks(void)
{
	int i, j;
	CHUNKNUM chunkNum;
	unsigned char *chunk;
	unsigned char b, c, value;
	unsigned char testChunks = CHUNKS_PER_BLOCK + CHUNKS_PER_BLOCK / 2;

	DECLARE_TEST("testReusingFreedChunks");

	printf("Running test: Reusing Freed Chunks\n");

	// Allocate about a block and a half of chunks,
	// setting each to unique values.

	for (i = 0; i < testChunks; ++i) {
		assertNonZero(allocChunk(&chunkNum));
		chunk = getChunk(chunkNum);
		assertNotNull(chunk);
		memset(chunk, i + 1, CHUNK_LEN);
	}

	// Free a couple chunks in the first block

	freeChunk(TO_BLOCK_AND_CHUNK(0, 5));
	freeChunk(TO_BLOCK_AND_CHUNK(0, 10));

	// And free one in the second block

	freeChunk(TO_BLOCK_AND_CHUNK(1, 5));

	// Retrieve a chunk from the first block to make it the
	// current block.  Allocations are always attempted in
	// the current block first.

	chunk = getChunk(TO_BLOCK_AND_CHUNK(0, 8));
	assertNotNull(chunk);

	// Reallocate two chunks

	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(0, GET_BLOCKNUM(chunkNum));
	assertEqualByte(5, GET_CHUNKNUM(chunkNum));
	chunk = getChunk(chunkNum);
	assertNotNull(chunk);
	memset(chunk, 50, CHUNK_LEN);

	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(0, GET_BLOCKNUM(chunkNum));
	assertEqualByte(10, GET_CHUNKNUM(chunkNum));
	chunk = getChunk(chunkNum);
	assertNotNull(chunk);
	memset(chunk, 100, CHUNK_LEN);

	// Reallocate a third chunk, which should come from the second block

	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(1, GET_BLOCKNUM(chunkNum));
	assertEqualByte(5, GET_CHUNKNUM(chunkNum));
	chunk = getChunk(chunkNum);
	assertNotNull(chunk);
	memset(chunk, 55, CHUNK_LEN);

	// Finally, allocate a fourth chunk, which should also come from the
	// second block.  But, this one is a new chunk that was never
	// previously allocated.

	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(1, GET_BLOCKNUM(chunkNum));
	assertEqualByte(testChunks + 1 - CHUNKS_PER_BLOCK, GET_CHUNKNUM(chunkNum));
	chunk = getChunk(chunkNum);
	assertNotNull(chunk);
	memset(chunk, testChunks + 1, CHUNK_LEN);

	// Verify each of the chunks

	b = 0;
	c = 1;
	for (i = 0; i <= testChunks; ++i) {
		chunk = getChunk(TO_BLOCK_AND_CHUNK(b, c));
		assertNotNull(chunk);
		value = i + 1;
		if (b == 0 && c == 5) {
			value = 50;
		} else if (b == 0 && c == 10) {
			value = 100;
		}
		else if (b == 1 && c == 5) {
			value = 55;
		}
		for (j = 0; j < CHUNK_LEN; ++j) {
			assertEqualByte(value, chunk[j]);
		}
		++c;
		if (c > CHUNKS_PER_BLOCK) {
			++b;
			c = 1;
		}
	}

	// Finally, try to retrieve a chunk after the last allocated one

	assertNull(getChunk(TO_BLOCK_AND_CHUNK(1, (testChunks/2) + 2)));
}

void testFreeingAllChunksInABlock(void)
{
	int b, c;
	CHUNKNUM chunkNum;

	DECLARE_TEST("testFreeingAllChunksInABlock");

	// Allocate enough chunks to go into a second block

	for (b = 0; b < 2; ++b) {
		for (c = 1; c <= CHUNKS_PER_BLOCK; ++c) {
			if (b == 1 && c > 5) {
				break;
			}
			assertNonZero(allocChunk(&chunkNum));
			assertEqualByte(b, GET_BLOCKNUM(chunkNum));
			assertEqualByte(c, GET_CHUNKNUM(chunkNum));
		}
	}

	// Free all chunk in the second block

	for (c = 1; c <= 5; ++c) {
		freeChunk(TO_BLOCK_AND_CHUNK(1, c));
		assertNull(getChunk(TO_BLOCK_AND_CHUNK(1, c)));
	}

	assertZero(isBlockAllocated(1));

	// Make sure we can retrieve a chunk in the first block

	assertNotNull(getChunk(TO_BLOCK_AND_CHUNK(0, 5)));
}
