#include <stdio.h>
#include <membuf.h>
#include <string.h>
#include "memtest.h"

void flushMemCache(void);

void testAllocateSmallBuffer(void)
{
    MEMBUF hdr;
    MEMBUF_CHUNK bufChunk;
    CHUNKNUM chunkNum;

	DECLARE_TEST("testAllocateSmallBuffer");

	printf("Running test: Allocate Small Buffer\n");

    allocMemBuf(&chunkNum);
    assertNonZero(chunkNum);
    flushMemCache();
    assertNonZero(isMemBufAtEnd(chunkNum));
    reserveMemBuf(chunkNum, 10);
    flushMemCache();
    assertZero(isMemBufAtEnd(chunkNum));
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertEqualInt(MEMBUF_CHUNK_LEN, hdr.capacity);
    assertEqualInt(10, hdr.used);
    assertNonZero(retrieveChunk(hdr.firstChunkNum, (unsigned char *)&bufChunk));
    assertEqualInt(0, bufChunk.nextChunk);
}

void testAllocateBufferOfOneChunkSize(void)
{
    MEMBUF hdr;
    MEMBUF_CHUNK bufChunk;
    CHUNKNUM chunkNum;

	DECLARE_TEST("testAllocateOneChunkBuffer");

	printf("Running test: Buffer of One Chunk Size\n");

    allocMemBuf(&chunkNum);
    assertNonZeroChunkNum(chunkNum);
    reserveMemBuf(chunkNum, MEMBUF_CHUNK_LEN);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertEqualInt(MEMBUF_CHUNK_LEN, hdr.capacity);
    assertEqualInt(MEMBUF_CHUNK_LEN, hdr.used);
    assertNonZeroChunkNum(hdr.firstChunkNum);
    assertNonZero(retrieveChunk(hdr.firstChunkNum, (unsigned char *)&bufChunk));
    assertEqualInt(0, bufChunk.nextChunk);
}

void testAllocateBufferOfTwoChunks(void)
{
    MEMBUF hdr;
    MEMBUF_CHUNK bufChunk;
    CHUNKNUM chunkNum;

	DECLARE_TEST("testAllocateTwoChunksBuffer");

	printf("Running test: Buffer of Two Chunks\n");

    allocMemBuf(&chunkNum);
    assertNonZeroChunkNum(chunkNum);
    reserveMemBuf(chunkNum, MEMBUF_CHUNK_LEN + 1);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertNonZeroChunkNum(hdr.firstChunkNum);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.capacity);
    assertEqualInt(MEMBUF_CHUNK_LEN + 1, hdr.used);
    assertNonZero(retrieveChunk(hdr.firstChunkNum, (unsigned char *)&bufChunk));
    assertNonZeroChunkNum(bufChunk.nextChunk);
    assertNonZero(retrieveChunk(bufChunk.nextChunk, (unsigned char *)&bufChunk));
    assertEqualInt(0, bufChunk.nextChunk);
}

void testAllocateBufferTwice(void)
{
    MEMBUF hdr;
    MEMBUF_CHUNK bufChunk;
    CHUNKNUM chunkNum;

	DECLARE_TEST("testAllocateBufferTwice");

	printf("Running test: Buffer Allocated Twice\n");

    allocMemBuf(&chunkNum);
    assertNonZeroChunkNum(chunkNum);
    reserveMemBuf(chunkNum, MEMBUF_CHUNK_LEN + 1);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertNonZeroChunkNum(hdr.firstChunkNum);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.capacity);
    assertEqualInt(MEMBUF_CHUNK_LEN + 1, hdr.used);
    assertNonZero(retrieveChunk(hdr.firstChunkNum, (unsigned char *)&bufChunk));
    assertNonZeroChunkNum(bufChunk.nextChunk);
    assertNonZero(retrieveChunk(bufChunk.nextChunk, (unsigned char *)&bufChunk));
    assertEqualInt(0, bufChunk.nextChunk);

    reserveMemBuf(chunkNum, 10);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertNonZeroChunkNum(hdr.firstChunkNum);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.capacity);
    assertEqualInt(MEMBUF_CHUNK_LEN + 1, hdr.used);
    assertNonZero(retrieveChunk(hdr.firstChunkNum, (unsigned char *)&bufChunk));
    assertNonZeroChunkNum(bufChunk.nextChunk);
    assertNonZero(retrieveChunk(bufChunk.nextChunk, (unsigned char *)&bufChunk));
    assertEqualInt(0, bufChunk.nextChunk);
}

void testExpandBuffer(void)
{
    MEMBUF hdr;
    MEMBUF_CHUNK bufChunk;
    CHUNKNUM chunkNum;

	DECLARE_TEST("testExpandBuffer");

	printf("Running test: Expand Buffer\n");

    allocMemBuf(&chunkNum);
    assertNonZeroChunkNum(chunkNum);
    reserveMemBuf(chunkNum, MEMBUF_CHUNK_LEN + 1);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertNonZeroChunkNum(hdr.firstChunkNum);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.capacity);
    assertEqualInt(MEMBUF_CHUNK_LEN + 1, hdr.used);
    assertNonZero(retrieveChunk(hdr.firstChunkNum, (unsigned char *)&bufChunk));
    assertNonZeroChunkNum(bufChunk.nextChunk);
    assertNonZero(retrieveChunk(bufChunk.nextChunk, (unsigned char *)&bufChunk));
    assertEqualInt(0, bufChunk.nextChunk);

    reserveMemBuf(chunkNum, MEMBUF_CHUNK_LEN * 2 + 1);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertNonZeroChunkNum(hdr.firstChunkNum);
    assertEqualInt(MEMBUF_CHUNK_LEN * 3, hdr.capacity);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2 + 1, hdr.used);
    assertNonZero(retrieveChunk(hdr.firstChunkNum, (unsigned char *)&bufChunk));
    assertNonZeroChunkNum(bufChunk.nextChunk);
    assertNonZero(retrieveChunk(bufChunk.nextChunk, (unsigned char *)&bufChunk));
    assertNonZeroChunkNum(bufChunk.nextChunk);
    assertNonZero(retrieveChunk(bufChunk.nextChunk, (unsigned char *)&bufChunk));
    assertEqualInt(0, bufChunk.nextChunk);
}

