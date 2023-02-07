#include <exec.h>
#include <stdio.h>
#include <stdlib.h>
#include <inputbuf.h>

#define DEFAULT_FIELD_WIDTH 10
#define DEFAULT_PRECISION 2

static void writeQuotedString(CHUNKNUM chunkNum);

CHUNKNUM executeAbsCall(void) {
    CHUNKNUM parmTypeChunk, parmBaseType;
    TTYPE parmType;

    getTokenForExecutor(); // (
    getTokenForExecutor();

    parmTypeChunk = executeExpression();
    retrieveChunk(parmTypeChunk, (unsigned char *)&parmType);
    parmBaseType = getBaseType(&parmType);

    if (parmBaseType == integerType) {
        stackTOS()->integer = abs(stackTOS()->integer);
    }

    getTokenForExecutor();
    return parmTypeChunk;
}

CHUNKNUM executeChrCall(void) {
    getTokenForExecutor(); // (
    getTokenForExecutor();
    executeExpression();

    stackTOS()->integer &= 0xff;

    getTokenForExecutor();
    return charType;
}

CHUNKNUM executeEofEolnCall(SYMBNODE *pRoutineId) {
    if (pRoutineId->defn.routine.which == rcEof) {
        stackPushInt(0);    // always FALSE for stdin
    } else {
        stackPushInt(isInputEndOfLine());
    }

    getTokenForExecutor();
    return booleanType;
}

CHUNKNUM executeOddCall(void) {
    getTokenForExecutor();  // (
    getTokenForExecutor();
    executeExpression();

    stackTOS()->integer &= 1;

    getTokenForExecutor();
    return booleanType;
}

CHUNKNUM executeOrdCall(void) {
    getTokenForExecutor();  // (
    getTokenForExecutor();
    executeExpression();

    getTokenForExecutor();  // after )

    return integerType;
}

CHUNKNUM executePrecSuccCall(SYMBNODE *pRoutineId) {
    TTYPE parmType;
    CHUNKNUM parmTypeChunk;
    int parmValue;
    TRoutineCode routineCode = pRoutineId->defn.routine.which;

    getTokenForExecutor();  // (
    getTokenForExecutor();

    parmTypeChunk = executeExpression();
    parmValue = stackPop()->integer;

    if (routineCode == rcPred) --parmValue;
    else                       ++parmValue;
    retrieveChunk(parmTypeChunk, (unsigned char *)&parmType);
    rangeCheck(&parmType, parmValue);
    stackPushInt(parmValue);

    getTokenForExecutor(); // token after )
    return parmTypeChunk;
}

CHUNKNUM executeReadReadlnCall(SYMBNODE *pRoutineId) {
    SYMBNODE *pVarId = &executor.pNode;
    CHUNKNUM varTypeChunk;
    TTYPE varType;
    char ch;
    STACKITEM *pVarValue;
    TRoutineCode routineCode = pRoutineId->defn.routine.which;

    // Actual parameters are optional for readln
    getTokenForExecutor();
    if (executor.token.code == tcLParen) {
        // Loop to read each parameter value.
        do {
            // Variable
            getTokenForExecutor();
            varTypeChunk = executeVariable(pVarId, 1);
            pVarValue = stackPop()->pStackItem;

            // Read the value.
            retrieveChunk(varTypeChunk, (unsigned char *)&varType);
            if (getBaseType(&varType) == integerType) {
                pVarValue->integer = readIntFromInput();
                rangeCheck(&varType, pVarValue->integer);
            } else {
                pVarValue->character = readCharFromInput();
                rangeCheck(&varType, ch);
            }
        } while (executor.token.code == tcComma);

        getTokenForExecutor();

        // Skip the rest of the line if readln
    }

    // Skip the rest of the input line if readln.
    if (routineCode == rcReadln) {
        clearInputBuf();
    }

    return dummyType;
}

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

