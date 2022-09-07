#ifndef TYPES_H
#define TYPES_H

#include <chunks.h>
#include <symtab.h>
#include <error.h>

typedef enum {
    fcNone, fcScalar, fcEnum, fcSubrange, fcArray, fcRecord,
} TFormCode;

extern CHUNKNUM integerType, booleanType, charType, dummyType;

void checkAssignmentCompatible(CHUNKNUM targetChunk, CHUNKNUM valueChunk, TErrorCode ec);
void checkBoolean(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk);
void checkRelOpOperands(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk);
char initPredefinedTypes(SYMTAB *symtab);
char integerOperands(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk);
CHUNKNUM makeType(TFormCode fc, int s, CHUNKNUM formId);
CHUNKNUM makeStringType(int length);
char setType(CHUNKNUM *targetType, CHUNKNUM sourceType);
void removeType(CHUNKNUM typeChunk);

typedef struct {
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

    char unused[CHUNK_LEN - 16];

} TTYPE;

#endif // end of TYPES_H
