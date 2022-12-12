/**
 * parsstmt.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for parsing statements.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <error.h>
#include <icode.h>
#include <parscommon.h>
#include <string.h>

void parseAssignment(SYMBNODE *pTargetNode, CHUNKNUM Icode)
{
    CHUNKNUM exprTypeChunk, targetTypeChunk;

    targetTypeChunk = parseVariable(Icode, pTargetNode);

    // :=
    resync(tlColonEqual, tlExpressionStart, NULL);
    condGetTokenAppend(Icode, tcColonEqual, errMissingColonEqual);

    // <expr>
    exprTypeChunk = parseExpression(Icode);

    // Check for assignment compatibility
    checkAssignmentCompatible(targetTypeChunk, exprTypeChunk, errIncompatibleAssignment);
}

void parseCASE(CHUNKNUM Icode) {
    TTYPE exprType;
    CHUNKNUM exprTypeChunk;
    char caseBranchFlag;  // true if another CASE branch, else false

    // <expr>
    getTokenAppend(Icode);
    exprTypeChunk = parseExpression(Icode);
    retrieveChunk(exprTypeChunk, (unsigned char *)&exprType);
    if (exprType.form == fcSubrange && exprType.subrange.baseType) {
        retrieveChunk(exprType.subrange.baseType, (unsigned char *)&exprType);
    }

    // Verify the type of the case expression
    if (exprType.nodeChunkNum != integerType &&
        exprType.nodeChunkNum != charType &&
        exprType.form != fcEnum) {
        Error(errIncompatibleTypes);
    }

    // OF
    resync(tlOF, tlCaseLabelStart, NULL);
    condGetTokenAppend(Icode, tcOF, errMissingOF);

    // Loop to parse CASE branches
    caseBranchFlag = tokenIn(tokenCode, tlCaseLabelStart);
    while (caseBranchFlag) {
        if (tokenIn(tokenCode, tlCaseLabelStart)) parseCaseBranch(Icode, exprTypeChunk);

        if (tokenCode == tcSemicolon) {
            getTokenAppend(Icode);
            caseBranchFlag = 1;
        } else if (tokenIn(tokenCode, tlCaseLabelStart)) {
            Error(errMissingSemicolon);
            caseBranchFlag = 1;
        } else {
            caseBranchFlag = 0;
        }
    }

    // END
    resync(tlEND, tlStatementStart, NULL);
    condGetTokenAppend(Icode, tcEND, errMissingEND);
}

void parseCaseBranch(CHUNKNUM Icode, CHUNKNUM exprTypeChunk) {
    char caseLabelFlag;  // true if another CASE label, else false

    // <case-label-list>
    do {
        parseCaseLabel(Icode, exprTypeChunk);
        if (tokenCode == tcComma) {
            // Saw comma, look for another CASE label
            getTokenAppend(Icode);
            if (tokenIn(tokenCode, tlCaseLabelStart)) caseLabelFlag = 1;
            else {
                Error(errMissingConstant);
                caseLabelFlag = 0;
            }
        } else {
            caseLabelFlag = 0;
        }
    } while (caseLabelFlag);

    // :
    resync(tlColon, tlStatementStart, NULL);
    condGetTokenAppend(Icode, tcColon, errMissingColon);

    // <stmt>
    parseStatement(Icode);
}

void parseCaseLabel(CHUNKNUM Icode, CHUNKNUM exprTypeChunk) {
    char signFlag = 0;  // true if unary sign, else false
    TTYPE labelType;
    SYMBNODE node;

    // Unary + or -
    if (tokenIn(tokenCode, tlUnaryOps)) {
        signFlag = 1;
        getTokenAppend(Icode);
    }

    switch (tokenCode) {
        // Identifier
        case tcIdentifier:
            if (!symtabStackSearchAll(tokenString, &node)) {
                Error(errUndefinedIdentifier);
            }
            retrieveChunk(node.node.typeChunk, (unsigned char *)&labelType);
            putSymtabNodeToIcode(Icode, &node);

            if (node.defn.how != dcUndefined) {
                if (labelType.form == fcSubrange && labelType.subrange.baseType) {
                    retrieveChunk(labelType.subrange.baseType, (unsigned char *)&labelType);
                }
            } else {
                node.defn.how = dcConstant;
                setType(&node.node.typeChunk, dummyType);
                saveSymbNode(&node);
                retrieveChunk(dummyType, (unsigned char *)&labelType);
            }

            if (exprTypeChunk != labelType.nodeChunkNum) {
                Error(errIncompatibleTypes);
            }

            // Only an integer constant can have a unary sign
            if (signFlag && labelType.nodeChunkNum != integerType) {
                Error(errInvalidConstant);
            }

            getTokenAppend(Icode);
            break;

        // Number - Both the label and the CASE expression must be an integer.
        case tcNumber:
            if (tokenType != tyInteger) Error(errInvalidConstant);
            if (exprTypeChunk != integerType) Error(errIncompatibleTypes);

            if (!symtabStackSearchAll(tokenString, &node)) {
                symtabEnterLocal(&node, tokenString, dcUndefined);
                setType(&node.node.typeChunk, integerType);
                node.defn.constant.value.integer = tokenValue.integer;
                saveSymbNode(&node);
            }
            putSymtabNodeToIcode(Icode, &node);

            getTokenAppend(Icode);
            break;
        
        // String - must be a single character without a unary sign
        case tcString:
            if (signFlag || strlen(tokenString) != 3) {
                Error(errInvalidConstant);
            }
            if (exprTypeChunk != charType) Error(errIncompatibleTypes);

            if (!symtabStackSearchAll(tokenString, &node)) {
                symtabEnterNewLocal(&node, tokenString, dcUndefined);
                setType(&node.node.typeChunk, charType);
                node.defn.constant.value.character = tokenString[1];
                saveSymbNode(&node);
            }
            putSymtabNodeToIcode(Icode, &node);

            getTokenAppend(Icode);
            break;
    }
}

void parseCompound(CHUNKNUM Icode) {
    getTokenAppend(Icode);

    // <stmt-list>
    parseStatementList(Icode, tcEND);

    condGetTokenAppend(Icode, tcEND, errMissingEND);
}

void parseFOR(CHUNKNUM Icode) {
    CHUNKNUM exprTypeChunk, expr2TypeChunk;
    TTYPE controlType;
    SYMBNODE node;

    // <id>
    getTokenAppend(Icode);
    if (tokenCode == tcIdentifier) {
        // Verify the definition and type of the control id
        symtabStackFind(tokenString, &node);
        memcpy(&controlType, &node.type, sizeof(TTYPE));
        if (node.defn.how != dcUndefined) {
            if (controlType.form == fcSubrange && controlType.subrange.baseType) {
                retrieveChunk(controlType.subrange.baseType, (unsigned char *)&controlType);
            }
        } else {
            node.defn.how = dcVariable;
            retrieveChunk(integerType, (unsigned char *)&controlType);
            node.node.typeChunk = integerType;
            saveSymbNode(&node);
        }
        if (controlType.nodeChunkNum != integerType &&
            controlType.nodeChunkNum != charType &&
            controlType.form != fcEnum) {
            Error(errIncompatibleTypes);
            retrieveChunk(integerType, (unsigned char *)&controlType);
        }

        putSymtabNodeToIcode(Icode, &node);
        getTokenAppend(Icode);
    } else {
        Error(errMissingIdentifier);
    }

    // :=
    resync(tlColonEqual, tlExpressionStart, NULL);
    condGetTokenAppend(Icode, tcColonEqual, errMissingColonEqual);

    // <expr-1>
    exprTypeChunk = parseExpression(Icode);
    checkAssignmentCompatible(node.node.typeChunk, exprTypeChunk, errIncompatibleTypes);

    // TO or DOWNTO
    resync(tlTODOWNTO, tlExpressionStart, NULL);
    if (tokenIn(tokenCode, tlTODOWNTO)) getTokenAppend(Icode);
    else Error(errMissingTOorDOWNTO);

    // <expr-2>
    expr2TypeChunk = parseExpression(Icode);
    checkAssignmentCompatible(controlType.nodeChunkNum, expr2TypeChunk, errIncompatibleTypes);

    // DO
    resync(tlDO, tlStatementStart, NULL);
    condGetTokenAppend(Icode, tcDO, errMissingDO);

    // <stmt>
    parseStatement(Icode);
}

void parseIF(CHUNKNUM Icode) {
    CHUNKNUM resultType;

    // <expr>
    getTokenAppend(Icode);
    resultType = parseExpression(Icode);
    checkBoolean(resultType, 0);

    // THEN
    resync(tlTHEN, tlStatementStart, NULL);
    condGetTokenAppend(Icode, tcTHEN, errMissingTHEN);

    // <stmt-1>
    parseStatement(Icode);

    if (tokenCode == tcELSE) {
        // ELSE <stmt-2>
        getTokenAppend(Icode);
        parseStatement(Icode);
    }
}

void parseREPEAT(CHUNKNUM Icode) {
    CHUNKNUM resultType;

    getTokenAppend(Icode);

    // <stmt-list>
    parseStatementList(Icode, tcUNTIL);

    // UNTIL
    condGetTokenAppend(Icode, tcUNTIL, errMissingUNTIL);

    // <expr>
    insertLineMarker(Icode);
    resultType = parseExpression(Icode);
    checkBoolean(resultType, 0);
}

void parseStatement(CHUNKNUM Icode)
{
    SYMBNODE node;

    insertLineMarker(Icode);

    // Call the appropriate parsing function based on
    // the statement's first token.
    switch (tokenCode) {
        case tcIdentifier:
            // Search for the identifier and enter it if
            // necessary.  Append the symbol table node handle
            // to the icode.
            findSymtabNode(&node, tokenString);
            putSymtabNodeToIcode(Icode, &node);

            // Based on how the identifier is defined,
            // parse an assignment statement or procedure call.
            if (node.defn.how == dcUndefined) {
                node.defn.how = dcVariable;
                setType(&node.node.typeChunk, dummyType);
                saveSymbNode(&node);
                parseAssignment(&node, Icode);
            } else if (node.defn.how == dcProcedure) {
                parseSubroutineCall(&node, 1, Icode);
            } else {
                parseAssignment(&node, Icode);
            }
            break;

        case tcREPEAT: parseREPEAT(Icode); break;
        case tcWHILE: parseWHILE(Icode); break;
        case tcIF: parseIF(Icode); break;
        case tcFOR: parseFOR(Icode); break;
        case tcCASE: parseCASE(Icode); break;
        case tcBEGIN: parseCompound(Icode); break;
    }

    // Resync at a proper statement ending
    if (tokenCode != tcEndOfFile) {
        resync(tlStatementFollow, tlStatementStart, NULL);
    }
}

void parseStatementList(CHUNKNUM Icode, TTokenCode terminator) {
    // Loop to parse statements and to check for and skip semicolons

    do {
        parseStatement(Icode);

        if (tokenIn(tokenCode, tlStatementStart)) {
            Error(errMissingSemicolon);
        } else if (tokenIn(tokenCode, tlStatementListNotAllowed)) {
            Error(errUnexpectedToken);
        } else while (tokenCode == tcSemicolon) {
            getTokenAppend(Icode);
        }
    } while (tokenCode != terminator && tokenCode != tcEndOfFile);
}

void parseWHILE(CHUNKNUM Icode) {
    CHUNKNUM resultType;

    // <expr>
    getTokenAppend(Icode);
    resultType = parseExpression(Icode);
    checkBoolean(resultType, 0);

    // DO
    resync(tlDO, tlStatementStart, NULL);
    condGetTokenAppend(Icode, tcDO, errMissingDO);

    // <stmt>
    parseStatement(Icode);
}


