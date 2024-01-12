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
#include <misc.h>

#define MAX_NESTING_LEVEL 8

struct ICODE;

extern CHUNKNUM symtabStack[MAX_NESTING_LEVEL];

typedef struct STRVALCHUNK {
    CHUNKNUM nextChunkNum;
    char value[CHUNK_LEN - 2];
} STRVALCHUNK;

_Static_assert (sizeof(struct STRVALCHUNK) == CHUNK_LEN, "STRVALCHUNK should be CHUNK_LEN bytes in size");

// How an identifier is defined

typedef enum {
    dcUndefined,
    dcConstant, dcType, dcVariable, dcField,
    dcValueParm, dcVarParm,
    dcProgram, dcProcedure, dcFunction,
} TDefnCode;

// For procedures, functions, and standard routines

typedef enum {
    rcDeclared, rcForward,
    rcRead, rcReadln, rcWrite, rcWriteln,
    rcAbs, rcEof, rcEoln, rcOrd,
    rcPred, rcRound, rcSqr, rcSucc, rcTrunc,
} TRoutineCode;

// Local identifier lists structure.

typedef struct {
    CHUNKNUM parmIds;
    CHUNKNUM constantIds;
    CHUNKNUM typeIds;
    CHUNKNUM variableIds;
    CHUNKNUM routineIds;
} LOCALIDS;

// Definition structure

typedef struct DEFN {
    TDefnCode how;  // the identifier was defined

    union {

        // Constant
        struct {
            TDataValue value;
        } constant;

        // Procedure, function, or standard routine
        struct {
            TRoutineCode which;             // routine code
            int          parmCount;         // count of parameters
            int          totalParmSize;     // total byte size of parms
            int          totalLocalSize;    // total byte size of locals
            LOCALIDS     locals;            // local identifiers
            CHUNKNUM     symtab;            // chunk number of local symtab
            CHUNKNUM     Icode;            // chunknum of routine's icode
        } routine;

        // Variable, record field, or parameter
        struct {
            int offset;     // vars and params: sequence count
                            // fields: byte offset in record
        } data;
    };

    char unused;  // pad to 23 bytes
} DEFN;

_Static_assert (sizeof(struct DEFN) == CHUNK_LEN, "DEFN should be CHUNK_LEN bytes in size");

typedef struct SYMTABNODE {
    CHUNKNUM nodeChunkNum;
    CHUNKNUM leftChunkNum, rightChunkNum;
    CHUNKNUM nameChunkNum;

    CHUNKNUM nextNode;   // next sibling node in chain
    CHUNKNUM defnChunk;  // definition info
    CHUNKNUM typeChunk;  // type info
    int level;   // nesting level
    int labelIndex;  // index for code label

    char unused[CHUNK_LEN - 18];
} SYMTABNODE;

typedef struct SYMBNODE {
    SYMTABNODE node;
    DEFN defn;
} SYMBNODE;

_Static_assert (sizeof(struct SYMTABNODE) == CHUNK_LEN, "SYMTABNODE should be CHUNK_LEN bytes in size");

typedef struct SYMTAB {
    CHUNKNUM symtabChunkNum;
    CHUNKNUM rootChunkNum;      // binary tree used at parse time
    short cntNodes;
    short xSymtab;
    CHUNKNUM nextSymtabChunk;
    char unused[CHUNK_LEN - 10];
} SYMTAB;

_Static_assert (sizeof(struct SYMTAB) == CHUNK_LEN, "SYMTAB should be CHUNK_LEN bytes in size");

void freeSymtab(CHUNKNUM symtabChunkNum);
char makeSymtab(CHUNKNUM *symtabChunkNum);

void freeDefn(DEFN *pDefn);

char enterNew(CHUNKNUM symtabChunkNum, SYMBNODE *pNode, const char *identifier, TDefnCode dc);
char enterSymtab(CHUNKNUM symtabChunkNum, SYMBNODE *pNode, const char *identifier, TDefnCode dc);
char searchSymtab(CHUNKNUM symtabChunkNum, SYMBNODE *pNode, const char *identifier);

char loadSymbNode(CHUNKNUM nodeChunk, SYMBNODE *pNode);
char saveSymbNode(SYMBNODE *pNode);
char saveSymbNodeDefn(SYMBNODE *pNode);
char saveSymbNodeOnly(SYMBNODE *pNode);

char symtabEnterLocal(SYMBNODE *pNode, const char *pString, TDefnCode dc);
char symtabEnterNewLocal(SYMBNODE *pNode, const char *pString, TDefnCode dc);
char symtabSearchLocal(SYMBNODE *pNode, const char *pString);
void symtabStackEnterScope(void);
void symtabExitScope(CHUNKNUM *symtabChunkNum);
void symtabStackFind(const char *pString, SYMBNODE *pNode);
char symtabStackSearchAll(const char *pString, SYMBNODE *pNode);

#endif // end of SYMTAB_H
