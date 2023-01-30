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
        case tcIdentifier:
            if (executor.pNode.defn.how == dcProcedure) {
                executeSubroutineCall(&executor.pNode);
            } else {
                executeAssignment(&executor.pNode);
            }
            break;

        case tcREPEAT: executeREPEAT(); break;
        case tcBEGIN: executeCompound(); break;

        case tcWHILE:
        case tcIF:
        case tcFOR:
        case tcCASE:
            runtimeError(rteUnimplementedRuntimeFeature);
            break;
    }
}

void executeStatementList(TTokenCode terminator) {
    // Look to execute statements and skip semicolons
    do {
        executeStatement();
        while (executor.token.code == tcSemicolon) getTokenForExecutor();
    } while (executor.token.code != terminator);
}

void executeAssignment(SYMBNODE *pTargetId)
{
    SYMBNODE targetId;
    STACKITEM target;           // runtime stack address of target
    CHUNKNUM targetTypeChunkNum;
    TTYPE targetType;           // target type object
    CHUNKNUM exprType;          // expression type

    memcpy(&targetId, pTargetId, sizeof(SYMBNODE));

    // Assignment to function name
    if (targetId.defn.how == dcFunction) {
        targetTypeChunkNum = targetId.type.nodeChunkNum;
        target.pStackItem = stackGetValueAddress(&targetId);

        getTokenForExecutor();
    }

    // Assignment to variable or formal parameter.
    // ExecuteVariable leaves the target address on
    // top of the runtime stack.
    else {
        targetTypeChunkNum = executeVariable(pTargetId, 1);
        memcpy(&target, stackPop(), sizeof(STACKITEM));
    }

    // Execute the expression and leave its value
    // on top of the runtime stack.
    getTokenForExecutor();
    exprType = executeExpression();

    memcpy(&targetType, &targetId.type, sizeof(TTYPE));
    if (targetType.nodeChunkNum != getBaseType(&targetType)) {
        retrieveChunk(getBaseType(&targetType), (unsigned char *)&targetType);
    }

    // Do the assignment
    /* if (pTargetType == realType) {

    } else */ if (targetType.nodeChunkNum == integerType || targetType.form == fcEnum) {
        int value;
        value = stackPop()->integer;
        rangeCheck(&targetType, value);
        target.pStackItem->integer = value;
    } else if (targetType.nodeChunkNum == charType) {
        char value = stackPop()->character;
        rangeCheck(&targetType, value);
        target.pStackItem->character = value;
    } else {
        void *pSource = stackPop();
        copyToMemBuf(target.membuf.membuf, pSource,
            target.membuf.offset, stackPop()->integer);
    }

    traceDataStore(&targetId, target.pStackItem, &targetType);
}

void executeREPEAT(void) {
#if 0
    unsigned atLoopStart = executorCurrentLocation(pExec);

    do {
        getTokenForExecutor(pExec);

        // <stmt-list> UNTIL
        executeStatementList(pExec, tcUNTIL);

        // <expr>
        getTokenForExecutor(pExec);
        executeExpression(pExec);

        // Decide whether or not to branch back to the loop start.
        if (rtstack_pop(pExec->runStack) == 0) {
            executorGoto(pExec, atLoopStart);
        }
    } while (executorCurrentLocation(pExec) == atLoopStart);
#endif
}

void executeCompound(void) {
    getTokenForExecutor();

    // <stmt-list> END
    executeStatementList(tcEND);

    getTokenForExecutor();
}

