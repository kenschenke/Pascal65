/**
 * chunks.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for memory chunk allocation.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef CHUNKS_H
#define CHUNKS_H

#include "blocks.h"

#define CHUNK_LEN 23
#define CHUNKS_PER_BLOCK 11

#define TO_BLOCK_AND_CHUNK(b, c) (c | (b << 4))
#define GET_BLOCKNUM(x) (x >> 4)
#define GET_CHUNKNUM(x) (x & 0x0f)

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

// Flushes the chunk's current block and writes it
// to extended memory.
void flushChunkBlock(void);

// Frees chunk and flushes block to storage since it
// loses currency.
void freeChunk(CHUNKNUM chunkNum);

// Returns the number of available chunks.
int getAvailChunks(void);

// Returns the total number of chunks in memory,
// allocated and unallocated.
unsigned getTotalChunks(void);

// Retrieves the chunk and returns a pointer to the chunk
// or NULL on failure.  Changes made to the chunk are
// automatically saved when another chunk is requested.
// ******** W A R N I N G: ********
// The returned pointer is only guaranteed valid until the
// next call to any function that stores, retrieves, or
// frees a chunk or block.
void *getChunk(CHUNKNUM chunkNum);

// Retrieves the data in the chunk and copies into
// caller's buffer.  Buffer must be at least CHUNK_LEN long.
// Zero is returned on failure.  Non-zero on success.
char getChunkCopy(CHUNKNUM chunkNum, void *buffer);

// Retrieves the data in the chunk and copies into
// caller's buffer.  Buffer must be at least CHUNK_LEN long.
// Zero is returned on failure.  Non-zero on success.
char retrieveChunk(CHUNKNUM chunkNum, void *chunk);

// Stores the bytes in the chunk.
char storeChunk(CHUNKNUM chunkNum, void *chunk);

void initChunkStorage(void);

// Functions needed for unit testing
unsigned char isChunkAllocated(CHUNKNUM chunkNum);

#endif // end of CHUNKS_H
