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
    int value;
    CHUNKNUM exprTypeChunk, caseItems;
    char caseBranchFlag;  // true if another CASE branch, else false
    MEMBUF_LOCN locnFollow, locnBranchTable, locnBranchStmt;

    allocMemBuf(&caseItems);

    putLocationMarker(Icode, &locnFollow);
    putLocationMarker(Icode, &locnBranchTable);

    // <expr>
    getTokenAppend(Icode);
    exprTypeChunk = parseExpression(Icode);
    retrieveChunk(exprTypeChunk, (unsigned char *)&exprType);
    exprTypeChunk = getBaseType(&exprType);

    // Verify the type of the case expression
    if (exprTypeChunk != integerType &&
        exprTypeChunk != charType &&
        exprType.form != fcEnum) {
        Error(errIncompatibleTypes);
    }

    // OF
    resync(tlOF, tlCaseLabelStart, NULL);
    condGetTokenAppend(Icode, tcOF, errMissingOF);

    // Loop to parse CASE branches
    caseBranchFlag = tokenIn(tokenCode, tlCaseLabelStart);
    while (caseBranchFlag) {
        if (tokenIn(tokenCode, tlCaseLabelStart)) parseCaseBranch(Icode, exprTypeChunk, caseItems);

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

    // Append the branch table to the intermediate code.
    fixupLocationMarker(Icode, &locnBranchTable);

    /**
     * At this point the case items buffer contains a list of case labels
     * and Icode locations for their branch's code.  The code needs to loop
     * through the buffer and write the items to the ICode then destroy the
     * buffer.  A "zero" value needs to be written at the end of the items table.
     */

    setMemBufPos(caseItems, 0);
    while (!isMemBufAtEnd(caseItems)) {
        getCaseItem(caseItems, &value, &locnBranchStmt);
        putCaseItem(Icode, value, &locnBranchStmt);
    }
    freeMemBuf(caseItems);
    putCaseItem(Icode, 0, NULL);

    // END
    resync(tlEND, tlStatementStart, NULL);
    condGetTokenAppend(Icode, tcEND, errMissingEND);
    fixupLocationMarker(Icode, &locnFollow);
}

void parseCaseBranch(CHUNKNUM Icode, CHUNKNUM exprTypeChunk, CHUNKNUM caseItems) {
    char caseLabelFlag;  // true if another CASE label, else false
    MEMBUF_LOCN locn, stmtLocn;
    unsigned thisLocn;
    int value;

    // <case-label-list>
    do {
        parseCaseLabel(Icode, exprTypeChunk, caseItems);
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

    /**
     * The code needs to loop through the items in the case item buffer
     * and fill in the current ICode location for each item with a
     * "zero" location.  These were just added while parsing the labels
     * for the current branch.
     */

    getMemBufLocn(Icode, &stmtLocn);
    setMemBufPos(caseItems, 0);
    while (!isMemBufAtEnd(caseItems)) {
        thisLocn = getMemBufPos(caseItems) + sizeof(int);
        getCaseItem(caseItems, &value, &locn);
        if (locn.chunkNum == 0) {
            setMemBufPos(caseItems, thisLocn);
            writeToMemBuf(caseItems, &stmtLocn, sizeof(MEMBUF_LOCN));
        }
    }

    // <stmt>
    parseStatement(Icode);
}

void parseCaseLabel(CHUNKNUM Icode, CHUNKNUM exprTypeChunk, CHUNKNUM caseItems) {
    char signFlag = 0;  // true if unary sign, else false
    int value;
    TTYPE labelType;
    SYMBNODE node;
    MEMBUF_LOCN locn;

    memset(&locn, 0, sizeof(MEMBUF_LOCN));

    // Unary + or -
    if (tokenIn(tokenCode, tlUnaryOps)) {
        signFlag = 1;
        getTokenAppend(Icode);
    }

    /**
     * This function is called for each "label" in a case branch.
     * i.e. Case 5, 6, 7:
     * 
     * It needs to parse the label and add an item to the caseItems buffer.
     * The item will have a zero location because the code does not yet know
     * the ICode location for the end of the case label.
     */

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

            // Set the label value into the CASE item
            if (labelType.nodeChunkNum == integerType ||
                labelType.form == fcEnum) {
                value = signFlag ?
                    -node.defn.constant.value.integer :
                    node.defn.constant.value.integer;
            } else {
                value = node.defn.constant.value.character;
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

            // Set the label value into the CASE item
            value = signFlag ?
                -node.defn.constant.value.integer :
                node.defn.constant.value.integer;

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

            // Set the label value into the CASE item
            value = tokenString[1];

            getTokenAppend(Icode);
            break;
    }

    putCaseItem(caseItems, value, &locn);
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
    MEMBUF_LOCN locn;

    putLocationMarker(Icode, &locn);

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
    fixupLocationMarker(Icode, &locn);
}

void parseIF(CHUNKNUM Icode) {
    CHUNKNUM resultType;
    MEMBUF_LOCN falseLocn, followLocn;

    // Append a placeholder location marker for where to go to if
    // <expr> is false and another marker for the statement following
    // the IF statement
    putLocationMarker(Icode, &falseLocn);
    putLocationMarker(Icode, &followLocn);

    // <expr> : must be boolean
    getTokenAppend(Icode);
    resultType = parseExpression(Icode);
    checkBoolean(resultType, 0);

    // THEN
    resync(tlTHEN, tlStatementStart, NULL);
    condGetTokenAppend(Icode, tcTHEN, errMissingTHEN);

    // <stmt-1>
    parseStatement(Icode);
    fixupLocationMarker(Icode, &falseLocn);

    if (tokenCode == tcELSE) {
        // Append a placeholder location marker for the token that
        // follows the IF statement. Remember the location of this
        // placeholder so it can be fixed up later.

        // ELSE <stmt-2>
        getTokenAppend(Icode);
        parseStatement(Icode);
        fixupLocationMarker(Icode, &followLocn);
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
                parseSubroutineCall(node.node.nodeChunkNum, 1, Icode);
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
    MEMBUF_LOCN locn;
    putLocationMarker(Icode, &locn);

    // Append a placeholder location marker for the token that
    // follows the WHILE statement. Remember the location of this
    // placeholder so it can be fixed up below.

    // <expr> : must be boolean
    getTokenAppend(Icode);
    resultType = parseExpression(Icode);
    checkBoolean(resultType, 0);

    // DO
    resync(tlDO, tlStatementStart, NULL);
    condGetTokenAppend(Icode, tcDO, errMissingDO);

    // <stmt>
    parseStatement(Icode);
    fixupLocationMarker(Icode, &locn);
}


