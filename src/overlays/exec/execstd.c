#include <exec.h>
#include <stdio.h>
#include <stdlib.h>
#include <inputbuf.h>
#include <real.h>

#define DEFAULT_FIELD_WIDTH 10
#define DEFAULT_PRECISION 2

// 0.51
#define FLOAT_POINT_51 0x004147af

static void writeQuotedString(CHUNKNUM chunkNum);

CHUNKNUM executeAbsSqrCall(SYMBNODE *pRoutineId) {
    char absFlag = pRoutineId->defn.routine.which == rcAbs;
    CHUNKNUM parmTypeChunk, parmBaseType;
    TTYPE parmType;

    getTokenForExecutor(); // (
    getTokenForExecutor();

    parmTypeChunk = executeExpression();
    retrieveChunk(parmTypeChunk, (unsigned char *)&parmType);
    parmBaseType = getBaseType(&parmType);

    if (parmBaseType == integerType) {
        stackTOS()->integer = absFlag ? abs(stackTOS()->integer) :
            stackTOS()->integer * stackTOS()->integer;
    } else {
        stackTOS()->real = absFlag ? floatAbs(stackTOS()->real) :
            floatMult(stackTOS()->real, stackTOS()->real);
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
            } else if (varTypeChunk == realType) {
                pVarValue->real = readFloatFromInput();
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

CHUNKNUM executeRoundTruncCall(SYMBNODE *pRoutineId) {
    FLOAT parmValue;
    TRoutineCode which = pRoutineId->defn.routine.which;

    getTokenForExecutor(); // (
    getTokenForExecutor();
    executeExpression();

    parmValue = stackTOS()->real;

    if (which == rcRound) {
        if (floatGt(parmValue, 0)) {
            stackTOS()->integer = floatToInt16(floatAdd(parmValue, FLOAT_POINT_51));
        } else {
            stackTOS()->integer = floatToInt16(floatSub(parmValue, FLOAT_POINT_51));
        }
    } else {
        stackTOS()->integer = floatToInt16(parmValue);
    }

    getTokenForExecutor();  // token after )

    return integerType;
}

CHUNKNUM executeWriteWritelnCall(SYMBNODE *pRoutineId) {
    int fieldWidth, fieldPrecision;
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
            if (baseTypeChunkNum == integerType || baseTypeChunkNum == realType) {
                fieldWidth = DEFAULT_FIELD_WIDTH;
            } else {
                fieldWidth = 0;
            }

            // Optional field width <expr-2>
            if (executor.token.code == tcColon) {
                getTokenForExecutor();
                executeExpression();
                fieldWidth = stackPop()->integer;

                fieldPrecision = -1;
                if (executor.token.code == tcColon) {
                    getTokenForExecutor();
                    executeExpression();
                    fieldPrecision = stackPop()->integer;
                }
            }

            // Write the value
            if (baseTypeChunkNum == integerType) {
                printf("%*d", fieldWidth, stackPop()->integer);
            } else if (baseTypeChunkNum == realType) {
                floatPrint(stackPop()->real, fieldPrecision, fieldWidth);
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
    char buffer[CHUNK_LEN];
    int toGet, len;
    MEMBUF membuf;

    retrieveChunk(chunkNum, (unsigned char *)&membuf);
    len = membuf.used;

    setMemBufPos(chunkNum, 0);
    while (len) {
        toGet = len > CHUNK_LEN ? CHUNK_LEN : len;
        readFromMemBuf(chunkNum, buffer, toGet);
        printf("%.*s", toGet, buffer);
        len -= toGet;
    }
}

