/**
 * blocks.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for memory block allocation.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef BLOCKS_H
#define BLOCKS_H

#define BLOCK_LEN 1024
#define BANKS 2
#define BLOCKS_PER_BANK 64
#define TOTAL_BLOCKS (BANKS * BLOCKS_PER_BANK)

typedef unsigned char BLOCKNUM;

/*
	This is a simple, stateless interface.  Block numbers are 1-based.
*/

void initBlockStorage(void);

// Allocates a new block.  Pointer to the buffer returned or NULL
// if allocation failed.  1-based block number returned by ref.
unsigned char *allocBlock(BLOCKNUM *blockNum);

// Frees the block.  Block number is 1-based.
void freeBlock(BLOCKNUM blockNum);

// Retrieves a block from storage and returns a pointer to the
// buffer or NULL if the block could not be retrieved.
// Block number is 1-based.
unsigned char *retrieveBlock(BLOCKNUM blockNum);

// Stores the block.  Block number is 1-based.
// 0 is returned on failure, non-zero on success.
unsigned char storeBlock(BLOCKNUM blockNum);

// Returns non-zero if block is allocated.
// Block number is 1-based.
unsigned char isBlockAllocated(BLOCKNUM blockNum);

// Functions used during unit testing
#ifdef __TEST__
unsigned char wasBankMemoryCorrupted(void);
#endif

#endif // end of BLOCKS_H
