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

void parseExpression(SCANNER *scanner, CHUNKNUM Icode, TTYPE *pResultType)
{
    TTYPE operandType;

    // Parse the first simple expression
    parseSimpleExpression(scanner, Icode, pResultType);

    // If we now see a relational operator,
    // parse a second simple expression.
    if (tokenIn(scanner->token.code, tlRelOps)) {
        getTokenAppend(scanner, Icode);
        parseSimpleExpression(scanner, Icode, &operandType);

        // Check the operand types and return the boolean type.
        checkRelOpOperands(pResultType->nodeChunkNum, operandType.nodeChunkNum);
        retrieveChunk(booleanType, (unsigned char *)pResultType);
    }

    // Make sure the expression ended properly.
    resync(scanner, tlExpressionFollow, tlStatementFollow, tlStatementStart);
}

void parseFactor(SCANNER *scanner, CHUNKNUM Icode, TTYPE *pResultType)
{
    DEFN defn;
    int length;
    CHUNKNUM newChunk, resultTypeChunk;
    SYMTABNODE node;

    switch (scanner->token.code) {
        case tcIdentifier:
            // Search for the identifier and enter if necessary.
            // Append the symbol table node handle to the icode.
            symtabStackFind(scanner->token.string, &node);
            putSymtabNodeToIcode(Icode, &node);
            retrieveChunk(node.defnChunk, (unsigned char *)&defn);
            if (defn.how == dcUndefined) {
                defn.how = dcVariable;
                storeChunk(node.defnChunk, (unsigned char *)&defn);
                setType(&node.typeChunk, dummyType);
                storeChunk(node.nodeChunkNum, (unsigned char *)&node);
            }

            // Based on how the identifier is defined,
            // parse a constant, function call, or variable.
            switch (defn.how) {
                case dcFunction:
                    resultTypeChunk = parseSubroutineCall(scanner, &node, 1, Icode);
                    retrieveChunk(resultTypeChunk, (unsigned char *)pResultType);
                    break;

                case dcProcedure:
                    Error(errInvalidIdentifierUsage);
                    resultTypeChunk = parseSubroutineCall(scanner, &node, 0, Icode);
                    retrieveChunk(resultTypeChunk, (unsigned char *)pResultType);
                    break;

                case dcConstant:
                    getTokenAppend(scanner, Icode);
                    resultTypeChunk = node.typeChunk;
                    retrieveChunk(resultTypeChunk, (unsigned char *)pResultType);
                    break;

                default:
                    parseVariable(scanner, Icode, &node, pResultType);
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
                    retrieveChunk(integerType, (unsigned char *)pResultType);
                    retrieveChunk(node.defnChunk, (unsigned char *)&defn);
                    defn.constant.value.integer = scanner->token.value.integer;
                    storeChunk(node.defnChunk, (unsigned char *)&defn);
                }
                setType(&node.typeChunk, pResultType->nodeChunkNum);
                storeChunk(node.nodeChunkNum, (unsigned char *)&node);
            }

            // Append the symbol table node handle to the icode.
            putSymtabNodeToIcode(Icode, &node);
            retrieveChunk(node.typeChunk, (unsigned char *)pResultType);
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
                    retrieveChunk(charType, (unsigned char *)pResultType);
                } else {
                    newChunk = makeStringType(length);
                    setType(&node.typeChunk, newChunk);
                    storeChunk(node.nodeChunkNum, (unsigned char *)&node);
                    retrieveChunk(newChunk, (unsigned char *)pResultType);
                }

                // Set the character value or string value into the symbol table.
                retrieveChunk(node.defnChunk, (unsigned char *)&defn);
                if (length == 1) {
                    defn.constant.value.character = scanner->token.string[1];
                } else {
                    copyQuotedString(scanner->token.string, &defn.constant.value.stringChunkNum);
                }
                storeChunk(node.defnChunk, (unsigned char *)&defn);
            } else {
                retrieveChunk(node.typeChunk, (unsigned char *)pResultType);
            }

            // Append the symbol table node to the icode
            putSymtabNodeToIcode(Icode, &node);
            getTokenAppend(scanner, Icode);
            break;

        case tcNOT:
            getTokenAppend(scanner, Icode);
            parseFactor(scanner, Icode, pResultType);
            checkBoolean(pResultType->nodeChunkNum, 0);
            break;

        case tcLParen:
            // Parenthesized subexpression: call parseExpression recursively
            getTokenAppend(scanner, Icode);
            parseExpression(scanner, Icode, pResultType);

            // and check for the closing right parenthesis
            if (scanner->token.code == tcRParen) {
                getTokenAppend(scanner, Icode);
            } else {
                Error(errMissingRightParen);
            }
            break;

        default:
            Error(errInvalidExpression);
            retrieveChunk(dummyType, (unsigned char *)pResultType);
            break;
    }
}

void parseField(SCANNER *scanner, CHUNKNUM Icode, TTYPE *pType) {
    SYMTABNODE fieldId;

    getTokenAppend(scanner, Icode);

    if (scanner->token.code == tcIdentifier && pType->form == fcRecord) {
        if (!searchSymtab(pType->record.symtab, &fieldId, scanner->token.string)) {
            fieldId.nodeChunkNum = 0;
            Error(errInvalidField);
        }
        putSymtabNodeToIcode(Icode, &fieldId);

        getTokenAppend(scanner, Icode);
        retrieveChunk(fieldId.nodeChunkNum ? fieldId.typeChunk : dummyType,
            (unsigned char *)pType);
    } else {
        Error(errInvalidField);
        getTokenAppend(scanner, Icode);
        retrieveChunk(dummyType, (unsigned char *)pType);
    }
}

