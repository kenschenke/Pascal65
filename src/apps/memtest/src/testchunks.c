#include <stdio.h>
#include <blocks.h>
#include <chunks.h>
#include "memtest.h"
#include <memory.h>
#include <string.h>

void testAllocateAllChunks(void)
{
	int i, b, c;
	CHUNKNUM chunkNum;
	unsigned char chunk[CHUNK_LEN];

	DECLARE_TEST("testAllocateAllChunks");

	printf("Running test: Allocate All Chunks\n");

	// Allocate each chunk and set its contents to unique values
	for (b = 0; b < TOTAL_BLOCKS; ++b) {
		for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
			assertNonZero(allocChunk(&chunkNum));
			assertEqualByte(b + 1, GET_BLOCKNUM(chunkNum));
			assertEqualByte(c + 1, GET_CHUNKNUM(chunkNum));

			for (i = 0; i < CHUNK_LEN - (CHUNK_LEN % 2); i += 2) {
				chunk[i] = b + 1;
				chunk[i + 1] = c + 1;
			}

			assertNonZero(storeChunk(chunkNum, chunk));
		}
	}

	// Retrieve each chunk and verify its contents
	for (b = 0; b < TOTAL_BLOCKS; ++b) {
		for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
			assertNonZero(retrieveChunk(TO_BLOCK_AND_CHUNK(b + 1, c + 1), chunk));

			for (i = 0; i < CHUNK_LEN - (CHUNK_LEN % 2); i += 2) {
				assertEqualByte(chunk[i], b + 1);
				assertEqualByte(chunk[i + 1], c + 1);
			}
		}
	}

	// Attempt to allocate one more chunk
	assertZero(allocChunk(&chunkNum));

	// Verify each chunk is allocated, free each chunk,
	// then verify each chunk is freed.
	for (b = 0; b < TOTAL_BLOCKS; ++b) {
		assertNonZero(isBlockAllocated(b + 1));
		for (c = 0; c < CHUNKS_PER_BLOCK; ++c) {
			assertNonZero(isChunkAllocated(TO_BLOCK_AND_CHUNK(b + 1, c + 1)));
			freeChunk(TO_BLOCK_AND_CHUNK(b + 1, c + 1));
			assertZero(isChunkAllocated(TO_BLOCK_AND_CHUNK(b + 1, c + 1)));
		}
		assertZero(isBlockAllocated(b + 1));
	}
}

void testRetrieveChunk(void)
{
	CHUNKNUM chunkNum;
	unsigned char chunk[CHUNK_LEN], chunk2[CHUNK_LEN];

	DECLARE_TEST("testRetrieveChunk");

	printf("Running test: Retrieve Chunk\n");

	// Test blockNum out of range
	assertZero(retrieveChunk(TO_BLOCK_AND_CHUNK(0, 1), chunk));
	assertZero(retrieveChunk(TO_BLOCK_AND_CHUNK(TOTAL_BLOCKS + 1, 1), chunk));

	// Test chunkNum out of range
	assertZero(retrieveChunk(TO_BLOCK_AND_CHUNK(1, 0), chunk));
	assertZero(retrieveChunk(TO_BLOCK_AND_CHUNK(1, CHUNKS_PER_BLOCK + 1), chunk));

	// Try to retrieve an unallocated chunk
	assertZero(retrieveChunk(TO_BLOCK_AND_CHUNK(1, 1), chunk));

	// Allocate a chunk and verify it can be retrieved
	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(1, GET_BLOCKNUM(chunkNum));
	assertEqualByte(1, GET_CHUNKNUM(chunkNum));
	memset(chunk, 1, CHUNK_LEN);
	assertNonZero(storeChunk(chunkNum, chunk));

	// Retrieve the same chunk
	assertNonZero(retrieveChunk(chunkNum, chunk2));
	assertZero(memcmp(chunk, chunk2, CHUNK_LEN));
}

void testReusingFreedChunks(void)
{
	int i, j;
	CHUNKNUM chunkNum;
	unsigned char chunk[CHUNK_LEN];
	unsigned char b, c, value;
	unsigned char testChunks = CHUNKS_PER_BLOCK + CHUNKS_PER_BLOCK / 2;

	DECLARE_TEST("testReusingFreedChunks");

	printf("Running test: Reusing Freed Chunks\n");

	// Allocate about a block and a half of chunks,
	// setting each to unique values.

	for (i = 0; i < testChunks; ++i) {
		assertNonZero(allocChunk(&chunkNum));
		memset(chunk, i + 1, CHUNK_LEN);
		assertNonZero(storeChunk(chunkNum, chunk));
	}

	// Free a couple chunks in the first block

	freeChunk(TO_BLOCK_AND_CHUNK(1, 5));
	freeChunk(TO_BLOCK_AND_CHUNK(1, 10));

	// And free one in the second block

	freeChunk(TO_BLOCK_AND_CHUNK(2, 5));

	// Retrieve a chunk from the first block to make it the
	// current block.  Allocations are always attempted in
	// the current block first.

	assertNonZero(retrieveChunk(TO_BLOCK_AND_CHUNK(1, 15), chunk));

	// Reallocate two chunks

	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(1, GET_BLOCKNUM(chunkNum));
	assertEqualByte(5, GET_CHUNKNUM(chunkNum));
	memset(chunk, 50, CHUNK_LEN);
	assertNonZero(storeChunk(chunkNum, chunk));

	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(1, GET_BLOCKNUM(chunkNum));
	assertEqualByte(10, GET_CHUNKNUM(chunkNum));
	memset(chunk, 100, CHUNK_LEN);
	assertNonZero(storeChunk(chunkNum, chunk));

	// Reallocate a third chunk, which should come from the second block

	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(2, GET_BLOCKNUM(chunkNum));
	assertEqualByte(5, GET_CHUNKNUM(chunkNum));
	memset(chunk, 55, CHUNK_LEN);
	assertNonZero(storeChunk(chunkNum, chunk));

	// Finally, allocate a fourth chunk, which should also come from the
	// second block.  But, this one is a new chunk that was never
	// previously allocated.

	assertNonZero(allocChunk(&chunkNum));
	assertEqualByte(2, GET_BLOCKNUM(chunkNum));
	assertEqualByte(testChunks + 1 - CHUNKS_PER_BLOCK, GET_CHUNKNUM(chunkNum));
	memset(chunk, testChunks + 1, CHUNK_LEN);
	assertNonZero(storeChunk(chunkNum, chunk));

	// Verify each of the chunks

	b = 1;
	c = 1;
	for (i = 0; i <= testChunks; ++i) {
		assertNonZero(retrieveChunk(TO_BLOCK_AND_CHUNK(b, c), chunk));
		value = i + 1;
		if (b == 1 && c == 5) {
			value = 50;
		} else if (b == 1 && c == 10) {
			value = 100;
		}
		else if (b == 2 && c == 5) {
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

	assertZero(retrieveChunk(TO_BLOCK_AND_CHUNK(2, testChunks + 2), chunk));
}