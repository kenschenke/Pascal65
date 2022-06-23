/**
 * execexpr.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for executing expressions in the executor.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <exec.h>
#include <misc.h>
#include <common.h>
#include <stdlib.h>

void executeExpression(EXECUTOR *pExec)
{
    TTokenCode op;
    int operand1, operand2;

    executeSimpleExpression(pExec);

    // If we now see a relational operator,
    // execute a second simple expression.
    if (pExec->token == tcEqual || pExec->token == tcNe ||
        pExec->token == tcLt    || pExec->token == tcGt ||
        pExec->token == tcLe    || pExec->token == tcGe) {
        op = pExec->token;

        getTokenForExecutor(pExec);
        executeSimpleExpression(pExec);

        // Pop off the two operand values, ...
        operand2 = rtstack_pop(pExec->runStack);
        operand1 = rtstack_pop(pExec->runStack);

        // perform the operation, and push the resulting value
        // onto the runtime stack.
        switch (op) {
            case tcEqual:
                rtstack_push(pExec->runStack, operand1 == operand2 ? 1 : 0);
                break;

            case tcNe:
                rtstack_push(pExec->runStack, operand1 != operand2 ? 1 : 0);
                break;
            
            case tcLt:
                rtstack_push(pExec->runStack, operand1 < operand2 ? 1 : 0);
                break;
            
            case tcGt:
                rtstack_push(pExec->runStack, operand1 > operand2 ? 1 : 0);
                break;
            
            case tcLe:
                rtstack_push(pExec->runStack, operand1 <= operand2 ? 1 : 0);
                break;
            
            case tcGe:
                rtstack_push(pExec->runStack, operand1 >= operand2 ? 1 : 0);
                break;
        }
    }
}

void executeSimpleExpression(EXECUTOR *pExec)
{
    int operand1, operand2;
    TTokenCode op;                  // binary operator
    TTokenCode unaryOp = tcPlus;    // unary operator

    // Unary + or -
    if (pExec->token == tcPlus || pExec->token == tcMinus) {
        unaryOp = pExec->token;
        getTokenForExecutor(pExec);
    }

    // Execute the first term and then negate its value
    // if there was a unary minus.
    executeTerm(pExec);
    if (unaryOp == tcMinus) {
        rtstack_push(pExec->runStack, -rtstack_pop(pExec->runStack));
    }

    // Loop to execute subsequent additive operators and terms.
    while (pExec->token == tcPlus || pExec->token == tcMinus || pExec->token == tcOR) {
        op = pExec->token;

        getTokenForExecutor(pExec);
        executeTerm(pExec);

        // Pop off the two operand values, ...
        operand2 = rtstack_pop(pExec->runStack);
        operand1 = rtstack_pop(pExec->runStack);

        // perform the operation, and push the resulting value
        // onto the runtime stack
        switch (op) {
            case tcPlus:
                rtstack_push(pExec->runStack, operand1 + operand2);
                break;

            case tcMinus:
                rtstack_push(pExec->runStack, operand1 - operand2);
                break;

            case tcOR:
                rtstack_push(pExec->runStack, operand1 != 0 || operand2 != 0 ? 1 : 0);
                break;
        }
    }
}

void executeTerm(EXECUTOR *pExec)
{
    TTokenCode op;
    int operand1, operand2, divZeroFlag;

    // Execute the first factor
    executeFactor(pExec);

    // Loop to execute subsequent multiplicative operators and factors.
    while (pExec->token == tcStar || pExec->token == tcSlash ||
            pExec->token == tcDIV || pExec->token == tcMOD ||
            pExec->token == tcAND) {
        op = pExec->token;

        getTokenForExecutor(pExec);
        executeFactor(pExec);

        // Pop off the two operand values, ...
        operand2 = rtstack_pop(pExec->runStack);
        operand1 = rtstack_pop(pExec->runStack);

        // perform the operation, and push the resulting value
        // onto the runtime stack.
        divZeroFlag = 0;  // non-zero if division by zero
        switch (op) {
            case tcStar:
                rtstack_push(pExec->runStack, operand1 * operand2);
                break;

            case tcSlash:
            case tcDIV:
                if (operand2 != 0) {
                    rtstack_push(pExec->runStack, operand1 / operand2);
                } else {
                    divZeroFlag = 1;
                }
                break;
            
            case tcMOD:
                if (operand2 != 0) {
                    rtstack_push(pExec->runStack, operand1 % operand2);
                } else {
                    divZeroFlag = 1;
                }
                break;

            case tcAND:
                rtstack_push(pExec->runStack, operand1 != 0 && operand2 != 0 ? 1 : 0);
                break;
        }

        if (divZeroFlag) {
            // Division by zero runtime error
            runtimeError(rteDivisionByZero);
            rtstack_push(pExec->runStack, 0);
        }
    }
}

void executeFactor(EXECUTOR *pExec)
{
    char buffer[5+1];

    switch (pExec->token) {
        case tcIdentifier:
            // If the variable is "input", prompt for its value.
            if (pExec->pNode == pExec->pInputNode) {
                printf(">> At %d: input ? ", currentLineNumber);
                if (strInput(buffer, sizeof(buffer))) {
                    pExec->userStop = 1;
                    pExec->pNode->value = 0;
                } else {
                    pExec->pNode->value = atoi(buffer);
                }
            }

            // Push the variable's value onto the runtime stack
            rtstack_push(pExec->runStack, pExec->pNode->value);
            getTokenForExecutor(pExec);
            break;

        case tcNumber:
            // Push the number's value onto the runtime stack
            rtstack_push(pExec->runStack, pExec->pNode->value);
            getTokenForExecutor(pExec);
            break;

        case tcString:
            // Just push 0 for now.
            rtstack_push(pExec->runStack, 0);
            getTokenForExecutor(pExec);
            break;

        case tcNOT:
            // Execute factor and invert its value.
            getTokenForExecutor(pExec);
            executeFactor(pExec);
            rtstack_push(pExec->runStack, rtstack_pop(pExec->runStack) ? 0 : 1);
            break;

        case tcLParen:
            // Parenthesized subexpression: call executeExpression() recursively
            getTokenForExecutor(pExec);
            executeExpression(pExec);
            getTokenForExecutor(pExec);
            break;
    }
}

