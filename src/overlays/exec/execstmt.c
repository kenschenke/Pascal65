/**
 * execstmt.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for processing statements for the executor.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <exec.h>
#include <ovrlcommon.h>
#include <string.h>
#include <membuf.h>

void executeStatement(void)
{
    if (executor.token.code != tcBEGIN) {
        ++executor.stmtCount;
        traceStatement();
    }

    switch (executor.token.code) {
        case tcIdentifier: {
            DEFN *pDefn = getChunk(executor.defnChunkNum);
            if (pDefn->how == dcProcedure) {
                executeSubroutineCall(pDefn);
            } else {
                executeAssignment();
            }
            break;
        }

        case tcREPEAT: executeREPEAT(); break;
        case tcBEGIN: executeCompound(); break;
        case tcWHILE: executeWHILE(); break;
        case tcIF: executeIF(); break;
        case tcFOR: executeFOR(); break;
        case tcCASE: executeCASE(); break;
    }
}

void executeStatementList(TTokenCode terminator) {
    // Look to execute statements and skip semicolons
    do {
        executeStatement();
        while (executor.token.code == tcSemicolon) getTokenForExecutor();
    } while (executor.token.code != terminator);
}

void executeAssignment(void)
{
    DEFN *pDefn;
    STACKITEM target;           // runtime stack address of target
    CHUNKNUM targetTypeChunkNum;
    TTYPE *targetType;     // target type object
    CHUNKNUM exprType, exprBaseType;

    pDefn = getChunk(executor.defnChunkNum);

    // Assignment to function name
    if (pDefn->how == dcFunction) {
        targetTypeChunkNum = executor.typeChunkNum;
        target.pStackItem = stackGetValueAddress(executor.nodeChunkNum, pDefn);

        getTokenForExecutor();
    }

    // Assignment to variable or formal parameter.
    // ExecuteVariable leaves the target address on
    // top of the runtime stack.
    else {
        targetTypeChunkNum = executeVariable(executor.nodeChunkNum,
            getChunk(executor.defnChunkNum), executor.typeChunkNum, 1);
        memcpy(&target, stackPop(), sizeof(STACKITEM));
    }

    // Execute the expression and leave its value
    // on top of the runtime stack.
    getTokenForExecutor();
    exprType = executeExpression();
    exprBaseType = getBaseType(getChunk(exprType));

    targetType = getChunk(executor.typeChunkNum);
    if (targetType->nodeChunkNum != getBaseType(targetType)) {
        targetType = getChunk(getBaseType(targetType));
    }

    // Do the assignment
    if (targetType->nodeChunkNum == realType) {
        target.pStackItem->real = exprBaseType == integerType
            ? int16ToFloat(stackPop()->integer)     // real := integer
            : stackPop()->real;                     // real := real
    } else if (targetType->nodeChunkNum == integerType || targetType->form == fcEnum) {
        int value;
        value = stackPop()->integer;
        rangeCheck(targetType, value);
        target.pStackItem->integer = value;
    } else if (targetType->nodeChunkNum == charType) {
        char value = stackPop()->character;
        rangeCheck(targetType, value);
        target.pStackItem->character = value;
    } else {
        void *pSource = stackPop();
        copyToMemBuf(target.membuf.membuf, pSource,
            target.membuf.offset, stackPop()->integer);
    }

#if 0
    traceDataStore(&targetId, target.pStackItem, &targetType);
#endif
}

void executeCompound(void) {
    getTokenForExecutor();

    // <stmt-list> END
    executeStatementList(tcEND);

    getTokenForExecutor();
}

void executeCASE(void) {
    int exprValue, labelValue;
    CHUNKNUM exprTypeChunkNum, exprBaseTypeChunkNum;
    MEMBUF_LOCN followLocn, branchTable, branchLocn;

    getTokenForExecutor();

    // Get the location of the token that follows the
    // CASE statement and of the branch table.
    getLocationMarker(executor.Icode, &followLocn);
    getTokenForExecutor();
    getLocationMarker(executor.Icode, &branchTable);

    // Evaluate the CASE expression.
    getTokenForExecutor();
    exprTypeChunkNum = executeExpression();
    exprBaseTypeChunkNum = getBaseType(getChunk(exprTypeChunkNum));
    exprValue = exprBaseTypeChunkNum == integerType || ((TTYPE *)getChunk(exprBaseTypeChunkNum))->form == fcEnum ?
        stackPop()->integer : stackPop()->character;
    
    // Search the branch table for the expression value.
    setMemBufLocn(executor.Icode, &branchTable);
    do {
        getCaseItem(executor.Icode, &labelValue, &branchLocn);
    } while (exprValue != labelValue && branchLocn.chunkNum != 0);

    // If found, execute the appropriate CASE statement
    if (branchLocn.chunkNum != 0) {
        setMemBufLocn(executor.Icode, &branchLocn);
        // Back up one location to account for the line marker
        setMemBufPos(executor.Icode, getMemBufPos(executor.Icode)-1);
        getTokenForExecutor();
        executeStatement();

        setMemBufLocn(executor.Icode, &followLocn);
        getTokenForExecutor();
    } else {
        runtimeError(rteInvalidCaseValue);
    }
}

void executeFOR(void) {
    char integerFlag;
    int initialValue, controlValue, delta, finalValue;
    CHUNKNUM controlTypeChunk, controlTypeBase;
    TTYPE controlType;
    MEMBUF_LOCN locnFollow, loopStart;
    STACKITEM *pControlValue;

    getTokenForExecutor();

    // Get the location of the token that follows the FOR statement.
    getLocationMarker(executor.Icode, &locnFollow);

    // Get a pointer to the control variable's type object and
    // a pointer to its value on the runtime stack item.
    getTokenForExecutor();
    controlTypeChunk = executeVariable(executor.nodeChunkNum,
        getChunk(executor.defnChunkNum), executor.typeChunkNum, 1);
    retrieveChunk(controlTypeChunk, (unsigned char *)&controlType);
    pControlValue = stackPop()->pStackItem;

    // := <expr-1>
    getTokenForExecutor();
    executeExpression();
    controlTypeBase = getBaseType(&controlType);
    integerFlag = controlTypeBase == integerType ||
        ((TTYPE *)getChunk(controlTypeBase))->form == fcEnum;
    initialValue = integerFlag ? stackPop()->integer : stackPop()->character;
    controlValue = initialValue;

    // TO or DOWNTO
    delta = executor.token.code == tcTO ? 1 : -1;

    // <expr-2>
    getTokenForExecutor();
    executeExpression();
    finalValue = integerFlag ? stackPop()->integer : stackPop()->character;

    // Remember the current location of the stack of the loop.
    getMemBufLocn(executor.Icode, &loopStart);

    // Execute the loop until the control value
    // reaches the final value;
    while ((delta == 1 && controlValue <= finalValue) ||
        (delta == -1 && controlValue >= finalValue)) {
            // Set the control variable's value
            if (integerFlag) pControlValue->integer = controlValue;
            else pControlValue->character = controlValue & 0xFF;
            rangeCheck(&controlType, controlValue);
#if 0
            traceDataStore(&controlId, pControlValue, &controlType);
#endif

            // DO <stmt>
            getTokenForExecutor();
            executeStatement();

            // Increment or decrement the control value,
            // and possibly execute <stmt> again.
            controlValue += delta;
            setMemBufLocn(executor.Icode, &loopStart);
        }
    
    // Jump out of the loop.
    // The control variable is left with the final value.
    setMemBufLocn(executor.Icode, &locnFollow);
    getTokenForExecutor();
}

void executeIF(void) {
    MEMBUF_LOCN locnFalse, locnFollow;

    getTokenForExecutor();

    // Get the location of where to go if <expr> is false.
    getLocationMarker(executor.Icode, &locnFalse);

    getTokenForExecutor();
    getLocationMarker(executor.Icode, &locnFollow);

    // <expr>
    getTokenForExecutor();
    executeExpression();

    if (stackPop()->integer) {
        // true: THEN <stmt>
        getTokenForExecutor();
        executeStatement();

        // If there is an ELSE part, jump around it.
        if (executor.token.code == tcELSE) {
            getTokenForExecutor();
            setMemBufLocn(executor.Icode, &locnFollow);
            getTokenForExecutor();
        }
    } else {
        // false: go to the false location
        setMemBufLocn(executor.Icode, &locnFalse);
        getTokenForExecutor();

        if (executor.token.code == tcELSE) {
            // ELSE <stmt>
            getTokenForExecutor();
            getTokenForExecutor();
            executeStatement();
        }
    }
}

void executeREPEAT(void) {
    unsigned atLoopStart = getMemBufPos(executor.Icode);
    MEMBUF_LOCN loopStart;

    getMemBufLocn(executor.Icode, &loopStart);

    do {
        getTokenForExecutor();

        // <stmt-list> UNTIL
        executeStatementList(tcUNTIL);

        // <expr>
        getTokenForExecutor();
        executeExpression();

        // Decide whether or not to branch back to the loop start.
        if (stackPop()->integer == 0) {
            setMemBufLocn(executor.Icode, &loopStart);
        }
    } while (getMemBufPos(executor.Icode) == atLoopStart);
}

void executeWHILE(void) {
    char doneFlag;
    MEMBUF_LOCN locnFollow, locnExpr;

    getTokenForExecutor();  // consume the location marker token

    // Get the location of the token that follows the WHILE statement
    // and remember the current location of the boolean expression.

    getLocationMarker(executor.Icode, &locnFollow);
    getMemBufLocn(executor.Icode, &locnExpr);

    // Loop to evaluate the boolean expression and to execute the
    // statement if the expression is true.
    doneFlag = 0;
    do {
        // <expr>
        getTokenForExecutor();
        executeExpression();

        if (stackPop()->integer) {
            // true: DO <stmt>
            // go back to re-evaluate the boolean expression
            getTokenForExecutor();
            executeStatement();
            setMemBufLocn(executor.Icode, &locnExpr);
        } else {
            // false: jump out of the loop
            doneFlag = 1;
            setMemBufLocn(executor.Icode, &locnFollow);
        }
    } while (!doneFlag);

    getTokenForExecutor();
}
