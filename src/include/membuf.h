/**
 * membuf.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for memory buffers
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef MEMBUF_H
#define MEMBUF_H

#include <chunks.h>

// Routines to manage dynamic in-memory buffers

#define MEMBUF_CHUNK_LEN (CHUNK_LEN - sizeof(CHUNKNUM))

typedef struct MEMBUF_CHUNK {
    CHUNKNUM nextChunk;
    unsigned char data[MEMBUF_CHUNK_LEN];
} MEMBUF_CHUNK;

_Static_assert (sizeof(struct MEMBUF_CHUNK) == CHUNK_LEN, "MEMBUF_CHUNK should be CHUNK_LEN bytes in size");

typedef struct MEMBUF {
    CHUNKNUM firstChunkNum;
    CHUNKNUM currentChunkNum;
    unsigned short posGlobal;
    unsigned short posChunk;
    unsigned short capacity;          // storage capacity of allocated chunks
    unsigned short used;              // total bytes stored in buffer
    char unused[CHUNK_LEN - 12];
} MEMBUF;

typedef struct MEMBUF_LOCN {
    CHUNKNUM chunkNum;
    unsigned posGlobal;
    unsigned posChunk;
} MEMBUF_LOCN;

_Static_assert (sizeof(struct MEMBUF) == CHUNK_LEN, "MEMBUF should be CHUNK_LEN bytes in size");

void allocMemBuf(CHUNKNUM *newHeader);
void flushMemCache(void);
void reserveMemBuf(CHUNKNUM header, unsigned size);
unsigned getMemBufPos(CHUNKNUM header);     // returns global position
void initMemBufCache(void);
char isMemBufAtEnd(CHUNKNUM header);
void setMemBufPos(CHUNKNUM header, unsigned position);
void freeMemBuf(CHUNKNUM header);
void copyFromMemBuf(CHUNKNUM header, void *buffer, unsigned offset, unsigned length);
void copyToMemBuf(CHUNKNUM header, void *buffer, unsigned offset, unsigned length);
void readFromMemBuf(CHUNKNUM header, void *buffer, unsigned length);
void writeToMemBuf(CHUNKNUM header, void *buffer, unsigned length);

#endif // end of MEMBUF_H
