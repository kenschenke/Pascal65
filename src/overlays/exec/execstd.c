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

CHUNKNUM executeAbsCall(void) {
    CHUNKNUM parmTypeChunk;

    getTokenForExecutor(); // (
    getTokenForExecutor();

    parmTypeChunk = executeExpression();

    if (getBaseType(getChunk(parmTypeChunk)) == integerType) {
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

CHUNKNUM executeEofEolnCall(TRoutineCode routineCode) {
    if (routineCode == rcEof) {
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

CHUNKNUM executePrecSuccCall(TRoutineCode routineCode) {
    CHUNKNUM parmTypeChunk;
    int parmValue;

    getTokenForExecutor();  // (
    getTokenForExecutor();

    parmTypeChunk = executeExpression();
    parmValue = stackPop()->integer;

    if (routineCode == rcPred) --parmValue;
    else                       ++parmValue;
    rangeCheck(getChunk(parmTypeChunk), parmValue);
    stackPushInt(parmValue);

    getTokenForExecutor(); // token after )
    return parmTypeChunk;
}

CHUNKNUM executeReadReadlnCall(TRoutineCode routineCode) {
    CHUNKNUM varTypeChunk;
    TTYPE *pVarType;
    char ch;
    STACKITEM *pVarValue;

    // Actual parameters are optional for readln
    getTokenForExecutor();
    if (executor.token.code == tcLParen) {
        // Loop to read each parameter value.
        do {
            // Variable
            getTokenForExecutor();
            varTypeChunk = executeVariable(executor.nodeChunkNum, getChunk(executor.defnChunkNum), executor.typeChunkNum, 1);
            pVarValue = stackPop()->pStackItem;

            // Read the value.
            pVarType = getChunk(varTypeChunk);
            if (getBaseType(pVarType) == integerType) {
                pVarValue->integer = readIntFromInput();
                rangeCheck(pVarType, pVarValue->integer);
            } else if (varTypeChunk == realType) {
                pVarValue->real = readFloatFromInput();
            } else {
                pVarValue->character = readCharFromInput();
                rangeCheck(pVarType, ch);
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

CHUNKNUM executeRoundTruncCall(TRoutineCode routineCode) {
    FLOAT parmValue;

    getTokenForExecutor(); // (
    getTokenForExecutor();
    executeExpression();

    parmValue = stackTOS()->real;

    if (routineCode == rcRound) {
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

CHUNKNUM executeWriteWritelnCall(TRoutineCode routineCode) {
    int fieldWidth, fieldPrecision;
    CHUNKNUM exprTypeChunkNum, baseTypeChunkNum;
    TTYPE exprType;

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
                writeQuotedString(((DEFN *)getChunk(executor.defnChunkNum))->constant.value.stringChunkNum);
            }
        } while (executor.token.code == tcComma);

        getTokenForExecutor();
    }

    // End the line if writeln.
    if (routineCode == rcWriteln) {
        puts("\n");
    }

    return dummyType;
}

static void writeQuotedString(CHUNKNUM chunkNum) {
    STRVALCHUNK *pChunk;

    while (chunkNum) {
        pChunk = getChunk(chunkNum);
        printf("%.*s", sizeof(pChunk->value), pChunk->value);
        chunkNum = pChunk->nextChunkNum;
    }
}

