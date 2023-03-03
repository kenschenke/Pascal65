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
    TTYPE arrayType, *elmtType;
    int indexFlag;  // non-zero if another array index, 0 if done.
    CHUNKNUM newTypeChunkNum, typeChunkNum, finalTypeChunkNum, arrayTypeChunkNum;
    
    arrayTypeChunkNum = makeType(fcArray, 0, 0);
    retrieveChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
    elmtType = &arrayType;
    typeChunkNum = arrayTypeChunkNum;

    // [
    getToken();
    condGetToken(tcLBracket, errMissingLeftBracket);

    // Loop to parse each type spec in the index type list, separated by commas.
    do {
        parseIndexType(elmtType);
        storeChunk(typeChunkNum, (unsigned char *)elmtType);

        // ,
        resync(tlIndexFollow, tlIndexStart, NULL);
        if (tokenCode == tcComma || tokenIn(tokenCode, tlIndexStart)) {
            // For each type spec after the first, create an element type object
            newTypeChunkNum = makeType(fcArray, 0, 0);
            setType(&elmtType->array.elemType, newTypeChunkNum);
            storeChunk(typeChunkNum, (unsigned char *)elmtType);
            typeChunkNum = newTypeChunkNum;
            retrieveChunk(typeChunkNum, (unsigned char *)elmtType);
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
    setType(&elmtType->array.elemType, finalTypeChunkNum);
    storeChunk(typeChunkNum, (unsigned char *)elmtType);

    retrieveChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
    // Total byte size of the array
    if (arrayType.form != fcNone) {
        arrayType.size = arraySize(&arrayType);
        storeChunk(arrayTypeChunkNum, (unsigned char *)&arrayType);
    }

    return arrayTypeChunkNum;
}

void parseIndexType(TTYPE *pArrayType) {
    TTYPE indexType;
    CHUNKNUM indexTypeChunkNum;

    if (tokenIn(tokenCode, tlIndexStart)) {
        indexTypeChunkNum = parseTypeSpec();
        setType(&pArrayType->array.indexType, indexTypeChunkNum);
        retrieveChunk(indexTypeChunkNum, (unsigned char *)&indexType);

        switch (indexType.form) {
            // subrange index type
            case fcSubrange:
                pArrayType->array.elemCount =
                    indexType.subrange.max -
                    indexType.subrange.min + 1;
                pArrayType->array.minIndex = indexType.subrange.min;
                pArrayType->array.maxIndex = indexType.subrange.max;
                return;
            
            // enumeration index type
            case fcEnum:
                pArrayType->array.elemCount = indexType.enumeration.max + 1;
                pArrayType->array.minIndex = 0;
                pArrayType->array.maxIndex = indexType.enumeration.max;
                return;
        }
    }

    // Error
    setType(&pArrayType->array.indexType, dummyType);
    pArrayType->array.elemCount = 0;
    pArrayType->array.minIndex = pArrayType->array.maxIndex = 0;
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

