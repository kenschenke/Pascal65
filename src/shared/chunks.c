#include <string.h>

#include <blocks.h>
#include <chunks.h>

static	BLOCKNUM		currentBlock;
static	unsigned char	*blockData;

static unsigned char AllocatedBlocks[TOTAL_BLOCKS];
static unsigned char FullBlocks[TOTAL_BLOCKS];

void initChunkStorage(void)
{
	currentBlock = 0;
	blockData = NULL;
	memset(AllocatedBlocks, 0, TOTAL_BLOCKS);
	memset(FullBlocks, 0, TOTAL_BLOCKS);
}

char allocChunk(CHUNKNUM *chunkNum)
{
	BLOCKNUM i;
	unsigned char c;

	// Do we have a current block allocated?
	if (currentBlock == 0) {
		// No we don't.  Allocate a new block.
		blockData = allocBlock(&currentBlock);
		if (blockData == NULL || currentBlock == 0) {
			return 0;
		}
		memset(blockData, 0, CHUNKS_PER_BLOCK);  // clear the used chunks part.
		AllocatedBlocks[currentBlock - 1] = 1;
		FullBlocks[currentBlock - 1] = 0;
	}

	// See if the current block has a free chunk.
	if (FullBlocks[currentBlock - 1]) {
		// It's full.  Store the current block and
		// look at other blocks that might have free chunks.
		if (storeBlock(currentBlock) == 0) {
			return 0;
		}
		currentBlock = 0;

		// Look for other blocks that might have free chunks.
		for (i = 0; i < TOTAL_BLOCKS; ++i) {
			if (AllocatedBlocks[i] && FullBlocks[i] == 0) {
				// This block has at least one spare chunk.
				blockData = retrieveBlock(i + 1);
				if (blockData == NULL) {
					return 0;
				}
				currentBlock = i + 1;
				break;
			}
		}
	}

	if (currentBlock) {
		// A block was found with a free chunk.
		// Find the free chunk in the block.
		for (i = 0; i < CHUNKS_PER_BLOCK; ++i) {
			if (blockData[i] == 0) {
				blockData[i] = 1;
				break;
			}
		}

		if (i < CHUNKS_PER_BLOCK) {
			c = i + 1;
			*chunkNum = TO_BLOCK_AND_CHUNK(currentBlock, c);

			// A chunk was allocated.  Look at the other allocated chunks
			// in this block.  If they're all allocated, mark the block as full.
			for (i = 0; i < CHUNKS_PER_BLOCK; ++i) {
				if (blockData[i] == 0) {
					break;
				}
			}
			if (i == CHUNKS_PER_BLOCK) {
				// The block is now full.
				FullBlocks[currentBlock - 1] = 1;
			}
			return 1; // blockData + CHUNKS_PER_BLOCK + (c - 1) * CHUNK_LEN;
		}
	}

	// No currently allocated blocks have a free chunk.  Allocate a new block.
	blockData = allocBlock(&currentBlock);
	if (blockData == NULL || currentBlock == 0) {
		return 0;
	}
	memset(blockData, 0, CHUNKS_PER_BLOCK);  // clear the used chunks part.
	AllocatedBlocks[currentBlock - 1] = 1;
	FullBlocks[currentBlock - 1] = 0;
	blockData[0] = 1;	// mark the first chunk as allocated

	*chunkNum = TO_BLOCK_AND_CHUNK(currentBlock, 1);
	return 1; // blockData + CHUNKS_PER_BLOCK;
}