void testFreeBuffer(void)
{
    CHUNKNUM chunkNum;
    unsigned availChunks;

	DECLARE_TEST("testFreeBuffer");

	printf("Running test: Free Buffer\n");

    availChunks = getAvailChunks();

    allocMemBuf(&chunkNum);
    assertNonZeroChunkNum(chunkNum);
    reserveMemBuf(chunkNum, MEMBUF_CHUNK_LEN + 1);
    assertEqualInt(availChunks - 3, getAvailChunks());
    freeMemBuf(chunkNum);
    assertEqualInt(availChunks, getAvailChunks());
}

void testSetBufferPosition(void)
{
    MEMBUF hdr;
    MEMBUF_CHUNK bufChunk;
    CHUNKNUM chunkNum;

	DECLARE_TEST("testSetBufferPosition");

	printf("Running test: Set Buffer Position\n");

    allocMemBuf(&chunkNum);
    assertNonZeroChunkNum(chunkNum);
    reserveMemBuf(chunkNum, MEMBUF_CHUNK_LEN * 2);

    // Test position in second chunk

    setMemBufPos(chunkNum, MEMBUF_CHUNK_LEN + 2);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertNonZeroChunkNum(hdr.firstChunkNum);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.capacity);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.used);
    assertEqualInt(MEMBUF_CHUNK_LEN + 2, hdr.posGlobal);
    assertEqualInt(2, hdr.posChunk);
    assertNonZero(retrieveChunk(hdr.firstChunkNum, (unsigned char *)&bufChunk));
    assertNonZeroChunkNum(bufChunk.nextChunk);

    // Try seeking past the end of the capacity

    setMemBufPos(chunkNum, MEMBUF_CHUNK_LEN * 2);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.posGlobal);
    assertEqualInt(0, hdr.posChunk);

    // Test resetting the position to 0

    setMemBufPos(chunkNum, 0);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertEqualInt(0, hdr.posGlobal);
    assertEqualInt(0, hdr.posChunk);
}

void testBufferReadAndWrite(void)
{
    int i;
    char ch;
    MEMBUF hdr;
    CHUNKNUM chunkNum;

	DECLARE_TEST("testBufferReadAndWrite");

	printf("Running test: Buffer Read and Write\n");

    allocMemBuf(&chunkNum);
    assertNonZeroChunkNum(chunkNum);
    flushMemCache();
    assertNonZero(isMemBufAtEnd(chunkNum));

    for (ch = 'A'; ch <= 'Z'; ++ch) {
        writeToMemBuf(chunkNum, &ch, 1);
    }
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
    assertNonZero(isMemBufAtEnd(chunkNum));
   
    assertEqualInt(26, hdr.posGlobal);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.capacity);
    assertEqualInt(26, hdr.used);

    setMemBufPos(chunkNum, 0);
    flushMemCache();
    assertZero(isMemBufAtEnd(chunkNum));
    for (i = 0; i < 26; ++i) {
        readFromMemBuf(chunkNum, &ch, 1);
        assertEqualByte(i + 'A', ch);
    }

    setMemBufPos(chunkNum, 3);
    readFromMemBuf(chunkNum, &ch, 1);
    assertEqualByte('D', ch);

    setMemBufPos(chunkNum, 20);
    readFromMemBuf(chunkNum, &ch, 1);
    assertEqualByte('U', ch);
    flushMemCache();
    assertZero(isMemBufAtEnd(chunkNum));
}

void testBufferMultiByteReadAndWrite(void)
{
    int i;
    char ch, buffer[26];
    MEMBUF hdr;
    CHUNKNUM chunkNum;

	DECLARE_TEST("testBufferMultiReadAndWrite");

	printf("Running test: Buffer Multi-Byte R/W\n");

    allocMemBuf(&chunkNum);
    assertNonZeroChunkNum(chunkNum);

    // initialize the buffer

    for (i=0,ch='A'; i < 26; ++i,++ch) {
        buffer[i] = ch;
    }
    writeToMemBuf(chunkNum, buffer, 26);
    flushMemCache();
    assertNonZero(retrieveChunk(chunkNum, (unsigned char *)&hdr));
   
    assertEqualInt(26, hdr.posGlobal);
    assertEqualInt(MEMBUF_CHUNK_LEN * 2, hdr.capacity);
    assertEqualInt(26, hdr.used);

    setMemBufPos(chunkNum, 0);
    memset(buffer, 0, 26);
    readFromMemBuf(chunkNum, buffer, 26);
    for (i=0,ch='A'; i < 26; ++i,++ch) {
        assertEqualByte(ch, buffer[i]);
    }
}