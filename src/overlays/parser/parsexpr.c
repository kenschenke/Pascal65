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

CHUNKNUM parseExpression(SCANNER *scanner, CHUNKNUM Icode)
{
    CHUNKNUM resultTypeChunk, operandTypeChunk;

    // Parse the first simple expression
    resultTypeChunk = parseSimpleExpression(scanner, Icode);

    // If we now see a relational operator,
    // parse a second simple expression.
    if (tokenIn(scanner->token.code, tlRelOps)) {
        getTokenAppend(scanner, Icode);
        operandTypeChunk = parseSimpleExpression(scanner, Icode);

        // Check the operand types and return the boolean type.
        checkRelOpOperands(resultTypeChunk, operandTypeChunk);
        resultTypeChunk = booleanType;
    }

    // Make sure the expression ended properly.
    resync(scanner, tlExpressionFollow, tlStatementFollow, tlStatementStart);

    return resultTypeChunk;
}

CHUNKNUM parseFactor(SCANNER *scanner, CHUNKNUM Icode)
{
    int length;
    CHUNKNUM resultTypeChunk;
    SYMBNODE node;

    switch (scanner->token.code) {
        case tcIdentifier:
            // Search for the identifier and enter if necessary.
            // Append the symbol table node handle to the icode.
            symtabStackFind(scanner->token.string, &node);
            putSymtabNodeToIcode(Icode, &node.node);
            if (node.defn.how == dcUndefined) {
                node.defn.how = dcVariable;
                setType(&node.node.typeChunk, dummyType);
                saveSymbNode(&node);
            }

            // Based on how the identifier is defined,
            // parse a constant, function call, or variable.
            switch (node.defn.how) {
                case dcFunction:
                    resultTypeChunk = parseSubroutineCall(scanner, &node, 1, Icode);
                    break;

                case dcProcedure:
                    Error(errInvalidIdentifierUsage);
                    resultTypeChunk = parseSubroutineCall(scanner, &node, 0, Icode);
                    break;

                case dcConstant:
                    getTokenAppend(scanner, Icode);
                    resultTypeChunk = node.node.typeChunk;
                    break;

                default:
                    resultTypeChunk = parseVariable(scanner, Icode, &node);
                    break;
            }

            break;

        case tcNumber:
            // Search for the number and enter it if necessary.
            if (!symtabStackSearchAll(scanner->token.string, &node)) {
                symtabEnterLocal(&node, scanner->token.string, dcUndefined);

                // Determine the number's type and set its value into
                // the symbol table node.
                if (scanner->token.type == tyInteger) {
                    resultTypeChunk = integerType;
                    node.defn.constant.value.integer = scanner->token.value.integer;
                }
                setType(&node.node.typeChunk, resultTypeChunk);
                saveSymbNode(&node);
            }

            // Append the symbol table node handle to the icode.
            putSymtabNodeToIcode(Icode, &node.node);
            resultTypeChunk = node.node.typeChunk;
            getTokenAppend(scanner, Icode);
            break;

        case tcString:
            // Search for the string and enter it if necessary.
            if (!symtabStackSearchAll(scanner->token.string, &node)) {
                symtabEnterLocal(&node, scanner->token.string, dcUndefined);

                // compute the string length (without the quotes).
                // if the length is 1, the result type is character,
                // else create a new string type.
                length = strlen(scanner->token.string) - 2;
                if (length == 1) {
                    resultTypeChunk = charType;
                } else {
                    resultTypeChunk = makeStringType(length);
                    setType(&node.node.typeChunk, resultTypeChunk);
                    saveSymbNode(&node);
                }

                // Set the character value or string value into the symbol table.
                if (length == 1) {
                    node.defn.constant.value.character = scanner->token.string[1];
                } else {
                    copyQuotedString(scanner->token.string, &node.defn.constant.value.stringChunkNum);
                }
                saveSymbNode(&node);
            } else {
                resultTypeChunk = node.node.typeChunk;
            }

            // Append the symbol table node to the icode
            putSymtabNodeToIcode(Icode, &node.node);
            getTokenAppend(scanner, Icode);
            break;

        case tcNOT:
            getTokenAppend(scanner, Icode);
            resultTypeChunk = parseFactor(scanner, Icode);
            checkBoolean(resultTypeChunk, 0);
            break;

        case tcLParen:
            // Parenthesized subexpression: call parseExpression recursively
            getTokenAppend(scanner, Icode);
            resultTypeChunk = parseExpression(scanner, Icode);

            // and check for the closing right parenthesis
            if (scanner->token.code == tcRParen) {
                getTokenAppend(scanner, Icode);
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

CHUNKNUM parseField(SCANNER *scanner, CHUNKNUM Icode, CHUNKNUM recordTypeChunkNum) {
    TTYPE recordType;
    CHUNKNUM varType;
    SYMBNODE fieldId;

    getTokenAppend(scanner, Icode);
    retrieveChunk(recordTypeChunkNum, (unsigned char *)&recordType);

    if (scanner->token.code == tcIdentifier && recordType.form == fcRecord) {
        if (!searchSymtab(recordType.record.symtab, &fieldId, scanner->token.string)) {
            fieldId.node.nodeChunkNum = 0;
            Error(errInvalidField);
        }
        putSymtabNodeToIcode(Icode, &fieldId.node);

        getTokenAppend(scanner, Icode);
        varType = fieldId.node.nodeChunkNum ? fieldId.node.typeChunk : dummyType;
    } else {
        Error(errInvalidField);
        getTokenAppend(scanner, Icode);
        varType = dummyType;
    }

    return varType;
}

CHUNKNUM parseSimpleExpression(SCANNER *scanner, CHUNKNUM Icode)
{
    CHUNKNUM resultTypeChunk, operandTypeChunk;
    TTokenCode op;
    char unaryOpFlag = 0;  // non-zero if unary op

    // Unary + or -
    if (tokenIn(scanner->token.code, tlUnaryOps)) {
        getTokenAppend(scanner, Icode);
        unaryOpFlag = 1;
    }

    // Parse the first term
    resultTypeChunk = parseTerm(scanner, Icode);

    // If there was a unary sign, check the term's type
    if (unaryOpFlag) {
        if (resultTypeChunk != integerType) {
            Error(errIncompatibleTypes);
        }
    }

    // Loop to parse subsequent additive operators and terms
    while (tokenIn(scanner->token.code, tlAddOps)) {
        // Remember the operator and parse the subsequent term.
        op = scanner->token.code;
        getTokenAppend(scanner, Icode);
        operandTypeChunk = parseTerm(scanner, Icode);

        switch (op) {
            case tcPlus:
            case tcMinus:
                // integer <op> integer => integer
                if (integerOperands(resultTypeChunk, operandTypeChunk)) {
                    resultTypeChunk = integerType;
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

CHUNKNUM parseSubscripts(SCANNER *scanner, CHUNKNUM Icode, CHUNKNUM arrayTypeChunk) {
    CHUNKNUM resultTypeChunk, targetTypeChunk;
    TTYPE arrayType;

    retrieveChunk(arrayTypeChunk, (unsigned char *)&arrayType);

    // Loop to parse a list of subscripts separated by commas.
    do {
        // [ (first) or , (subsequent)
        getTokenAppend(scanner, Icode);

        // The current variable is an array type.
        if (arrayType.form == fcArray) {
            // The subscript expression must be an assignment type
            // compatible with the corresponding subscript type.
            targetTypeChunk = parseExpression(scanner, Icode);
            // retrieveChunk(targetTypeChunk, (unsigned char *)&targetType);
            // retrieveChunk(arrayType.array.indexType, (unsigned char *)&indexType);
            checkAssignmentCompatible(arrayType.array.indexType, targetTypeChunk, errIncompatibleTypes);

            // Update the variable's type
            resultTypeChunk = arrayType.array.elemType;
            // retrieveChunk(pType->array.elemType, (unsigned char *)pType);
        }

        // No longer an array type, so too many subscripts.
        // Parse the extra subscripts anyway for error recovery.
        else {
            Error(errTooManySubscripts);
            parseExpression(scanner, Icode);
        }
    } while (scanner->token.code == tcComma);

    // ]
    condGetTokenAppend(scanner, Icode, tcRBracket, errMissingRightBracket);

    return resultTypeChunk;
}

CHUNKNUM parseTerm(SCANNER *scanner, CHUNKNUM Icode)
{
    CHUNKNUM resultChunkNum, operandTypeChunk;
    // TTYPE operandType;
    TTokenCode op;

    // Parse the first factor
    resultChunkNum = parseFactor(scanner, Icode);

    // Loop to parse subsequent multiplicative operators and factors
    while (tokenIn(scanner->token.code, tlMulOps)) {
        // Remember the operator and parse subsequent factor
        op = scanner->token.code;
        getTokenAppend(scanner, Icode);
        operandTypeChunk = parseFactor(scanner, Icode);

        // Check the operand types to determine the result type.
        switch (op) {
            case tcStar:
                // integer * integer => integer
            case tcSlash:
                // integer / integer => integer
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

CHUNKNUM parseVariable(SCANNER *scanner, CHUNKNUM Icode, SYMBNODE *pNode) {
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

    getTokenAppend(scanner, Icode);

    // [ or . : Loop to parse any subscripts and fields.
    do {
        switch (scanner->token.code) {
            case tcLBracket:
                resultTypeChunk = parseSubscripts(scanner, Icode, resultTypeChunk);
                break;

            case tcPeriod:
                resultTypeChunk = parseField(scanner, Icode, resultTypeChunk);
                break;

            default:
                doneFlag = 1;
                break;
        }
    } while (!doneFlag);

    return resultTypeChunk;
}
