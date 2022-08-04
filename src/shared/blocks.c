#include <stdio.h>
#include <memory.h>
#include <blocks.h>
#include <chunks.h>
#include <string.h>

#ifdef __TEST__
#define TEST_OFFSET 10
#else
#define TEST_OFFSET 0
#endif

// Mega65 banks 4 and 5
static long banks[] = {
    0x40000,
    0x50000
};	// bank memory addresses

static unsigned char BlocksUsed[TOTAL_BLOCKS];

static unsigned char SharedBlock[BLOCK_LEN + TEST_OFFSET * 2];

static void transferFromBank(BLOCKNUM blockNum);
static void transferToBank(BLOCKNUM blockNum);

static void transferFromBank(unsigned char blockNum)
{
	unsigned char bank = (blockNum - 1) / BLOCKS_PER_BANK;
	unsigned char block = (blockNum - 1) % BLOCKS_PER_BANK;
    lcopy(
        banks[bank] + (long)block * BLOCK_LEN,  // source
        (long)SharedBlock + TEST_OFFSET,        // destination
        BLOCK_LEN                               // bytes to copy
    );
}

static void transferToBank(BLOCKNUM blockNum)
{
	unsigned char bank = (blockNum - 1) / BLOCKS_PER_BANK;
	unsigned char block = (blockNum - 1) % BLOCKS_PER_BANK;
    lcopy(
        (long)SharedBlock + TEST_OFFSET,        // source
        banks[bank] + (long)block * BLOCK_LEN,  // destination
        BLOCK_LEN                               // bytes to copy
    );
}

void initBlockStorage(void)
{
    int i;
    for (i = 0; i < TOTAL_BLOCKS; ++i) {
        BlocksUsed[i] = 0;
    }
	initChunkStorage();

#ifdef __TEST__
	memset(SharedBlock, 'X', TEST_OFFSET);
	memset(SharedBlock + TEST_OFFSET, 0, BLOCK_LEN);
	memset(SharedBlock + TEST_OFFSET + BLOCK_LEN, 'X', TEST_OFFSET);
#endif
}

unsigned char *allocBlock(BLOCKNUM *blockNum)
{
	int i;

	for (i = 0; i < TOTAL_BLOCKS; ++i) {
		if (BlocksUsed[i] == 0) {
			BlocksUsed[i] = 1;
			*blockNum = i + 1;
			return SharedBlock + TEST_OFFSET;
		}
	}

	return NULL;
}

void freeBlock(BLOCKNUM blockNum)
{
	if (blockNum > 0 && blockNum <= TOTAL_BLOCKS)
		BlocksUsed[blockNum - 1] = 0;
}

unsigned char *retrieveBlock(BLOCKNUM blockNum)
{
	// Block numbers are 1-based
	if (blockNum < 1 || blockNum > TOTAL_BLOCKS) {
		return NULL;
	}

	// Make sure the block is allocated
	if (BlocksUsed[blockNum - 1] == 0) {
		return NULL;
	}

	transferFromBank(blockNum);

	return SharedBlock + TEST_OFFSET;
}

unsigned char storeBlock(BLOCKNUM blockNum)
{
	// Block numbers are 1-based
	if (blockNum < 1 || blockNum > TOTAL_BLOCKS) {
		return 0;
	}

	// Make sure the block is allocated
	if (BlocksUsed[blockNum - 1] == 0) {
		return 0;
	}

	transferToBank(blockNum);

	return 1;
}

#ifdef __TEST__
unsigned char isBlockAllocated(BLOCKNUM blockNum)
{
	return BlocksUsed[blockNum - 1];
}

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
