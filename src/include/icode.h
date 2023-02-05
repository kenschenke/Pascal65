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
#include <membuf.h>

extern const TTokenCode mcLineMarker;
extern const TTokenCode mcLocationMarker;

void checkIcodeBounds(CHUNKNUM chunkNum, int size);
void fixupLocationMarker(CHUNKNUM headerChunkNum, MEMBUF_LOCN *pMemBufLocn);
void getCaseItem(CHUNKNUM headerChunkNum, int *value, MEMBUF_LOCN *pMemBufLocn);
void getLocationMarker(CHUNKNUM chunkNum, MEMBUF_LOCN *pMemBufLocn);
void getNextTokenFromIcode(CHUNKNUM chunkNum, TOKEN *pToken, SYMBNODE *pNode);
void insertLineMarker(CHUNKNUM chunkNum);
void putCaseItem(CHUNKNUM headerChunkNum, int value, MEMBUF_LOCN *pMemBufLocn);
void putLocationMarker(CHUNKNUM headerChunkNum, MEMBUF_LOCN *pMemBufLocn);
void putSymtabNodeToIcode(CHUNKNUM chunkNum, SYMBNODE *pNode);
void putTokenToIcode(CHUNKNUM chunkNum, TTokenCode tc);

#endif // end of ICODE_H
