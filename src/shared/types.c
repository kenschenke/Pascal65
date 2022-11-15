#include <symtab.h>
#include <types.h>
#include <error.h>
#include <stdio.h>

CHUNKNUM booleanType;
CHUNKNUM charType;
CHUNKNUM dummyType;
CHUNKNUM integerType;

static char getType(CHUNKNUM chunkNum, TTYPE *pType);

void checkAssignmentCompatible(CHUNKNUM targetTypeId, CHUNKNUM valueTypeId, TErrorCode ec) {
    TTYPE targetType, valueType;
#if 0
    extern int currentLineNumber;
#endif

#if 0
    getType(targetTypeId, &targetType);
    getType(valueTypeId, &valueType);
#else
    retrieveChunk(targetTypeId, (unsigned char *)&targetType);
    retrieveChunk(valueTypeId, (unsigned char *)&valueType);
#endif

    if (targetType.form == fcSubrange) {
        targetTypeId = targetType.subrange.baseType;
    }
    if (valueType.form == fcSubrange) {
        valueTypeId = valueType.subrange.baseType;
    }

#if 0
    if (currentLineNumber == 49) {
        printf("targetType! = %04X\n", targetTypeId);
    }
#endif

    if (targetTypeId == valueTypeId) {
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

void checkRelOpOperands(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk) {
    TTYPE type1, type2;

    if (getType(type1Chunk, &type1) == 0 ||
        getType(type2Chunk, &type2) == 0) {
        Error(errIncompatibleTypes);
    }

    // Two identical scalar or enumeration types.
    if (type1Chunk == type2Chunk && (type1.form == fcScalar || type1.form == fcEnum)) {
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

static char getType(CHUNKNUM chunkNum, TTYPE *pType) {
    if (retrieveChunk(chunkNum, (unsigned char *)pType) == 0) {
        return 0;
    }

    if (pType->form == fcSubrange) {
        if (retrieveChunk(pType->subrange.baseType, (unsigned char *)pType) == 0) {
            return 0;
        }
    }

    return 1;
}

char initPredefinedTypes(CHUNKNUM symtabChunkNum) {
    TTYPE typeNode;
    SYMBNODE node;
    CHUNKNUM integerId, booleanId, charId;
    CHUNKNUM falseId, trueId;

    // Enter the names of the predefined types and of "false"
    // and "true" into the symbol table.

    enterSymtab(symtabChunkNum, &node, "integer", dcType);
    integerId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "boolean", dcType);
    booleanId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "char", dcType);
    charId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "false", dcConstant);
    falseId = node.node.nodeChunkNum;

    enterSymtab(symtabChunkNum, &node, "true", dcConstant);
    trueId = node.node.nodeChunkNum;

    // Create the predefined type objects

    integerType = makeType(fcScalar, sizeof(int), integerId);
    booleanType = makeType(fcEnum, sizeof(int), booleanId);
    charType = makeType(fcScalar, sizeof(char), charId);
    dummyType = makeType(fcNone, 1, 0);

    if (loadSymbNode(integerId, &node) == 0) {
        return 0;
    }
    setType(&node.node.typeChunk, integerType);
    if (storeChunk(integerId, (unsigned char *)&node.node) == 0) {
        return 0;
    }

    if (loadSymbNode(booleanId, &node) == 0) {
        return 0;
    }
    setType(&node.node.typeChunk, booleanType);
    if (storeChunk(booleanId, (unsigned char *)&node.node) == 0) {
        return 0;
    }

    if (loadSymbNode(charId, &node) == 0) {
        return 0;
    }
    setType(&node.node.typeChunk, charType);
    if (storeChunk(charId, (unsigned char *)&node.node) == 0) {
        return 0;
    }

    if (retrieveChunk(booleanType, (unsigned char *)&typeNode) == 0) {
        return 0;
    }
    typeNode.enumeration.max = 1;
    typeNode.enumeration.constIds = falseId;
    if (storeChunk(booleanType, (unsigned char *)&typeNode) == 0) {
        return 0;
    }

    // More initialization for the "false" and "true" id nodes.
    if (loadSymbNode(falseId, &node) == 0) {
        return 0;
    }
    node.node.nextNode = trueId;
    setType(&node.node.typeChunk, booleanType);
    if (storeChunk(falseId, (unsigned char *)&node.node) == 0) {
        return 0;
    }
    node.defn.constant.value.integer = 0;
    if (storeChunk(node.node.defnChunk, (unsigned char *)&node.defn) == 0) {
        return 0;
    }

    if (loadSymbNode(trueId, &node) == 0) {
        return 0;
    }
    setType(&node.node.typeChunk, booleanType);
    if (storeChunk(trueId, (unsigned char *)&node.node) == 0) {
        return 0;
    }
    node.defn.constant.value.integer = 1;
    if (storeChunk(node.node.defnChunk, (unsigned char *)&node.defn) == 0) {
        return 0;
    }

    // Initialize the dummy type object that will be used
    // for erroneous type definitions and for typeless objects.
    if (setType(&dummyType, makeType(fcNone, 1, 0)) == 0) {
        return 0;
    }

    return 1;
}

char integerOperands(CHUNKNUM type1Chunk, CHUNKNUM type2Chunk) {
    return type1Chunk == integerType && type2Chunk == integerType;
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
    CHUNKNUM chunkNum, subrangeChunkNum;
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

    if (allocChunk(&chunkNum) == 0) {
        abortTranslation(abortOutOfMemory);
    }
    if (storeChunk(chunkNum, (unsigned char *)&typeObj) == 0) {
        abortTranslation(abortOutOfMemory);
    }
    if (storeChunk(subrangeChunkNum, (unsigned char *)&subrange) == 0) {
        abortTranslation(abortOutOfMemory);
    }

    return chunkNum;
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

