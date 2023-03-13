/**
 * parsexpr.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for parsing expressions.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <error.h>
#include <icode.h>
#include <string.h>
#include <parscommon.h>
#include <common.h>

CHUNKNUM parseExpression(CHUNKNUM Icode)
{
    CHUNKNUM resultTypeChunk, operandTypeChunk;

    // Parse the first simple expression
    resultTypeChunk = parseSimpleExpression(Icode);

    // If we now see a relational operator,
    // parse a second simple expression.
    if (tokenIn(parserToken, tlRelOps)) {
        getTokenAppend(Icode);
        operandTypeChunk = parseSimpleExpression(Icode);

        // Check the operand types and return the boolean type.
        checkRelOpOperands(resultTypeChunk, operandTypeChunk);
        resultTypeChunk = booleanType;
    }

    // Make sure the expression ended properly.
    resync(tlExpressionFollow, tlStatementFollow, tlStatementStart);

    return resultTypeChunk;
}

CHUNKNUM parseFactor(CHUNKNUM Icode)
{
    int length;
    CHUNKNUM resultTypeChunk;
    SYMBNODE node;

    switch (parserToken) {
        case tcIdentifier:
            // Search for the identifier and enter if necessary.
            // Append the symbol table node handle to the icode.
            symtabStackFind(parserString, &node);
            putSymtabNodeToIcode(Icode, &node);
            if (node.defn.how == dcUndefined) {
                node.defn.how = dcVariable;
                setType(&node.node.typeChunk, dummyType);
                saveSymbNode(&node);
            }

            // Based on how the identifier is defined,
            // parse a constant, function call, or variable.
            switch (node.defn.how) {
                case dcFunction:
                    resultTypeChunk = parseSubroutineCall(node.node.nodeChunkNum, 1, Icode);
                    break;

                case dcProcedure:
                    Error(errInvalidIdentifierUsage);
                    resultTypeChunk = parseSubroutineCall(node.node.nodeChunkNum, 0, Icode);
                    break;

                case dcConstant:
                    getTokenAppend(Icode);
                    resultTypeChunk = node.node.typeChunk;
                    break;

                default:
                    resultTypeChunk = parseVariable(Icode, &node);
                    break;
            }

            break;

        case tcNumber:
            // Search for the number and enter it if necessary.
            if (!symtabStackSearchAll(parserString, &node)) {
                symtabEnterLocal(&node, parserString, dcUndefined);

                // Determine the number's type and set its value into
                // the symbol table node.
                if (parserType == tyInteger) {
                    resultTypeChunk = integerType;
                    node.defn.constant.value.integer = parserValue.integer;
                } else {
                    resultTypeChunk = realType;
                    node.defn.constant.value.real = parserValue.real;
                }
                setType(&node.node.typeChunk, resultTypeChunk);
                saveSymbNode(&node);
            }

            // Append the symbol table node handle to the icode.
            putSymtabNodeToIcode(Icode, &node);
            resultTypeChunk = node.node.typeChunk;
            getTokenAppend(Icode);
            break;

        case tcString:
            // Search for the string and enter it if necessary.
            if (!symtabStackSearchAll(parserString, &node)) {
                symtabEnterLocal(&node, parserString, dcUndefined);

                // compute the string length (without the quotes).
                // if the length is 1, the result type is character,
                // else create a new string type.
                length = strlen(parserString) - 2;
                resultTypeChunk = length == 1 ? charType : makeStringType(length);
                setType(&node.node.typeChunk, resultTypeChunk);
                saveSymbNode(&node);

                // Set the character value or string value into the symbol table.
                if (length == 1) {
                    node.defn.constant.value.character = parserString[1];
                } else {
                    copyQuotedString(parserString, &node.defn.constant.value.stringChunkNum);
                }
                saveSymbNode(&node);
            } else {
                resultTypeChunk = node.node.typeChunk;
            }

            // Append the symbol table node to the icode
            putSymtabNodeToIcode(Icode, &node);
            getTokenAppend(Icode);
            break;

        case tcNOT:
            getTokenAppend(Icode);
            resultTypeChunk = parseFactor(Icode);
            checkBoolean(resultTypeChunk, 0);
            break;

        case tcLParen:
            // Parenthesized subexpression: call parseExpression recursively
            getTokenAppend(Icode);
            resultTypeChunk = parseExpression(Icode);

            // and check for the closing right parenthesis
            if (parserToken == tcRParen) {
                getTokenAppend(Icode);
            } else {
                Error(errMissingRightParen);
            }
            break;

        default:
            Error(errInvalidExpression);
            resultTypeChunk = dummyType;
            break;
    }

    return resultTypeChunk;
}

CHUNKNUM parseField(CHUNKNUM Icode, CHUNKNUM recordTypeChunkNum) {
    TTYPE recordType;
    CHUNKNUM varType;
    SYMBNODE fieldId;

    getTokenAppend(Icode);
    getChunkCopy(recordTypeChunkNum, &recordType);

    if (parserToken == tcIdentifier && recordType.form == fcRecord) {
        if (!searchSymtab(recordType.record.symtab, &fieldId, parserString)) {
            fieldId.node.nodeChunkNum = 0;
            Error(errInvalidField);
        }
        putSymtabNodeToIcode(Icode, &fieldId);

        getTokenAppend(Icode);
        varType = fieldId.node.nodeChunkNum ? fieldId.node.typeChunk : dummyType;
    } else {
        Error(errInvalidField);
        getTokenAppend(Icode);
        varType = dummyType;
    }

    return varType;
}

CHUNKNUM parseSimpleExpression(CHUNKNUM Icode)
{
    CHUNKNUM resultTypeChunk, operandTypeChunk;
    TTokenCode op;
    char unaryOpFlag = 0;  // non-zero if unary op

    // Unary + or -
    if (tokenIn(parserToken, tlUnaryOps)) {
        getTokenAppend(Icode);
        unaryOpFlag = 1;
    }

    // Parse the first term
    resultTypeChunk = parseTerm(Icode);

    // If there was a unary sign, check the term's type
    if (unaryOpFlag) {
        checkIntegerOrReal(resultTypeChunk, 0);
    }

    // Loop to parse subsequent additive operators and terms
    while (tokenIn(parserToken, tlAddOps)) {
        // Remember the operator and parse the subsequent term.
        op = parserToken;
        getTokenAppend(Icode);
        operandTypeChunk = parseTerm(Icode);

        switch (op) {
            case tcPlus:
            case tcMinus:
                // integer <op> integer => integer
                if (integerOperands(resultTypeChunk, operandTypeChunk)) {
                    resultTypeChunk = integerType;
                }

                // real    <op> real    => real
                // real    <op> integer => real
                // integer <op> real => real
                else if (realOperands(resultTypeChunk, operandTypeChunk)) {
                    resultTypeChunk = realType;
                } else {
                    Error(errIncompatibleTypes);
                }
                break;

            case tcOR:
                // boolean OR boolean => boolean
                checkBoolean(resultTypeChunk, operandTypeChunk);
                resultTypeChunk = booleanType;
                break;
        }
    }

    return resultTypeChunk;
}

CHUNKNUM parseSubscripts(CHUNKNUM Icode, CHUNKNUM arrayTypeChunk) {
    CHUNKNUM resultTypeChunk, targetTypeChunk;
    TTYPE arrayType;

    getChunkCopy(arrayTypeChunk, &arrayType);

    // Loop to parse a list of subscripts separated by commas.
    do {
        // [ (first) or , (subsequent)
        getTokenAppend(Icode);

        // The current variable is an array type.
        if (arrayType.form == fcArray) {
            // The subscript expression must be an assignment type
            // compatible with the corresponding subscript type.
            targetTypeChunk = parseExpression(Icode);
            checkAssignmentCompatible(arrayType.array.indexType, targetTypeChunk, errIncompatibleTypes);

            // Update the variable's type
            resultTypeChunk = arrayType.array.elemType;
        }

        // No longer an array type, so too many subscripts.
        // Parse the extra subscripts anyway for error recovery.
        else {
            Error(errTooManySubscripts);
            parseExpression(Icode);
        }
    } while (parserToken == tcComma);

    // ]
    condGetTokenAppend(Icode, tcRBracket, errMissingRightBracket);

    return resultTypeChunk;
}

CHUNKNUM parseTerm(CHUNKNUM Icode)
{
    CHUNKNUM resultChunkNum, operandTypeChunk;
    // TTYPE operandType;
    TTokenCode op;

    // Parse the first factor
    resultChunkNum = parseFactor(Icode);

    // Loop to parse subsequent multiplicative operators and factors
    while (tokenIn(parserToken, tlMulOps)) {
        // Remember the operator and parse subsequent factor
        op = parserToken;
        getTokenAppend(Icode);
        operandTypeChunk = parseFactor(Icode);

        // Check the operand types to determine the result type.
        switch (op) {
            case tcStar:
                // integer * integer => integer
                if (integerOperands(resultChunkNum, operandTypeChunk)) {
                    resultChunkNum = integerType;
                }

                // real    * real    => real
                // real    * integer => real
                // integer * real    => real
                else if (realOperands(resultChunkNum, operandTypeChunk)) {
                    resultChunkNum = realType;
                } else {
                    Error(errIncompatibleTypes);
                }
                break;

            case tcSlash:
                // integer / integer => real
                // real    / real    => real
                // real    / integer => real
                // integer / real    => real
                if (integerOperands(resultChunkNum, operandTypeChunk)
                 || realOperands(resultChunkNum, operandTypeChunk)) {
                    resultChunkNum = realType;
                } else {
                    Error(errIncompatibleTypes);
                }
                break;

            case tcDIV:
            case tcMOD:
                // integer <op> integer => integer
                if (integerOperands(resultChunkNum, operandTypeChunk)) {
                    resultChunkNum = integerType;
                } else {
                    Error(errIncompatibleTypes);
                }
                break;

            case tcAND:
                // boolean AND boolean => boolean
                checkBoolean(resultChunkNum, operandTypeChunk);
                resultChunkNum = booleanType;
                break;
        }
    }

    return resultChunkNum;
}

CHUNKNUM parseVariable(CHUNKNUM Icode, SYMBNODE *pNode) {
    CHUNKNUM resultTypeChunk;
    char doneFlag = 0;

    resultTypeChunk = pNode->node.typeChunk;

    // Check how the variable identifier was defined.
    switch (pNode->defn.how) {
        case dcVariable:
        case dcValueParm:
        case dcVarParm:
        case dcFunction:
        case dcUndefined:
            break;          // OK
        
        default:
            resultTypeChunk = dummyType;
            Error(errInvalidIdentifierUsage);
            break;
    }

    getTokenAppend(Icode);

    // [ or . : Loop to parse any subscripts and fields.
    do {
        switch (parserToken) {
            case tcLBracket:
                resultTypeChunk = parseSubscripts(Icode, resultTypeChunk);
                break;

            case tcPeriod:
                resultTypeChunk = parseField(Icode, resultTypeChunk);
                break;

            default:
                doneFlag = 1;
                break;
        }
    } while (!doneFlag);

    return resultTypeChunk;
}
