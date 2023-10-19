#ifndef TYPES_H
#define TYPES_H

#include <chunks.h>
#include <error.h>

typedef enum {
    fcNone, fcScalar, fcEnum, fcSubrange, fcArray, fcRecord,
} TFormCode;

extern CHUNKNUM integerType, realType, booleanType, charType, dummyType;

typedef struct TTYPE {
    CHUNKNUM nodeChunkNum;
    int refCount;

    TFormCode form;
    int size;
    CHUNKNUM typeId;

    union {
        // Enumeration
        struct {
            CHUNKNUM constIds;  // const id nodes
            int max;
        } enumeration;

        // Subrange
        struct {
            CHUNKNUM baseType;
            int min, max;
        } subrange;

        // Array
        struct {
            CHUNKNUM indexType;
            CHUNKNUM elemType;
            int minIndex, maxIndex;
            int elemCount;
        } array;

        // Record
        struct {
            CHUNKNUM symtab;  // record fields symtab
        } record;
    };

    char unused[CHUNK_LEN - 19];

} TTYPE;

_Static_assert (sizeof(struct TTYPE) == CHUNK_LEN, "TTYPE should be CHUNK_LEN bytes in size");

void checkBoolean(CHUNKNUM type1ChunkNum, CHUNKNUM type2ChunkNum);
char isTypeScalar(TTYPE *pType);
CHUNKNUM makeType(TFormCode fc, int s, CHUNKNUM formId);
void removeType(CHUNKNUM typeChunk);

#endif // end of TYPES_H
