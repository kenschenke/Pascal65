#ifndef MEMBUF_H
#define MEMBUF_H

#include <chunks.h>

// Routines to manage dynamic in-memory buffers

#define MEMBUF_CHUNK_LEN (CHUNK_LEN - sizeof(CHUNKNUM))

typedef struct MEMBUF_CHUNK {
    CHUNKNUM nextChunk;
    unsigned char data[MEMBUF_CHUNK_LEN];
} MEMBUF_CHUNK;

#if sizeof(struct MEMBUF_CHUNK) != CHUNK_LEN
#error MEMBUF_CHUNK should be CHUNK_LEN bytes in size
#endif

typedef struct MEMBUF {
    CHUNKNUM firstChunkNum;
    CHUNKNUM currentChunkNum;
    unsigned posGlobal;
    unsigned posChunk;
    unsigned capacity;          // storage capacity of allocated chunks
    unsigned used;              // total bytes stored in buffer
    char unused[CHUNK_LEN - 12];
} MEMBUF;

typedef struct MEMBUF_LOCN {
    CHUNKNUM chunkNum;
    unsigned posGlobal;
    unsigned posChunk;
} MEMBUF_LOCN;

#if sizeof(struct MEMBUF) != CHUNK_LEN
#error MEMBUF should be CHUNK_LEN bytes in size
#endif

void allocMemBuf(CHUNKNUM *newHeader);
void reserveMemBuf(CHUNKNUM header, unsigned size);
void getMemBufLocn(CHUNKNUM header, MEMBUF_LOCN *pMemBufLocn);
unsigned getMemBufPos(CHUNKNUM header);     // returns global position
void initMemBufCache(void);
void duplicateMemBuf(CHUNKNUM sourceHeader, CHUNKNUM *newHeader);
char isMemBufAtEnd(CHUNKNUM header);
void setMemBufLocn(CHUNKNUM header, MEMBUF_LOCN *pMemBufLocn);
void setMemBufPos(CHUNKNUM header, unsigned position);
void freeMemBuf(CHUNKNUM header);
void copyFromMemBuf(CHUNKNUM header, void *buffer, unsigned offset, unsigned length);
void copyToMemBuf(CHUNKNUM header, void *buffer, unsigned offset, unsigned length);
void resetMemBufPosition(CHUNKNUM header);
void readFromMemBuf(CHUNKNUM header, void *buffer, unsigned length);
void writeToMemBuf(CHUNKNUM header, void *buffer, unsigned length);

#endif // end of MEMBUF_H
