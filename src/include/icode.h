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

typedef struct {
    CHUNKNUM firstChunkNum;
    CHUNKNUM currentChunkNum;
    unsigned posGlobal;
    unsigned posChunk;
    ICODE_CHUNK chunk;
    SYMTABNODE symtabNode;
    TOKEN token;
} ICODE;

void checkIcodeBounds(ICODE *Icode, int size);
void freeIcode(ICODE *Icode);
unsigned getCurrentIcodeLocation(ICODE *Icode);
TOKEN *getNextTokenFromIcode(ICODE *Icode);
void gotoIcodePosition(ICODE *Icode, unsigned position);
void insertLineMarker(ICODE *Icode);
ICODE *makeIcode(void);
ICODE *makeIcodeFrom(ICODE *Icode);
void putSymtabNodeToIcode(ICODE *Icode, SYMTABNODE *pNode);
void putTokenToIcode(ICODE *Icode, TTokenCode tc);
void resetIcodePosition(ICODE *Icode);

#endif // end of ICODE_H
