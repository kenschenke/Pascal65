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

#include <exec.h>
#include <ovrlcommon.h>
#include <string.h>

void executeStatement(EXECUTOR *pExec)
{
    if (pExec->token != tcBEGIN) {
        ++pExec->stmtCount;
    }

    switch (pExec->token) {
        case tcIdentifier: executeAssignment(pExec); break;
        case tcREPEAT: executeREPEAT(pExec); break;
        case tcBEGIN: executeCompound(pExec); break;

        case tcWHILE:
        case tcIF:
        case tcFOR:
        case tcCASE:
            runtimeError(rteUnimplementedRuntimeFeature);
            break;
    }
}

void executeStatementList(EXECUTOR *pExec, TTokenCode terminator) {
    // Look to execute statements and skip semicolons
    do {
        executeStatement(pExec);
        while (pExec->token == tcSemicolon) getTokenForExecutor(pExec);
    } while (pExec->token != terminator);
}

void executeAssignment(EXECUTOR *pExec)
{
    char message[MAX_LINE_LEN+1];
    SYMTABNODE targetNode;

    memcpy(&targetNode, pExec->pNode, sizeof(SYMTABNODE));

    getTokenForExecutor(pExec);     // :=
    getTokenForExecutor(pExec);     // first token of expression

    // Execute the expression and pop its value into the
    // target variable's symbol table node
    executeExpression(pExec);
    // setSymtabInt(&targetNode, rtstack_pop(pExec->runStack));

    // If the target variable is "output", print its value
    // preceded by the current source line number
    if (targetNode.nodeChunkNum == pExec->outputNode) {
        // sprintf(message, ">> At %d: output = %d", currentLineNumber,
        //     getSymtabInt(&targetNode));
        outputLine(message);
    }
}

void executeREPEAT(EXECUTOR *pExec) {
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
}

void executeCompound(EXECUTOR *pExec) {
    getTokenForExecutor(pExec);

    // <stmt-list> END
    executeStatementList(pExec, tcEND);

    getTokenForExecutor(pExec);
}

