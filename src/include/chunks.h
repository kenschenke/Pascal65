#ifndef CHUNKS_H
#define CHUNKS_H

#include "blocks.h"

#define CHUNK_LEN 23
#define CHUNKS_PER_BLOCK 42

#define TO_BLOCK_AND_CHUNK(b, c) (c | (b << 8))
#define GET_BLOCKNUM(x) (x >> 8 & 0xff)
#define GET_CHUNKNUM(x) (x & 0xff)

typedef unsigned short CHUNKNUM;

/*
	These functions remember the current chunk and block.
	When the caller wants to interact with a different block,
	the current block is automatically stored.
*/

// Allocates a new chunk.
// Chunk number returned by ref.
// Zero returned on failure.  Non-zero on success.
char allocChunk(CHUNKNUM *chunkNum);

// Frees chunk and flushes block to storage since it
// loses currency.
void freeChunk(CHUNKNUM chunkNum);

// Returns the number of available chunks.
int getAvailChunks(void);

// Returns the total number of chunks in memory,
// allocated and unallocated.
int getTotalChunks(void);

// Retrieves the data in the chunk and copies into
// callers buffer.  Buffer must be at least CHUNK_LEN long.
// Zero is returned on failure.  Non-zero on success.
char retrieveChunk(CHUNKNUM chunkNum, unsigned char *chunk);

// Stores the bytes in the chunk.
char storeChunk(CHUNKNUM chunkNum, unsigned char *chunk);

void initChunkStorage(void);

// Functions needed for unit testing
#ifdef __TEST__
unsigned char isChunkAllocated(CHUNKNUM chunkNum);
#endif

#endif // end of CHUNKS_H
