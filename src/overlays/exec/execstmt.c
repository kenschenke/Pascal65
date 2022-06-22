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
    SYMTABNODE *pTargetNode = pExec->pNode;

    getTokenForExecutor(pExec);     // :=
    getTokenForExecutor(pExec);     // first token of expression

    // Execute the expression and pop its value into the
    // target variable's symbol table node
    executeExpression(pExec);
    pTargetNode->value = rtstack_pop(pExec->runStack);

    // If the target variable is "output", print its value
    // preceded by the current source line number
    if (pTargetNode == pExec->pOutputNode) {
        sprintf(message, ">> At %d: output = %d", currentLineNumber,
            pTargetNode->value);
        outputLine(message);
    }
}

