#include <common.h>
#include <parser.h>
#include <chunks.h>
#include <parscommon.h>
#include <symtab.h>
#include <types.h>
#include <string.h>

int arraySize(TTYPE *pArrayType) {
    TTYPE elemType;

    retrieveChunk(pArrayType->array.elemType, (unsigned char *)&elemType);

    // Calculate the size of the element type
    // if it hasn't already been calculated.
    if (elemType.size == 0) {
        elemType.size = arraySize(&elemType);
        storeChunk(pArrayType->array.elemType, (unsigned char *)&elemType);
    }

    return pArrayType->array.elemCount * elemType.size;
}

CHUNKNUM parseArrayType(void) {
    TTYPE arrayType;
    int indexFlag;  // non-zero if another array index, 0 if done.
    CHUNKNUM newTypeChunkNum, typeChunkNum, finalTypeChunkNum, arrayTypeChunkNum;
    
    arrayTypeChunkNum = makeType(fcArray, 0, 0);
    retrieveChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
    typeChunkNum = arrayTypeChunkNum;

    // [
    getToken();
    condGetToken(tcLBracket, errMissingLeftBracket);

    // Loop to parse each type spec in the index type list, separated by commas.
    do {
        parseIndexType(arrayType.nodeChunkNum);
        getChunkCopy(arrayType.nodeChunkNum, &arrayType);

        // ,
        resync(tlIndexFollow, tlIndexStart, NULL);
        if (tokenCode == tcComma || tokenIn(tokenCode, tlIndexStart)) {
            // For each type spec after the first, create an element type object
            newTypeChunkNum = makeType(fcArray, 0, 0);
            setType(&arrayType.array.elemType, newTypeChunkNum);
            storeChunk(typeChunkNum, (unsigned char *)&arrayType);
            typeChunkNum = newTypeChunkNum;
            retrieveChunk(typeChunkNum, (unsigned char *)&arrayType);
            condGetToken(tcComma, errMissingComma);
            indexFlag = 1;
        } else {
            indexFlag = 0;
        }
    } while (indexFlag);

    // ]
    condGetToken(tcRBracket, errMissingRightBracket);

    // OF
    resync(tlIndexListFollow, tlDeclarationStart, tlStatementStart);
    condGetToken(tcOF, errMissingOF);

    // Final element type
    finalTypeChunkNum = parseTypeSpec();
    setType(&arrayType.array.elemType, finalTypeChunkNum);
    storeChunk(typeChunkNum, (unsigned char *)&arrayType);

    retrieveChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
    // Total byte size of the array
    if (arrayType.form != fcNone) {
        arrayType.size = arraySize(&arrayType);
        storeChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
    }

    return arrayTypeChunkNum;
}

void parseIndexType(CHUNKNUM arrayTypeChunkNum) {
    TTYPE arrayType, indexType;
    CHUNKNUM indexTypeChunkNum;

    getChunkCopy(arrayTypeChunkNum, &arrayType);

    if (tokenIn(tokenCode, tlIndexStart)) {
        indexTypeChunkNum = parseTypeSpec();
        setType(&arrayType.array.indexType, indexTypeChunkNum);
        retrieveChunk(indexTypeChunkNum, (unsigned char *)&indexType);

        switch (indexType.form) {
            // subrange index type
            case fcSubrange:
                arrayType.array.elemCount =
                    indexType.subrange.max -
                    indexType.subrange.min + 1;
                arrayType.array.minIndex = indexType.subrange.min;
                arrayType.array.maxIndex = indexType.subrange.max;
                storeChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
                return;
            
            // enumeration index type
            case fcEnum:
                arrayType.array.elemCount = indexType.enumeration.max + 1;
                arrayType.array.minIndex = 0;
                arrayType.array.maxIndex = indexType.enumeration.max;
                storeChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
                return;
        }
    }

    // Error
    setType(&arrayType.array.indexType, dummyType);
    arrayType.array.elemCount = 0;
    arrayType.array.minIndex = arrayType.array.maxIndex = 0;
    storeChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
    Error(errInvalidIndexType);
}

CHUNKNUM parseRecordType(void) {
    CHUNKNUM newTypeChunkNum;
    TTYPE newType;

    newTypeChunkNum = makeType(fcRecord, 0, 0);
    retrieveChunk(newTypeChunkNum, (unsigned char *)&newType);
    makeSymtab(&newType.record.symtab);

    // Parse field declarations
    getToken();
    parseFieldDeclarations(&newType, 0);
    storeChunk(newTypeChunkNum, (unsigned char *)&newType);

    // END
    condGetToken(tcEND, errMissingEND);

    return newTypeChunkNum;
}

