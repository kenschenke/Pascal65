#include <exec.h>
#include <stdio.h>

#define DEFAULT_FIELD_WIDTH 10
#define DEFAULT_PRECISION 2

static void writeQuotedString(CHUNKNUM chunkNum);

CHUNKNUM executeWriteWritelnCall(SYMBNODE *pRoutineId) {
    int fieldWidth;
    TRoutineCode which;
    CHUNKNUM exprTypeChunkNum, baseTypeChunkNum;
    TTYPE exprType;

    which = pRoutineId->defn.routine.which;

    // Actual parameters are optional for writeln.
    getTokenForExecutor();
    if (executor.token.code == tcLParen) {
        // Loop to write each parameter value.
        do {
            getTokenForExecutor();
            exprTypeChunkNum = executeExpression();
            retrieveChunk(exprTypeChunkNum, (unsigned char *)&exprType);
            baseTypeChunkNum = getBaseType(&exprType);
            if (baseTypeChunkNum == integerType) {
                fieldWidth = DEFAULT_FIELD_WIDTH;
            } else {
                fieldWidth = 0;
            }

            // Optional field width <expr-2>
            if (executor.token.code == tcColon) {
                getTokenForExecutor();
                executeExpression();
                fieldWidth = stackPop()->integer;
            }

            // Write the value
            if (baseTypeChunkNum == integerType) {
                printf("%*d", fieldWidth, stackPop()->integer);
            } else if (baseTypeChunkNum == booleanType) {
                printf("%*s", fieldWidth, stackPop()->integer == 0 ? "FALSE" : "TRUE");
            } else if (baseTypeChunkNum == charType) {
                printf("%*c", fieldWidth, stackPop()->character);
            } else if (exprType.form == fcArray && exprType.array.elemType == charType) {
                writeQuotedString(executor.pNode.defn.constant.value.stringChunkNum);
            }
        } while (executor.token.code == tcComma);

        getTokenForExecutor();
    }

    // End the line if writeln.
    if (which == rcWriteln) {
        puts("\n");
    }

    return dummyType;
}

static void writeQuotedString(CHUNKNUM chunkNum) {
    STRVALCHUNK chunk;

    while (chunkNum) {
        retrieveChunk(chunkNum, (unsigned char *)&chunk);
        printf("%.*s", sizeof(chunk.value), chunk.value);
        chunkNum = chunk.nextChunkNum;
    }
}

