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

typedef struct STRVALCHUNK {
    CHUNKNUM nextChunkNum;
    char value[CHUNK_LEN - 2];
} STRVALCHUNK;

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
    rcAbs, rcArctan, rcChr, rcCos, rcEof, rcEoln,
    rcExp, rcLn, rcOdd, rcOrd, rcPred, rcRound,
    rcSin, rcSqr, rcSqrt, rcSucc, rcTrunc,
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

typedef struct {
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
            CHUNKNUM     Icode;             // chunknum of routine's icode
        } routine;

        // Variable, record field, or parameter
        struct {
            int offset;     // vars and params: sequence count
                            // fields: byte offset in record
        } data;
    };

    char unused;  // pad to 23 bytes
} DEFN;

typedef struct SYMTABNODE {
    CHUNKNUM nodeChunkNum;
    CHUNKNUM leftChunkNum, rightChunkNum;
    CHUNKNUM nameChunkNum;

    CHUNKNUM nextNode;   // next sibling node in chain
    CHUNKNUM defnChunk;  // definition info
    CHUNKNUM typeChunk;  // type info
    int level;   // nesting level
    int labelIndex;  // index for code label

    char unused[CHUNK_LEN - 16];
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

void freeDefn(DEFN *pDefn);

char enterNew(SYMTAB *symtab, SYMTABNODE *pNode, const char *identifier, TDefnCode dc);
char enterSymtab(SYMTAB *symtab, SYMTABNODE *pNode, const char *identifier, TDefnCode dc);
char searchSymtab(SYMTAB *symtab, SYMTABNODE *pNode, const char *identifier);

#endif // end of SYMTAB_H
