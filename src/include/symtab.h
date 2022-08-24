/**
 * symtab.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for symbol table
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef SYMTAB_H
#define SYMTAB_H

#include <chunks.h>

typedef struct STRVALCHUNK {
    CHUNKNUM nextChunkNum;
    char value[CHUNK_LEN - 2];
} STRVALCHUNK;

enum TSymtabValue {
    valInteger,
    valString,
    valLong,
};

typedef struct SYMTABNODE {
    CHUNKNUM nodeChunkNum;
    CHUNKNUM leftChunkNum, rightChunkNum;
    CHUNKNUM nameChunkNum;
    short xSymtab;
    short xNode;
    char valueType;  // TSymtabValue
    // Value:
    //    Int: first two bytes are value, last two bytes ignored
    //    String: first two bytes are strlen, last two bytes are chunkNum of value
    //    Long: All four bytes are 32-bit integer
    unsigned char value[4];
    char unused[CHUNK_LEN - 17];
} SYMTABNODE;

typedef struct SYMTAB {
    CHUNKNUM symtabChunkNum;
    CHUNKNUM rootChunkNum;      // binary tree used at parse time
    short cntNodes;
    short xSymtab;
    CHUNKNUM nextSymtabChunk;
    char unused[CHUNK_LEN - 10];
} SYMTAB;

void freeSymtab(CHUNKNUM symtabChunkNum);
char makeSymtab(SYMTAB *pSymtab);

char enterSymtab(SYMTAB *symtab, SYMTABNODE *pNode, const char *identifier);
int getSymtabInt(SYMTABNODE *pNode);
char searchSymtab(SYMTAB *symtab, SYMTABNODE *pNode, const char *identifier);
char setSymtabInt(SYMTABNODE *pNode, int value);
char setSymtabString(SYMTABNODE *pNode, const char *value);

#endif // end of SYMTAB_H
