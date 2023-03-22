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
#include <string.h>
#include <parscommon.h>
#include <membuf.h>

CHUNKNUM executeExpression(void)
{
    CHUNKNUM operand1Type;     // first operand's type
    CHUNKNUM operand2Type;     // second operand's type
    CHUNKNUM resultType;       // result type
    TTYPE type;
    TTokenCode op;

    // Execute the first simple expression
    resultType = executeSimpleExpression();

    // If we now see a relational operator,
    // execute a second simple expression.
    if (tokenIn(executor.token.code, tlRelOps)) {
        op = executor.token.code;
        operand1Type = resultType;
        resultType = booleanType;

        retrieveChunk(operand1Type, (unsigned char *)&type);

        getTokenForExecutor();
        operand2Type = executeSimpleExpression();

        // perform the operation, and push the resulting value
        // onto the runtime stack.
        if ((operand1Type == integerType &&
            operand2Type == integerType)
            || (operand1Type == charType &&
            operand2Type == charType)
            || type.form == fcEnum) {
            // integer <op> integer
            // boolean <op> boolean
            // char <op> char
            // enum <op> enum
            int value1, value2;
            if (operand1Type == charType) {
                value2 = stackPop()->character;
                value1 = stackPop()->character;
            } else {
                value2 = stackPop()->integer;
                value1 = stackPop()->integer;
            }
        
            switch (op) {
                case tcEqual:
                    stackPushInt(value1 == value2);
                    break;

                case tcNe:
                    stackPushInt(value1 != value2);
                    break;
                
                case tcLt:
                    stackPushInt(value1 < value2);
                    break;
                
                case tcGt:
                    stackPushInt(value1 > value2);
                    break;
                
                case tcLe:
                    stackPushInt(value1 <= value2);
                    break;
                
                case tcGe:
                    stackPushInt(value1 >= value2);
                    break;
            }
        } else if (operand1Type == realType || operand2Type == realType) {
            // real    <op> real
            // real    <op> integer
            // integer <op> real
            FLOAT value2 = operand2Type == realType ? stackPop()->real :
                int16ToFloat(stackPop()->integer);
            FLOAT value1 = operand1Type == realType ? stackPop()->real :
                int16ToFloat(stackPop()->integer);

            switch (op) {
                case tcEqual:
                    stackPushInt(floatEq(value1, value2));
                    break;
                
                case tcNe:
                    stackPushInt(!floatEq(value1, value2));
                    break;
                
                case tcLt:
                    stackPushInt(floatLt(value1, value2));
                    break;
                
                case tcGt:
                    stackPushInt(floatGt(value1, value2));
                    break;
                
                case tcLe:
                    stackPushInt(floatLte(value1, value2));
                    break;
                
                case tcGe:
                    stackPushInt(floatGte(value1, value2));
                    break;
            }
        }
    }

    return resultType;
}

CHUNKNUM executeSimpleExpression(void)
{
    CHUNKNUM operandType;           // operand's type
    CHUNKNUM resultType;            // result type
    TTokenCode op;                  // binary operator
    TTokenCode unaryOp = tcPlus;    // unary operator
    TTYPE rType, oType;

    // Unary + or -
    if (tokenIn(executor.token.code, tlUnaryOps)) {
        unaryOp = executor.token.code;
        getTokenForExecutor();
    }

    // Execute the first term.
    resultType = executeTerm();

    // If there was a unary -, negate the first operand value.
    if (unaryOp == tcMinus) {
        if (resultType == realType) {
            stackPushReal(floatNeg(stackPop()->real));
        } else {
            stackPushInt(-stackPop()->integer);
        }
    }

    // Loop to execute subsequent additive operators and terms.
    while (tokenIn(executor.token.code, tlAddOps)) {
        op = executor.token.code;

        retrieveChunk(resultType, (unsigned char *)&rType);
        resultType = getBaseType(&rType);

        getTokenForExecutor();
        operandType = executeTerm();
        retrieveChunk(operandType, (unsigned char *)&oType);
        operandType = getBaseType(&oType);

        // Perform the operation, and push the resulting valud onto the stack.
        if (op == tcOR) {
            // boolean OR boolean
            int value2 = stackPop()->integer;
            int value1 = stackPop()->integer;

            stackPushInt(value1 || value2);
            resultType == booleanType;
        } else if (resultType == integerType && operandType == integerType) {
            // integer +|- integer
            int value2 = stackPop()->integer;
            int value1 = stackPop()->integer;

            stackPushInt(op == tcPlus ? value1 + value2 : value1 - value2);
            resultType == integerType;
        } else {
            // real    +|- real
            // real    +|- integer
            // integer +|- real
            FLOAT value2 = operandType == realType ? stackPop()->real :
                int16ToFloat(stackPop()->integer);
            FLOAT value1 = resultType == realType ? stackPop()->real :
                int16ToFloat(stackPop()->integer);
            
            stackPushReal(op == tcPlus ? floatAdd(value1, value2) :
                floatSub(value1, value2));
            resultType = realType;
        }
    } 

    return resultType;
}

