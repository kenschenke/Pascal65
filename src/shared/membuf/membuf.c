#include <membuf.h>

#if 0
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#endif

MEMBUF cachedMemBufHdr;
CHUNKNUM cachedMemBufHdrChunkNum;

MEMBUF_CHUNK cachedMemBufData;
CHUNKNUM cachedMemBufDataChunkNum;

#if 0
static CHUNKNUM initNewChunk(MEMBUF *pMemBufHdr, MEMBUF_CHUNK *pMemBufData);

static CHUNKNUM initNewChunk(MEMBUF *pMemBufHdr, MEMBUF_CHUNK *pMemBufData)
{
    CHUNKNUM chunkNum;

    allocChunk(&chunkNum);

    if (!pMemBufHdr->firstChunkNum) {
        pMemBufHdr->firstChunkNum = chunkNum;
    } else if (pMemBufHdr->currentChunkNum) {
        retrieveChunk(pMemBufHdr->currentChunkNum, pMemBufData);
        pMemBufData->nextChunk = chunkNum;
        storeChunk(pMemBufHdr->currentChunkNum, pMemBufData);
    }

    memset(pMemBufData, 0, sizeof(MEMBUF_CHUNK));
    // pMemBufData->nextChunk = chunkNum;
    storeChunk(chunkNum, pMemBufData);
    pMemBufHdr->currentChunkNum = chunkNum;
    pMemBufHdr->posChunk = 0;
    pMemBufHdr->capacity += MEMBUF_CHUNK_LEN;

    return chunkNum;
}
#endif

#if 0
static void loadMemBufDataCache(CHUNKNUM chunkNum);
static void loadMemBufHeaderCache(CHUNKNUM header);

static void loadMemBufDataCache(CHUNKNUM chunkNum)
{
    if (cachedMemBufDataChunkNum == chunkNum) {
        return;  // nothing to do
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
    }

    cachedMemBufDataChunkNum = chunkNum;
    retrieveChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
}

static void loadMemBufHeaderCache(CHUNKNUM header)
{
    if (cachedMemBufHdrChunkNum == header) {
        return;  // nothing to do
    }

    if (cachedMemBufHdrChunkNum) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
    }

    cachedMemBufHdrChunkNum = header;
    retrieveChunk(header, &cachedMemBufHdr);
}
#endif

#if 0
void allocMemBuf(CHUNKNUM *header)
{
    MEMBUF memBufHdr;

    if (cachedMemBufHdrChunkNum) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
        cachedMemBufHdrChunkNum = 0;
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
        cachedMemBufDataChunkNum = 0;
    }

    allocChunk(header);
    memset(&memBufHdr, 0, sizeof(MEMBUF));
    storeChunk(*header, &memBufHdr);
}
#endif

#if 0
void freeMemBuf(CHUNKNUM header)
{
    CHUNKNUM chunkNum;
    MEMBUF memBufHdr;
    MEMBUF_CHUNK memBufData;

    if (cachedMemBufHdrChunkNum) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
        cachedMemBufHdrChunkNum = 0;
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
        cachedMemBufDataChunkNum = 0;
    }

    retrieveChunk(header, &memBufHdr);

    chunkNum = memBufHdr.firstChunkNum;
    while (chunkNum) {
        retrieveChunk(chunkNum, &memBufData);
        freeChunk(chunkNum);
        chunkNum = memBufData.nextChunk;
    }

    freeChunk(header);
}
#endif

#if 0
unsigned getMemBufPos(CHUNKNUM header)
{
    MEMBUF memBufHdr;

    if (cachedMemBufHdrChunkNum) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
        cachedMemBufHdrChunkNum = 0;
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
        cachedMemBufDataChunkNum = 0;
    }

    retrieveChunk(header, &memBufHdr);
    return memBufHdr.posGlobal;
}
#endif

#if 0
char isMemBufAtEnd(CHUNKNUM header)
{
    MEMBUF memBufHdr;

    if (cachedMemBufHdrChunkNum) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
        cachedMemBufHdrChunkNum = 0;
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
        cachedMemBufDataChunkNum = 0;
    }

    retrieveChunk(header, &memBufHdr);
    return memBufHdr.posGlobal >= memBufHdr.used ? 1 : 0;
}
#endif

