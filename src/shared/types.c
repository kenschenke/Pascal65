#include <symtab.h>
#include <types.h>
#include <error.h>
#include <stdio.h>

CHUNKNUM booleanType;
CHUNKNUM charType;
CHUNKNUM dummyType;
CHUNKNUM integerType;
CHUNKNUM realType;

void checkAssignmentCompatible(CHUNKNUM targetTypeId, CHUNKNUM valueTypeId, TErrorCode ec) {
    TTYPE targetType, valueType;
    CHUNKNUM baseTargetType, baseValueType;

    retrieveChunk(targetTypeId, (unsigned char *)&targetType);
    retrieveChunk(valueTypeId, (unsigned char *)&valueType);

    baseTargetType = getBaseType(&targetType);
    baseValueType = getBaseType(&valueType);

    // Two identical types
    if (baseTargetType == baseValueType) {
        return;
    }

    // real := integer
    if (baseTargetType == realType && baseValueType == integerType) {
        return;
    }

    // Two strings of the same length

    if (targetType.form == fcArray &&
        valueType.form == fcArray &&
        targetType.array.elemType == charType &&
        valueType.array.elemType == charType &&
        targetType.array.elemCount == valueType.array.elemCount) {
        return;
    }

    Error(ec);
}

void checkBoolean(CHUNKNUM type1ChunkNum, CHUNKNUM type2ChunkNum) {
    if (type1ChunkNum != booleanType) {
        Error(errIncompatibleTypes);
    }

    if (type2ChunkNum && type2ChunkNum != booleanType) {
        Error(errIncompatibleTypes);
    }
}

void checkIntegerOrReal(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk) {
    TTYPE type;
    CHUNKNUM baseType;

    getChunkCopy(type1Chunk, &type);
    baseType = getBaseType(&type);
    if (baseType != integerType && baseType != realType) {
        Error(errIncompatibleTypes);
    }

    if (type2Chunk) {
        getChunkCopy(type2Chunk, &type);
        baseType = getBaseType(&type);
        if (baseType != integerType && baseType != realType) {
            Error(errIncompatibleTypes);
        }
    }
}

void checkRelOpOperands(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk) {
    TTYPE type1, type2;

    getChunkCopy(type1Chunk, &type1);
    getChunkCopy(type2Chunk, &type2);

    // Two identical scalar or enumeration types.
    if (type1Chunk == type2Chunk && (type1.form == fcScalar || type1.form == fcEnum)) {
        return;
    }

    // One integer operand and one real operand.
    if ((type1Chunk == integerType && type2Chunk == realType) ||
        (type2Chunk == integerType && type1Chunk == realType)) {
        return;
    }

    // Two strings of the same length
    if (type1.form == fcArray &&
        type2.form == fcArray &&
        type1.array.elemType == charType &&
        type2.array.elemType == charType &&
        type1.array.elemCount == type2.array.elemCount) {
        return;
    }

    // Incompatible types
    Error(errIncompatibleTypes);
}

CHUNKNUM getBaseType(TTYPE *pType) {
    return pType->form == fcSubrange ? pType->subrange.baseType : pType->nodeChunkNum;
}

char integerOperands(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk) {
    TTYPE type1, type2;

    retrieveChunk(type1Chunk, (unsigned char *)&type1);
    retrieveChunk(type2Chunk, (unsigned char *)&type2);
    return getBaseType(&type1) == integerType && getBaseType(&type2) == integerType;
}

char realOperands(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk) {
    TTYPE type1, type2;
    CHUNKNUM baseType1, baseType2;

    retrieveChunk(type1Chunk, (unsigned char *)&type1);
    retrieveChunk(type2Chunk, (unsigned char *)&type2);

    baseType1 = getBaseType(&type1);
    baseType2 = getBaseType(&type2);

    return (baseType1 == realType && baseType2 == realType)
        ||  (baseType1 == realType && baseType2 == integerType)
        ||  (baseType2 == realType && baseType1 == integerType);
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

CHUNKNUM makeStringType(int length) {
    CHUNKNUM subrangeChunkNum;
    TTYPE typeObj, subrange;

    typeObj.form = fcArray;
    typeObj.size = length;
    typeObj.typeId = 0;

    subrangeChunkNum = makeType(fcSubrange, sizeof(int), 0);
    retrieveChunk(subrangeChunkNum, (unsigned char *)&subrange);

    typeObj.array.indexType = typeObj.array.elemType = 0;
    setType(&typeObj.array.indexType, subrangeChunkNum);
    setType(&typeObj.array.elemType, charType);
    typeObj.array.elemCount = length;

    // integer subrange index type, range 1..length
    setType(&subrange.subrange.baseType, integerType);
    subrange.subrange.min = 1;
    subrange.subrange.max = length;

    if (allocChunk(&typeObj.nodeChunkNum) == 0) {
        abortTranslation(abortOutOfMemory);
    }
    if (storeChunk(typeObj.nodeChunkNum, (unsigned char *)&typeObj) == 0) {
        abortTranslation(abortOutOfMemory);
    }
    if (storeChunk(subrangeChunkNum, (unsigned char *)&subrange) == 0) {
        abortTranslation(abortOutOfMemory);
    }

    return typeObj.nodeChunkNum;
}

char setType(CHUNKNUM *targetType, CHUNKNUM sourceType) {
#if 0
    TTYPE typeNode;

    if (targetType) {
        removeType(*targetType);
    }

    if (retrieveChunk(sourceType, (unsigned char *)&typeNode) == 0) {
        return 0;
    }

    // typeNode.typeId = sourceType;
    ++typeNode.refCount;
    if (storeChunk(sourceType, (unsigned char *)&typeNode) == 0) {
        return 0;
    }
#endif
    *targetType = sourceType;

    return 1;
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