CHUNKNUM executeTerm(void)
{
    CHUNKNUM operandType;
    CHUNKNUM resultType;
    TTYPE rType, oType;
    TTokenCode op;

    // Execute the first factor
    resultType = executeFactor();

    // Loop to execute subsequent multiplicative operators and factors.
    while (tokenIn(executor.token.code, tlMulOps)) {
        op = executor.token.code;
        retrieveChunk(resultType, (unsigned char *)&rType);
        resultType = getBaseType(&rType);

        getTokenForExecutor();
        operandType = executeFactor();
        retrieveChunk(operandType, (unsigned char *)&oType);
        operandType = getBaseType(&oType);

        // perform the operation, and push the resulting value
        // onto the runtime stack.
        switch (op) {
            case tcAND: {
                // boolean AND boolean
                int value2 = stackPop()->integer;
                int value1 = stackPop()->integer;
                stackPushInt(value1 && value2);
                resultType = booleanType;
                break;
            }

            case tcStar:
                if (resultType == integerType && operandType == integerType) {
                    // integer * integer
                    int value2 = stackPop()->integer;
                    int value1 = stackPop()->integer;

                    stackPushInt(value1 * value2);
                    resultType = integerType;
                } else {
                    // real    * real
                    // real    * integer
                    // integer * real
                    FLOAT value2 = operandType == realType ? stackPop()->real :
                        int16ToFloat(stackPop()->integer);
                    FLOAT value1 = resultType == realType ? stackPop()->real :
                        int16ToFloat(stackPop()->integer);
                    
                    stackPushReal(floatMult(value1, value2));
                    resultType = realType;
                }
                break;

            case tcSlash: {
                // integer / integer
                if (operandType == integerType && resultType == integerType) {
                    // integer / integer
                    int value2 = stackPop()->integer;
                    int value1 = stackPop()->integer;

                    stackPushInt(value1 / value2);
                    resultType = integerType;
                } else {
                    // real    / real
                    // real    / integer
                    // integer / real
                    FLOAT value2 = operandType == realType ? stackPop()->real :
                        int16ToFloat(stackPop()->integer);
                    FLOAT value1 = resultType == realType ? stackPop()->real :
                        int16ToFloat(stackPop()->integer);
                    
                    stackPushReal(floatDiv(value1, value2));
                    resultType = realType;
                }
                break;
            }

            case tcDIV:
            case tcMOD: {
                int value2 = stackPop()->integer;
                int value1 = stackPop()->integer;

                if (value2 == 0) runtimeError(rteDivisionByZero);
                stackPushInt(op == tcDIV ? value1 / value2 : value1 % value2);
                resultType = integerType;
                break;
            }

        }
    }

    return resultType;
}

CHUNKNUM executeFactor(void)
{
    CHUNKNUM resultType;

    switch (executor.token.code) {
        case tcIdentifier:
            switch (executor.pNode.defn.how) {
                case dcFunction:
                    resultType = executeSubroutineCall(&executor.pNode);
                    break;
                
                case dcConstant:
                    resultType = executeConstant(&executor.pNode);
                    break;
                
                default:
                    resultType = executeVariable(&executor.pNode, 0);
                    break;
            }
            break;

        case tcNumber:
            // Push the number's value onto the runtime stack
            if (executor.pNode.type.nodeChunkNum == integerType) {
                stackPushInt(executor.pNode.defn.constant.value.integer);
            } else {
                stackPushReal(executor.pNode.defn.constant.value.real);
            }
            resultType = executor.pNode.type.nodeChunkNum;
            getTokenForExecutor();
            break;

        case tcString: {
            // Push either a character or a string address onto the runtime stack,
            // depending on the string length.
            int length = strlen(executor.token.string);
            if (length == 3) {
                // Character
                stackPushChar(executor.pNode.defn.constant.value.character);
                resultType = charType;
            } else {
                stackPushNode(executor.pNode.defn.constant.value.stringChunkNum);
                resultType = executor.pNode.node.typeChunk;
            }
            getTokenForExecutor();
            break;
        }

        case tcNOT:
            // Execute factor and invert its value.
            getTokenForExecutor();
            executeFactor();
            stackPushInt(1 - stackPop()->integer);
            resultType = booleanType;
            break;

        case tcLParen:
            // Parenthesized subexpression: call executeExpression() recursively
            getTokenForExecutor();
            resultType = executeExpression();
            getTokenForExecutor();
            break;
    }

    return resultType;
}

CHUNKNUM executeConstant(SYMBNODE *pId) {
    TDataValue value;

    memcpy(&value, &pId->defn.constant.value, sizeof(TDataValue));

    if (pId->type.nodeChunkNum == realType) stackPushReal(value.real);
    else if (pId->type.nodeChunkNum == charType) stackPushChar(value.character);
    else stackPushInt(value.integer);

    getTokenForExecutor();
    return pId->type.nodeChunkNum;
}

