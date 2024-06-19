/**
 * membuf.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <membuf.h>
#include <string.h>

#define CHUNKS_PER_INDEX 10
#define BYTES_PER_INDEX (21*CHUNKS_PER_INDEX)

MEMBUF cachedMemBufHdr;
CHUNKNUM cachedMemBufHdrChunkNum;

MEMBUF_CHUNK cachedMemBufData;
CHUNKNUM cachedMemBufDataChunkNum;

void flushMemBufCache(void);
static void initMemBufChunk(CHUNKNUM hdrChunkNum);
static void loadMemBufDataCache(CHUNKNUM dataChunkNum);
static void loadMemBufHeaderCache(CHUNKNUM hdrChunkNum);

// void copyFromMemBuf(CHUNKNUM header, void *buffer, unsigned offset, unsigned length);

void allocMemBuf(CHUNKNUM *pChunkNum)
{
    flushMemBufCache();
    memset(&cachedMemBufHdr, 0, sizeof(MEMBUF));

    allocChunk(pChunkNum);
    storeChunk(*pChunkNum, &cachedMemBufHdr);
}

void copyToMemBuf(CHUNKNUM header, void *buffer, unsigned offset, unsigned length)
{
    setMemBufPos(header, offset);
    writeToMemBuf(header, buffer, length);
}

void flushMemBufCache()
{
    if (cachedMemBufHdrChunkNum && isChunkAllocated(cachedMemBufHdrChunkNum)) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
    }
    cachedMemBufHdrChunkNum = 0;

    if (cachedMemBufDataChunkNum && isChunkAllocated(cachedMemBufDataChunkNum)) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
    }
    cachedMemBufDataChunkNum = 0;
}

void flushMemCache(void)
{
    flushMemBufCache();
}

unsigned getMemBufPos(CHUNKNUM hdrChunkNum)
{
    loadMemBufHeaderCache(hdrChunkNum);

    return cachedMemBufHdr.posGlobal;
}

void initMemBufCache(void)
{
    cachedMemBufDataChunkNum = 0;
    cachedMemBufHdrChunkNum = 0;
}

static void initMemBufChunk(CHUNKNUM hdrChunkNum)
{
    CHUNKNUM chunkNum;

    flushMemBufCache();

    loadMemBufHeaderCache(hdrChunkNum);

    allocChunk(&chunkNum);
    if (!cachedMemBufHdr.firstChunkNum) {
        cachedMemBufHdr.firstChunkNum = chunkNum;
    } else if (cachedMemBufHdr.currentChunkNum) {
        retrieveChunk(cachedMemBufHdr.currentChunkNum, &cachedMemBufData);
        cachedMemBufData.nextChunk = chunkNum;
        storeChunk(cachedMemBufHdr.currentChunkNum, &cachedMemBufData);
    }
    cachedMemBufHdr.currentChunkNum = chunkNum;

    memset(&cachedMemBufData, 0, sizeof(MEMBUF_CHUNK));
    storeChunk(chunkNum, &cachedMemBufData);

    cachedMemBufHdr.capacity += MEMBUF_CHUNK_LEN;
}

char isMemBufAtEnd(CHUNKNUM hdrChunkNum)
{
    loadMemBufHeaderCache(hdrChunkNum);

    return cachedMemBufHdr.posGlobal >= cachedMemBufHdr.used ? 1 : 0;
}

static void loadMemBufDataCache(CHUNKNUM dataChunkNum)
{
    if (dataChunkNum == cachedMemBufDataChunkNum) {
        return;
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
    }

    if (dataChunkNum) {
        retrieveChunk(dataChunkNum, &cachedMemBufData);
    }
    cachedMemBufDataChunkNum = dataChunkNum;
}

static void loadMemBufHeaderCache(CHUNKNUM hdrChunkNum)
{
    if (hdrChunkNum == cachedMemBufHdrChunkNum) {
        return;
    }

    if (cachedMemBufHdrChunkNum && isChunkAllocated(cachedMemBufHdrChunkNum)) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
    }

    retrieveChunk(hdrChunkNum, &cachedMemBufHdr);
    cachedMemBufHdrChunkNum = hdrChunkNum;
}

void reserveMemBuf(CHUNKNUM hdrChunkNum, unsigned size)
{
    CHUNKNUM chunkNum, lastChunkNum=0;
    MEMBUF_CHUNK chunk;

    loadMemBufHeaderCache(hdrChunkNum);

    // Already big enough for needed size?
    if (size < cachedMemBufHdr.capacity) {
        return;
    }

    cachedMemBufHdr.posGlobal = cachedMemBufHdr.posChunk = 0;
    cachedMemBufHdr.capacity = 0;
    cachedMemBufHdr.used = size;

    chunkNum = cachedMemBufHdr.firstChunkNum;

    while (cachedMemBufHdr.capacity < cachedMemBufHdr.used) {
        if (!chunkNum) {
            allocChunk(&chunkNum);
            memset(&chunk, 0, sizeof(MEMBUF_CHUNK));
            storeChunk(chunkNum, &chunk);
            if (!lastChunkNum) {
                cachedMemBufHdr.firstChunkNum = chunkNum;
            } else {
                retrieveChunk(lastChunkNum, &chunk);
                chunk.nextChunk = chunkNum;
                storeChunk(lastChunkNum, &chunk);
            }
        }

        retrieveChunk(chunkNum, &chunk);
        cachedMemBufHdr.capacity += MEMBUF_CHUNK_LEN;

        lastChunkNum = chunkNum;
        chunkNum = chunk.nextChunk;
    }
}

void setMemBufPos(CHUNKNUM hdrChunkNum, unsigned position)
{
    CHUNKNUM chunkNum;
    unsigned remaining = position;

    flushMemBufCache();

    loadMemBufHeaderCache(hdrChunkNum);
    cachedMemBufHdr.posGlobal = cachedMemBufHdr.posChunk = 0;

    if (cachedMemBufHdr.firstChunkNum) {
        loadMemBufDataCache(cachedMemBufHdr.firstChunkNum);
        cachedMemBufHdr.currentChunkNum = cachedMemBufHdr.firstChunkNum;
    }

    if (!position) {
        return;
    }

    chunkNum = cachedMemBufHdr.firstChunkNum;
    while (remaining) {
        loadMemBufDataCache(chunkNum);
        if (remaining < MEMBUF_CHUNK_LEN) {
            cachedMemBufHdr.posChunk = remaining;
            cachedMemBufHdr.posGlobal += remaining;
            break;
        }

        chunkNum = cachedMemBufData.nextChunk;
        remaining -= MEMBUF_CHUNK_LEN;
        cachedMemBufHdr.posGlobal += MEMBUF_CHUNK_LEN;
    }
}

void freeMemBuf(CHUNKNUM hdrChunkNum)
{
    CHUNKNUM chunkNum;

    flushMemBufCache();

    retrieveChunk(hdrChunkNum, &cachedMemBufHdr);
    chunkNum = cachedMemBufHdr.firstChunkNum;
    while (chunkNum) {
        if (!retrieveChunk(chunkNum, &cachedMemBufData)) {
            break;
        }
        freeChunk(chunkNum);
        chunkNum = cachedMemBufData.nextChunk;
    }

    freeChunk(hdrChunkNum);
}

void readFromMemBuf(CHUNKNUM hdrChunkNum, void *buffer, unsigned length)
{
    unsigned toCopy;
    unsigned char *pBuffer = buffer;

    loadMemBufHeaderCache(hdrChunkNum);

    if (!cachedMemBufHdr.currentChunkNum) {
        if (!cachedMemBufHdr.firstChunkNum) {
            return;
        }
        cachedMemBufHdr.currentChunkNum = cachedMemBufHdr.firstChunkNum;
        cachedMemBufHdr.posGlobal = cachedMemBufHdr.posChunk = 0;
    }

    while (length) {
        loadMemBufDataCache(cachedMemBufHdr.currentChunkNum);
        if (length > MEMBUF_CHUNK_LEN - cachedMemBufHdr.posChunk) {
            toCopy = MEMBUF_CHUNK_LEN - cachedMemBufHdr.posChunk;
        } else {
            toCopy = length;
        }

        if (toCopy) {
            memcpy(pBuffer,
                cachedMemBufData.data+cachedMemBufHdr.posChunk,
                toCopy);
        }

        cachedMemBufHdr.posChunk += toCopy;
        cachedMemBufHdr.posGlobal += toCopy;
        pBuffer += toCopy;
        length -= toCopy;

        if (length) {
            if (!cachedMemBufData.nextChunk) {
                return;
            }
            cachedMemBufHdr.currentChunkNum = cachedMemBufData.nextChunk;
            cachedMemBufHdr.posChunk = 0;
        }
    }
}

void writeToMemBuf(CHUNKNUM hdrChunkNum, void *buffer, unsigned length)
{
    unsigned toCopy;
    unsigned char *pBuffer = buffer;

    loadMemBufHeaderCache(hdrChunkNum);

    if (!cachedMemBufHdr.firstChunkNum) {
        initMemBufChunk(hdrChunkNum);
    } else if (!cachedMemBufHdr.currentChunkNum) {
        cachedMemBufHdr.currentChunkNum = cachedMemBufHdr.firstChunkNum;
        cachedMemBufHdr.posChunk = 0;
        cachedMemBufHdr.posGlobal = 0;
    }

    while (length) {
        loadMemBufDataCache(cachedMemBufHdr.currentChunkNum);

        if (length > MEMBUF_CHUNK_LEN - cachedMemBufHdr.posChunk) {
            toCopy = MEMBUF_CHUNK_LEN - cachedMemBufHdr.posChunk;
        } else {
            toCopy = length;
        }

        if (toCopy) {
            memcpy(cachedMemBufData.data+cachedMemBufHdr.posChunk,
                pBuffer,
                toCopy);
            cachedMemBufHdr.posChunk += toCopy;
            cachedMemBufHdr.posGlobal += toCopy;
            pBuffer += toCopy;
            length -= toCopy;
        }

        if (length) {
            if (cachedMemBufData.nextChunk) {
                cachedMemBufHdr.currentChunkNum = cachedMemBufData.nextChunk;
            } else {
                initMemBufChunk(hdrChunkNum);
            }
            cachedMemBufHdr.posChunk = 0;
        }
    }

    if (cachedMemBufHdr.posGlobal > cachedMemBufHdr.used) {
        cachedMemBufHdr.used = cachedMemBufHdr.posGlobal;
    }
}
