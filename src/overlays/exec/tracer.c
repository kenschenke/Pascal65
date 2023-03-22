#include <stdio.h>
#include <string.h>
#include <common.h>
#include <buffer.h>
#include <exec.h>
#include <membuf.h>
#include <real.h>

#ifdef __TEST__

void traceRoutineEntry(SYMBNODE *pRoutineId) {
    if (executor.traceRoutineFlag) {
        char name[CHUNK_LEN];
        retrieveChunk(pRoutineId->node.nameChunkNum, (unsigned char *)name);
        printf(">> Entering routine %.*s\n", CHUNK_LEN, name);
    }
}

void traceRoutineExit(SYMBNODE *pRoutineId) {
    if (executor.traceRoutineFlag) {
        char name[CHUNK_LEN];
        retrieveChunk(pRoutineId->node.nameChunkNum, (unsigned char *)name);
        printf(">> Exiting routine %.*s\n", CHUNK_LEN, name);
    }
}

void traceStatement(void) {
    if (executor.traceStatementFlag) {
        char buf[3];
        printf(">> At Line %d %04x:%d\n", currentLineNumber, executor.Icode, getMemBufPos(executor.Icode));
        gets(buf);
    }
}

void traceDataStore(SYMBNODE *pTargetId, void *pDataValue, TTYPE *pDataType) {
    if (executor.traceStoreFlag) {
        TFormCode form = pTargetId->type.form;
        char name[CHUNK_LEN];

        retrieveChunk(pTargetId->node.nameChunkNum, (unsigned char *)name);

        printf(">>   %.*s", CHUNK_LEN, name);
        if (form == fcArray) printf("[*]");
        else if (form == fcRecord) printf(".*");
        printf(" <== ");

        traceDataValue(pDataValue, pDataType);
    }
}

void traceDataFetch(SYMBNODE *pId, void *pDataValue, TTYPE *pDataType) {
    if (executor.traceFetchFlag) {
        TFormCode form = pId->type.form;
        char name[CHUNK_LEN];

        retrieveChunk(pId->node.nameChunkNum, (unsigned char *)name);

        printf(">>   %.*s", CHUNK_LEN, name);
        if (form == fcArray) printf("[*]");
        else if (form == fcRecord) printf(".*");
        printf(" <== ");

        traceDataValue(pDataValue, pDataType);
    }
}

void traceDataValue(void *pDataValue, TTYPE *pDataType) {
    char text[80];
    int length;
    SYMTABNODE node;
    TTYPE baseType;

    if (pDataType->nodeChunkNum == charType) {
        sprintf(text, "'%c'", ((STACKITEM *)pDataValue)->character);
    } else if (pDataType->nodeChunkNum == booleanType) {
        strcpy(text, ((STACKITEM *)pDataValue)->integer == 0 ? "false" : "true");
    } else if (pDataType->form == fcArray) {
        if (pDataType->array.elemType == charType) {
            length = pDataType->array.elemCount;
            memcpy(text + 1, pDataValue, length);
            text[0] = '\'';
            text[length + 1] = '\'';
            text[length + 2] = 0;
        } else {
            strcpy(text, "<array>");
        }
    } else if (pDataType->form == fcRecord) {
        strcpy(text, "<record>");
    } else if (pDataType->form == fcEnum) {
        length = ((STACKITEM *)pDataValue)->integer;
        retrieveChunk(getBaseType(pDataType), (unsigned char *)&baseType);
        retrieveChunk(baseType.enumeration.constIds, (unsigned char *)&node);
        while (--length >= 0) {
            retrieveChunk(node.nextNode, (unsigned char *)&node);
        }
        retrieveChunk(node.nameChunkNum, (unsigned char *)text);
    } else if (pDataType->nodeChunkNum == realType) {
        floatToStr(((STACKITEM *)pDataValue)->real, text, -1);
    } else {
        sprintf(text, "%d", ((STACKITEM *)pDataValue)->integer);
    }

    printf("%s\n", text);
}

#endif