void freeChunk(CHUNKNUM chunkNum)
{
	BLOCKNUM blockNum;
	unsigned char i, c;

	// Validate blockNum and chunkNum
	blockNum = GET_BLOCKNUM(chunkNum);
	c = GET_CHUNKNUM(chunkNum);
	if (blockNum < 1 || blockNum > TOTAL_BLOCKS) {
		return;
	}
	if (c < 1 || c > CHUNKS_PER_BLOCK) {
		return;
	}

	// Make sure the block is actually allocated
	if (AllocatedBlocks[blockNum - 1] == 0) {
		return;
	}

	if (currentBlock == 0 || currentBlock != blockNum) {
		// The chunk is in a different block.  Store the
		// current block and retrieve the other one.
		if (currentBlock) {
			if (storeBlock(currentBlock) == 0) {
				return;
			}
			currentBlock = 0;
		}
		blockData = retrieveBlock(blockNum);
		if (blockData == NULL) {
			return;
		}
		currentBlock = blockNum;
	}

	blockData[c - 1] = 0;
	FullBlocks[blockNum - 1] = 0;

	// Check if all other chunks in this block are also freed.
	// If so, free the block too.
	for (i = 0; i < CHUNKS_PER_BLOCK; ++i) {
		if (blockData[i]) {
			break;
		}
	}
	if (i == CHUNKS_PER_BLOCK) {
		// All the chunks are free.  The block can be freed too.
		freeBlock(blockNum);
		AllocatedBlocks[blockNum - 1] = 0;
	}
}

char retrieveChunk(CHUNKNUM chunkNum, unsigned char *bytes)
{
	BLOCKNUM blockNum;
	unsigned char c;

	// Validate blockNum and chunkNum
	blockNum = GET_BLOCKNUM(chunkNum);
	c = GET_CHUNKNUM(chunkNum);
	if (blockNum < 1 || blockNum > TOTAL_BLOCKS) {
		return 0;
	}
	if (c < 1 || c > CHUNKS_PER_BLOCK) {
		return 0;
	}

	// Make sure the block is actually allocated
	if (AllocatedBlocks[blockNum - 1] == 0) {
		return 0;
	}

	if (currentBlock == 0 || currentBlock != blockNum) {
		// The chunk is in a different block.  Store the
		// current block and retrieve the other one.
		if (currentBlock) {
			if (storeBlock(currentBlock) == 0) {
				return 0;
			}
			currentBlock = 0;
		}
		blockData = retrieveBlock(blockNum);
		if (blockData == NULL) {
			return 0;
		}
		currentBlock = blockNum;
	}

	// Make sure the chunk is allocated
	if (blockData[c - 1] == 0) {
		return 0;
	}

	memcpy(bytes, blockData + CHUNKS_PER_BLOCK + (c - 1) * CHUNK_LEN, CHUNK_LEN);
	return 1;
}

char storeChunk(CHUNKNUM chunkNum, unsigned char *bytes) {
	BLOCKNUM blockNum;
	unsigned char c;

	// Validate blockNum and chunkNum
	blockNum = GET_BLOCKNUM(chunkNum);
	c = GET_CHUNKNUM(chunkNum);
	if (blockNum < 1 || blockNum > TOTAL_BLOCKS) {
		return 0;
	}
	if (c < 1 || c > CHUNKS_PER_BLOCK) {
		return 0;
	}

	// Make sure the block is actually allocated
	if (AllocatedBlocks[blockNum - 1] == 0) {
		return 0;
	}

	if (currentBlock == 0 || currentBlock != blockNum) {
		// The chunk is in a different block.  Store the
		// current block and retrieve the other one.
		if (currentBlock) {
			if (storeBlock(currentBlock) == 0) {
				return 0;
			}
			currentBlock = 0;
		}
		blockData = retrieveBlock(blockNum);
		if (blockData == NULL) {
			return 0;
		}
		currentBlock = blockNum;
	}

	memcpy(blockData + CHUNKS_PER_BLOCK + (c - 1) * CHUNK_LEN, bytes, CHUNK_LEN);
	return 1;
}

#ifdef __TEST__
unsigned char isChunkAllocated(CHUNKNUM chunkNum)
{
	BLOCKNUM blockNum;
	unsigned char c;

	blockNum = GET_BLOCKNUM(chunkNum);
	c = GET_CHUNKNUM(chunkNum);
	if (AllocatedBlocks[blockNum - 1] == 0) {
		return 0;
	}

	if (currentBlock != blockNum) {
		blockData = retrieveBlock(blockNum);
		if (blockData == NULL) {
			return 0;
		}
		currentBlock = blockNum;
	}

	return blockData[c - 1];
}
#endif