#if 0
void readFromMemBuf(CHUNKNUM header, void *buffer, unsigned length)
{
    MEMBUF memBufHdr;
    MEMBUF_CHUNK memBufData;
    unsigned toCopy;
    unsigned char *p = buffer;

    if (cachedMemBufHdrChunkNum) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
        cachedMemBufHdrChunkNum = 0;
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
        cachedMemBufDataChunkNum = 0;
    }

    retrieveChunk(header, &memBufHdr);
    if (memBufHdr.currentChunkNum) {
#if 1
        if (!isChunkAllocated(memBufHdr.currentChunkNum)) {
            printf("cur not alloc %04X hdr %04x\n", memBufHdr.currentChunkNum, header);
            exit(0);
        }
#endif
        retrieveChunk(memBufHdr.currentChunkNum, &memBufData);
    } else if (memBufHdr.firstChunkNum == 0) {
        return;
    } else {
        memBufHdr.currentChunkNum = memBufHdr.firstChunkNum;
        memBufHdr.posChunk = 0;
        memBufHdr.posGlobal = 0;
        retrieveChunk(memBufHdr.currentChunkNum, &memBufData);
    }

    while (length) {
        if (length > MEMBUF_CHUNK_LEN - memBufHdr.posChunk) {
            toCopy = MEMBUF_CHUNK_LEN - memBufHdr.posChunk;
        } else {
            toCopy = length;
        }

        memcpy(p, memBufData.data + memBufHdr.posChunk, toCopy);
        length -= toCopy;
        p += toCopy;
        memBufHdr.posChunk += toCopy;
        memBufHdr.posGlobal += toCopy;

        if (length) {
            if (!memBufData.nextChunk) {
                break;
            }
            memBufHdr.currentChunkNum = memBufData.nextChunk;
            memBufHdr.posChunk = 0;
            retrieveChunk(memBufHdr.currentChunkNum, &memBufData);
        }
    }

    storeChunk(header, &memBufHdr);
}
#endif

#if 0
void setMemBufPos(CHUNKNUM header, unsigned position)
{
    unsigned pos = position;
    MEMBUF memBufHdr;
    MEMBUF_CHUNK memBufData;
    
    if (cachedMemBufHdrChunkNum) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
        cachedMemBufHdrChunkNum = 0;
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
        cachedMemBufDataChunkNum = 0;
    }

    retrieveChunk(header, &memBufHdr);

    memBufHdr.posGlobal = 0;
    memBufHdr.posChunk = 0;
    memBufHdr.currentChunkNum = memBufHdr.firstChunkNum;

    while (pos) {
#if 1
        if (!isChunkAllocated(memBufHdr.currentChunkNum)) {
            printf("Cannot position %u\n", position);
            exit(0);
        }
#endif

        retrieveChunk(memBufHdr.currentChunkNum, &memBufData);
        if (pos < MEMBUF_CHUNK_LEN) {
            memBufHdr.posGlobal += pos;
            memBufHdr.posChunk = pos;
            break;
        }

        memBufHdr.posGlobal += MEMBUF_CHUNK_LEN;
        pos -= MEMBUF_CHUNK_LEN;
        memBufHdr.currentChunkNum = memBufData.nextChunk;
    }

    storeChunk(header, &memBufHdr);
}
#endif

#if 0
void writeToMemBuf(CHUNKNUM header, void *data, unsigned length)
{
    unsigned toCopy;
    unsigned char *p = data;
    MEMBUF memBufHdr;
    MEMBUF_CHUNK memBufData;

    if (cachedMemBufHdrChunkNum) {
        storeChunk(cachedMemBufHdrChunkNum, &cachedMemBufHdr);
        cachedMemBufHdrChunkNum = 0;
    }

    if (cachedMemBufDataChunkNum) {
        storeChunk(cachedMemBufDataChunkNum, &cachedMemBufData);
        cachedMemBufDataChunkNum = 0;
    }

    retrieveChunk(header, &memBufHdr);

    if (!memBufHdr.firstChunkNum) {
        memBufHdr.firstChunkNum = initNewChunk(&memBufHdr, &memBufData);
        memBufHdr.posGlobal = 0;
    } else if (!memBufHdr.currentChunkNum) {
        memBufHdr.currentChunkNum = memBufHdr.firstChunkNum;
        memBufHdr.posChunk = memBufHdr.posGlobal = 0;
    }
    
    retrieveChunk(memBufHdr.currentChunkNum, &memBufData);

    while (length) {
        if (length > MEMBUF_CHUNK_LEN - memBufHdr.posChunk) {
            toCopy = MEMBUF_CHUNK_LEN - memBufHdr.posChunk;
        } else {
            toCopy = length;
        }

        memcpy(memBufData.data + memBufHdr.posChunk, p, toCopy);
        memBufHdr.posChunk += toCopy;
        memBufHdr.posGlobal += toCopy;
        p += toCopy;
        length -= toCopy;

        if (!length) {
            break;
        }

        if (!memBufData.nextChunk) {
            storeChunk(memBufHdr.currentChunkNum, &memBufData);
            initNewChunk(&memBufHdr, &memBufData);
        } else {
            storeChunk(memBufHdr.currentChunkNum, &memBufData);
            memBufHdr.currentChunkNum = memBufData.nextChunk;
            retrieveChunk(memBufHdr.currentChunkNum, &memBufData);
            memBufHdr.posChunk = 0;
        }
    }

    if (memBufHdr.posGlobal > memBufHdr.used) {
        memBufHdr.used = memBufHdr.posGlobal;
    }

    storeChunk(header, &memBufHdr);
    storeChunk(memBufHdr.currentChunkNum, &memBufData);
}
#endif
