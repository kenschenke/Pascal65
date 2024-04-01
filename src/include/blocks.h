/**
 * blocks.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for memory block allocation.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef BLOCKS_H
#define BLOCKS_H

#define BLOCK_LEN 256

#ifdef __MEGA65__
#include <blocks_mega65.h>
#endif

#define MAX_BLOCKS 4096		// 1 megabyte memory (256 bytes per block)

typedef unsigned BLOCKNUM;

/*
	This is a simple, stateless interface.  Block numbers are zero-based.
*/

void initBlockStorage(void);

// Allocates a new block.  Pointer to the buffer returned or NULL
// if allocation failed.  Zero-based block number returned by ref.
unsigned char *allocBlock(BLOCKNUM *blockNum);

// Allocates a group of consecutive blocks.  The starting
// block number is returned via the first parameter.
// The starting block number is an REU page number that can be
// passed to em_copyto() and em_copyfrom().
//
// NOTE: This is intended for caching overlays or other large
// blocks of extended memory.  Once allocated, the blocks are
// permanently removed from available allocation.
//
// NOTE: Be sure to call flushChunkBlock() before calling
// em_copyfrom() or em_copyto() to make sure the chunking
// routines are not inadvertantly using state or invalid blocks.
//
// Non-zero is returned on success.
char allocBlockGroup(BLOCKNUM *blockNum, unsigned numBlocks);

// Frees the block.  Block number is zero-based.
void freeBlock(BLOCKNUM blockNum);

unsigned getTotalBlocks(void);

// Retrieves a block from storage and returns a pointer to the
// buffer or NULL if the block could not be retrieved.
// Block number is zero-based.
unsigned char *retrieveBlock(BLOCKNUM blockNum);

// Stores the block.  Block number is zero-based.
// 0 is returned on failure, non-zero on success.
unsigned char storeBlock(BLOCKNUM blockNum);

// Returns non-zero if block is allocated.
// Block number is zero-based.
char isBlockAllocated(BLOCKNUM blockNum);

// Functions used during unit testing
#ifdef __TEST__
unsigned char wasBankMemoryCorrupted(void);
#endif

#endif // end of BLOCKS_H
