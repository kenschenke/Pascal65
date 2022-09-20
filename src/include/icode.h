/**
 * icode.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for intermediate code
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef ICODE_H
#define ICODE_H

#include <stdio.h>
#include <scanner.h>
#include <symtab.h>
#include <misc.h>
#include <chunks.h>

extern const TTokenCode mcLineMarker;

#define ICODE_CHUNK_LEN (CHUNK_LEN - sizeof(CHUNKNUM))

typedef struct ICODE_CHUNK {
    CHUNKNUM nextChunk;
    unsigned char data[ICODE_CHUNK_LEN];
} ICODE_CHUNK;

#if sizeof(struct ICODE_CHUNK) != CHUNK_LEN
#error ICODE_CHUNK should be CHUNK_LEN bytes in size
#endif

typedef struct ICODE {
    CHUNKNUM firstChunkNum;
    CHUNKNUM currentChunkNum;
    unsigned posGlobal;
    unsigned posChunk;
    char unused[CHUNK_LEN - 8];
} ICODE;

#if sizeof(struct ICODE) != CHUNK_LEN
#error ICODE should be CHUNK_LEN bytes in size
#endif

void checkIcodeBounds(CHUNKNUM chunkNum, int size);
void flushIcodeCache(void);
void freeIcode(CHUNKNUM chunkNum);
unsigned getCurrentIcodeLocation(CHUNKNUM chunkNum);
void getNextTokenFromIcode(CHUNKNUM chunkNum, TOKEN *pToken, SYMTABNODE *pNode);
void gotoIcodePosition(CHUNKNUM chunkNum, unsigned position);
void initIcodeCache(void);
void insertLineMarker(CHUNKNUM chunkNum);
void makeIcode(CHUNKNUM *newChunkNum);
void putSymtabNodeToIcode(CHUNKNUM chunkNum, SYMTABNODE *pNode);
void putTokenToIcode(CHUNKNUM chunkNum, TTokenCode tc);
void resetIcodePosition(CHUNKNUM chunkNum);

#endif // end of ICODE_H