// addressFlag is non-zero if this function is processing
// the variable on the left-half of an assignment.  If so,
// the address of the variable is left on the stack.  If not,
// the variable's value is left on the stack in its place.
CHUNKNUM executeVariable(SYMBNODE *pId, char addressFlag) {
    char doneFlag = 0;
    TTYPE type;
    CHUNKNUM resultType;
    SYMBNODE node;

    // Get the variable's runtime stack address
    STACKITEM *pEntry = stackGetValueAddress(pId);

    memcpy(&type, &pId->type, sizeof(TTYPE));
    resultType = type.nodeChunkNum;

    // If it's a VAR formal parameter, or the type is an array
    // or record, then the stack item contains the address
    // of the data.  Push the data address onto the stack.
    if (pId->defn.how == dcVarParm || !isTypeScalar(&type)) {
        // VAR formal parameter.  Push the address of the data
        // onto the stack.
        stackPushMemBuf(pEntry->membuf.membuf, 0);
        pEntry = stackTOS();
    } else {
        stackPushItem(pEntry);
    }

    getTokenForExecutor();

    // Loop to execute any subscripts and field designators,
    // which will modify the data address at the top of the stack.
    do {
        switch (executor.token.code) {
            case tcLBracket:
                loadSymbNode(executor.prevNode, &node);
                resultType = executeSubscripts(&node.type);
                break;
            
            case tcPeriod:
                resultType = executeField(&type);
                break;
            
            default:
                doneFlag = 1;
                break;
        }
    } while (!doneFlag);

    // If addressFlag is zero, and the data is not an array
    // or a record, replace the address at the top of the stack
    // with the data value.
    if (!addressFlag && isTypeScalar(&type)) {
        if (type.nodeChunkNum == realType) {
            stackPushReal(stackPop()->pStackItem->real);
        } else if (type.nodeChunkNum == charType) {
            stackPushChar(stackPop()->pStackItem->character);
        } else {
            stackPushInt(stackPop()->pStackItem->integer);
        }
    }

    // If addressFlag is zero, and the data is an array or a
    // record, retrieve the value from the memory buffer and
    // replace the address at the top of the stack with the value.
    if (!addressFlag && !isTypeScalar(&type)) {
        stackPop();     // pop the membuf address off the stack
        if (resultType == charType) {
            char value;
            copyFromMemBuf(pEntry->membuf.membuf, &value, pEntry->membuf.offset, 1);
            stackPushChar(value);
        } else if (resultType == integerType || resultType == booleanType) {
            int value;
            copyFromMemBuf(pEntry->membuf.membuf, &value, pEntry->membuf.offset, 2);
            stackPushInt(value);
        }
        else {
            // Put the membuf back on the stack
            stackPushMemBuf(pEntry->membuf.membuf, 0);
        }
    } else if (!isTypeScalar(&type) && pId->defn.how != dcVarParm) {
        // The variable is the target of an assignment.  Look up the
        // size of the data value and push it on the stack.
        TTYPE t;
        STACKITEM addr;
        retrieveChunk(resultType, (unsigned char *)&t);
        // Pop the address off the stack
        memcpy(&addr, stackPop(), sizeof(STACKITEM));
        // Push the size
        stackPushInt(t.size);
        // Now, push the address back on the stack
        stackPushMemBuf(addr.membuf.membuf, addr.membuf.offset);
    }

#ifdef __TEST__
    if (!addressFlag) {
        void *pDataValue = isTypeScalar(&type) ? stackTOS() : stackTOS()->pStackItem;
        traceDataFetch(pId, pDataValue, &type);
    }
#endif

    return resultType;
}

CHUNKNUM executeSubscripts(TTYPE *pType) {
    TTYPE arrayType;
    TTYPE elemType;
    int value;

    memcpy(&arrayType, pType, sizeof(TTYPE));
    retrieveChunk(arrayType.array.elemType, (unsigned char *)&elemType);

    // Loop to execute subscript lists enclosed in brackets.
    while (executor.token.code == tcLBracket) {
        // Loop to execute comma-separated subscript expressions
        // within a subscript list.
        do {
            getTokenForExecutor();
            executeExpression();

            // Evaluate and range check the subscript
            value = stackPop()->integer;
            rangeCheck(&arrayType, value);

            // Modify the data address at the top of the stack.
            stackTOS()->membuf.offset += elemType.size * (value - arrayType.array.minIndex);
            getTokenForExecutor();

            // Prepare for another subscript in this list
            if (executor.token.code == tcComma) {
                retrieveChunk(arrayType.array.elemType, (unsigned char *)&arrayType);
                retrieveChunk(arrayType.array.elemType, (unsigned char *)&elemType);
            }
        } while (executor.token.code == tcComma);

        // Prepare for another subscript in this list
        if (executor.token.code == tcLBracket) {
            retrieveChunk(arrayType.array.elemType, (unsigned char *)&arrayType);
            retrieveChunk(arrayType.array.elemType, (unsigned char *)&elemType);
        }
    }

    return elemType.nodeChunkNum;
}

CHUNKNUM executeField(TTYPE * /*pType*/) {
    CHUNKNUM resultType;
    getTokenForExecutor();

    stackTOS()->membuf.offset += executor.pNode.defn.data.offset;
    resultType = executor.pNode.type.nodeChunkNum;
    getTokenForExecutor();

    return resultType;
}
