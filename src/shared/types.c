#include <symtab.h>
#include <types.h>
#include <error.h>
#include <stdio.h>

CHUNKNUM booleanType;
CHUNKNUM charType;
CHUNKNUM dummyType;
CHUNKNUM integerType;
CHUNKNUM realType;

void checkBoolean(CHUNKNUM type1ChunkNum, CHUNKNUM type2ChunkNum) {
    if (type1ChunkNum != booleanType) {
        Error(errIncompatibleTypes);
    }

    if (type2ChunkNum && type2ChunkNum != booleanType) {
        Error(errIncompatibleTypes);
    }
}

char isTypeScalar(TTYPE *pType) {
    return pType->form != fcArray && pType->form != fcRecord ? 1 : 0;
}

CHUNKNUM makeType(TFormCode fc, int s, CHUNKNUM formId) {
    CHUNKNUM chunkNum;
    TTYPE typeObj;

    typeObj.form = fc;
    typeObj.size = s;
    typeObj.typeId = formId;

    switch (fc) {
        case fcSubrange:
            typeObj.subrange.baseType = 0;
            break;
        
        case fcArray:
            typeObj.array.indexType = typeObj.array.elemType = 0;
            break;

        default:
            break;
    }

    if (allocChunk(&chunkNum) == 0) {
        abortTranslation(abortOutOfMemory);
    }
    typeObj.nodeChunkNum = chunkNum;
    if (storeChunk(chunkNum, (unsigned char *)&typeObj) == 0) {
        abortTranslation(abortOutOfMemory);
    }

    return chunkNum;
}

void removeType(CHUNKNUM typeChunk) {
    TTYPE typeNode;

    if (retrieveChunk(typeChunk, (unsigned char *)&typeNode) == 0) {
        return;
    }

    if (--typeNode.refCount == 0) {
        freeChunk(typeChunk);
    } else {
        storeChunk(typeChunk, (unsigned char *)&typeNode);
    }
}