void parseSimpleExpression(SCANNER *scanner, CHUNKNUM Icode, TTYPE *pResultType)
{
    TTYPE operandType;
    TTokenCode op;
    char unaryOpFlag = 0;  // non-zero if unary op

    // Unary + or -
    if (tokenIn(scanner->token.code, tlUnaryOps)) {
        getTokenAppend(scanner, Icode);
        unaryOpFlag = 1;
    }

    // Parse the first term
    parseTerm(scanner, Icode, pResultType);

    // If there was a unary sign, check the term's type
    if (unaryOpFlag) {
        if (pResultType->nodeChunkNum != integerType) {
            Error(errIncompatibleTypes);
        }
    }

    // Loop to parse subsequent additive operators and terms
    while (tokenIn(scanner->token.code, tlAddOps)) {
        // Remember the operator and pae the subsequent term.
        op = scanner->token.code;
        getTokenAppend(scanner, Icode);
        parseTerm(scanner, Icode, &operandType);

        switch (op) {
            case tcPlus:
            case tcMinus:
                // integer <op> integer => integer
                if (integerOperands(pResultType->nodeChunkNum, operandType.nodeChunkNum)) {
                    retrieveChunk(integerType, (unsigned char *)pResultType);
                } else {
                    Error(errIncompatibleTypes);
                }
                break;

            case tcOR:
                // boolean OR boolean => boolean
                checkBoolean(pResultType->nodeChunkNum, operandType.nodeChunkNum);
                retrieveChunk(booleanType, (unsigned char *)pResultType);
                break;
        }
    }
}

void parseSubscripts(SCANNER *scanner, CHUNKNUM Icode, TTYPE *pType) {
    TTYPE indexType, targetType;

    // Loop to parse a list of subscripts separated by commas.
    do {
        // [ (first) or , (subsequent)
        getTokenAppend(scanner, Icode);

        // The current variable is an array type.
        if (pType->form == fcArray) {
            // The subscript expression must be an assignment type
            // compatible with the corresponding subscript type.
            parseExpression(scanner, Icode, &targetType);
            retrieveChunk(pType->array.indexType, (unsigned char *)&indexType);
            checkAssignmentCompatible(&indexType, &targetType, errIncompatibleTypes);

            // Update the variable's type
            retrieveChunk(pType->array.elemType, (unsigned char *)pType);
        }

        // No longer an array type, so too many subscripts.
        // Parse the extra subscripts anyway for error recovery.
        else {
            Error(errTooManySubscripts);
            parseExpression(scanner, Icode, &targetType);
        }
    } while (scanner->token.code == tcComma);

    // ]
    condGetTokenAppend(scanner, Icode, tcRBracket, errMissingRightBracket);
}

void parseTerm(SCANNER *scanner, CHUNKNUM Icode, TTYPE *pResultType)
{
    TTYPE operandType;
    TTokenCode op;

    // Parse the first factor
    parseFactor(scanner, Icode, pResultType);

    // Loop to parse subsequent multiplicative operators and factors
    while (tokenIn(scanner->token.code, tlMulOps)) {
        // Remember the operator and parse subsequent factor
        op = scanner->token.code;
        getTokenAppend(scanner, Icode);
        parseFactor(scanner, Icode, &operandType);

        // Check the operand types to determine the result type.
        switch (op) {
            case tcStar:
                // integer * integer => integer
            case tcSlash:
                // integer / integer => integer
            case tcDIV:
            case tcMOD:
                // integer <op> integer => integer
                if (integerOperands(pResultType->nodeChunkNum, operandType.nodeChunkNum)) {
                    retrieveChunk(integerType, (unsigned char *)pResultType);
                } else {
                    Error(errIncompatibleTypes);
                }
                break;

            case tcAND:
                // boolean AND boolean => boolean
                checkBoolean(pResultType->nodeChunkNum, operandType.nodeChunkNum);
                retrieveChunk(booleanType, (unsigned char *)pResultType);
                break;
        }
    }
}

void parseVariable(SCANNER *scanner, CHUNKNUM Icode, SYMTABNODE *pNode, TTYPE *pResultType) {
    DEFN defn;
    char doneFlag = 0;

    retrieveChunk(pNode->typeChunk, (unsigned char *)pResultType);
    retrieveChunk(pNode->defnChunk, (unsigned char *)&defn);

    // Check how the variable identifier was defined.
    switch (defn.how) {
        case dcVariable:
        case dcValueParm:
        case dcVarParm:
        case dcFunction:
        case dcUndefined:
            break;          // OK
        
        default:
            retrieveChunk(dummyType, (unsigned char *)&pResultType);
            Error(errInvalidIdentifierUsage);
            break;
    }

    getTokenAppend(scanner, Icode);

    // [ or . : Loop to parse any subscripts and fields.
    do {
        switch (scanner->token.code) {
            case tcLBracket:
                parseSubscripts(scanner, Icode, pResultType);
                break;

            case tcPeriod:
                parseField(scanner, Icode, pResultType);
                break;

            default:
                doneFlag = 1;
                break;
        }
    } while (!doneFlag);
}
