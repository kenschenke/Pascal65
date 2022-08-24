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

    // Only assignment statements for now.
    executeAssignment(pExec);
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
    setSymtabInt(&targetNode, rtstack_pop(pExec->runStack));

    // If the target variable is "output", print its value
    // preceded by the current source line number
    if (targetNode.nodeChunkNum == pExec->outputNode) {
        sprintf(message, ">> At %d: output = %d", currentLineNumber,
            getSymtabInt(&targetNode));
        outputLine(message);
    }
}

