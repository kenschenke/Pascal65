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

void parseAssignment(SCANNER *scanner, SYMTABNODE *pTargetNode, CHUNKNUM Icode)
{
    DEFN defn;
    TTYPE exprType, targetType;

    parseVariable(scanner, Icode, pTargetNode, &targetType);

    // :=
    resync(scanner, tlColonEqual, tlExpressionStart, NULL);
    condGetTokenAppend(scanner, Icode, tcColonEqual, errMissingColonEqual);

    // <expr>
    parseExpression(scanner, Icode, &exprType);

    // Check for assignment compatibility
    checkAssignmentCompatible(&targetType, &exprType, errIncompatibleAssignment);
}

void parseCASE(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE exprType;
    char caseBranchFlag;  // true if another CASE branch, else false

    // <expr>
    getTokenAppend(scanner, Icode);
    parseExpression(scanner, Icode, &exprType);
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
    resync(scanner, tlOF, tlCaseLabelStart, NULL);
    condGetTokenAppend(scanner, Icode, tcOF, errMissingOF);

    // Loop to parse CASE branches
    caseBranchFlag = tokenIn(scanner->token.code, tlCaseLabelStart);
    while (caseBranchFlag) {
        if (tokenIn(scanner->token.code, tlCaseLabelStart)) parseCaseBranch(scanner, Icode, &exprType);

        if (scanner->token.code == tcSemicolon) {
            getTokenAppend(scanner, Icode);
            caseBranchFlag = 1;
        } else if (tokenIn(scanner->token.code, tlCaseLabelStart)) {
            Error(errMissingSemicolon);
            caseBranchFlag = 1;
        } else {
            caseBranchFlag = 0;
        }
    }

    // END
    resync(scanner, tlEND, tlStatementStart, NULL);
    condGetTokenAppend(scanner, Icode, tcEND, errMissingEND);
}

void parseCaseBranch(SCANNER *scanner, CHUNKNUM Icode, TTYPE *pExprType) {
    char caseLabelFlag;  // true if another CASE label, else false

    // <case-label-list>
    do {
        parseCaseLabel(scanner, Icode, pExprType);
        if (scanner->token.code == tcComma) {
            // Saw comma, look for another CASE label
            getTokenAppend(scanner, Icode);
            if (tokenIn(scanner->token.code, tlCaseLabelStart)) caseLabelFlag = 1;
            else {
                Error(errMissingConstant);
                caseLabelFlag = 0;
            }
        } else {
            caseLabelFlag = 0;
        }
    } while (caseLabelFlag);

    // :
    resync(scanner, tlColon, tlStatementStart, NULL);
    condGetTokenAppend(scanner, Icode, tcColon, errMissingColon);

    // <stmt>
    parseStatement(scanner, Icode);
}

void parseCaseLabel(SCANNER *scanner, CHUNKNUM Icode, TTYPE *pExprType) {
    char signFlag = 0;  // true if unary sign, else false
    DEFN defn;
    TTYPE labelType;
    SYMTABNODE node;

    // Unary + or -
    if (tokenIn(scanner->token.code, tlUnaryOps)) {
        signFlag = 1;
        getTokenAppend(scanner, Icode);
    }

    switch (scanner->token.code) {
        // Identifier
        case tcIdentifier:
            if (!symtabStackSearchAll(scanner->token.string, &node)) {
                Error(errUndefinedIdentifier);
            }
            retrieveChunk(node.typeChunk, (unsigned char *)&labelType);
            putSymtabNodeToIcode(Icode, &node);

            retrieveChunk(node.defnChunk, (unsigned char *)&defn);
            if (defn.how != dcUndefined) {
                if (labelType.form == fcSubrange && labelType.subrange.baseType) {
                    retrieveChunk(labelType.subrange.baseType, (unsigned char *)&labelType);
                }
            } else {
                defn.how = dcConstant;
                setType(&node.typeChunk, dummyType);
                storeChunk(node.nodeChunkNum, (unsigned char *)&node);
                retrieveChunk(dummyType, (unsigned char *)&labelType);
            }

            if (pExprType->nodeChunkNum != labelType.nodeChunkNum) {
                Error(errIncompatibleTypes);
            }

            // Only an integer constant can have a unary sign
            if (signFlag && labelType.nodeChunkNum != integerType) {
                Error(errInvalidConstant);
            }

            getTokenAppend(scanner, Icode);
            break;

        // Number - Both the label and the CASE expression must be an integer.
        case tcNumber:
            if (scanner->token.type != tyInteger) Error(errInvalidConstant);
            if (pExprType->nodeChunkNum != integerType) Error(errIncompatibleTypes);

            if (!symtabStackSearchAll(scanner->token.string, &node)) {
                symtabEnterLocal(&node, scanner->token.string, dcUndefined);
                setType(&node.typeChunk, integerType);
                storeChunk(node.nodeChunkNum, (unsigned char *)&node);
                retrieveChunk(node.defnChunk, (unsigned char *)&defn);
                defn.constant.value.integer = scanner->token.value.integer;
                storeChunk(node.defnChunk, (unsigned char *)&defn);
            }
            putSymtabNodeToIcode(Icode, &node);

            getTokenAppend(scanner, Icode);
            break;
        
        // String - must be a single character without a unary sign
        case tcString:
            if (signFlag || strlen(scanner->token.string) != 3) {
                Error(errInvalidConstant);
            }
            if (pExprType->nodeChunkNum != charType) Error(errIncompatibleTypes);

            if (!symtabStackSearchAll(scanner->token.string, &node)) {
                symtabEnterNewLocal(&node, scanner->token.string, dcUndefined);
                setType(&node.typeChunk, charType);
                storeChunk(node.nodeChunkNum, (unsigned char *)&node);
                retrieveChunk(node.defnChunk, (unsigned char *)&defn);
                defn.constant.value.character = scanner->token.string[1];
                storeChunk(node.defnChunk, (unsigned char *)&defn);
            }
            putSymtabNodeToIcode(Icode, &node);

            getTokenAppend(scanner, Icode);
            break;
    }
}

void parseCompound(SCANNER *scanner, CHUNKNUM Icode) {
    getTokenAppend(scanner, Icode);

    // <stmt-list>
    parseStatementList(scanner, Icode, tcEND);

    condGetTokenAppend(scanner, Icode, tcEND, errMissingEND);
}

void parseFOR(SCANNER *scanner, CHUNKNUM Icode) {
    DEFN defn;
    TTYPE controlType, exprType, expr2Type;
    SYMTABNODE node, typeNode;

    // <id>
    getTokenAppend(scanner, Icode);
    if (scanner->token.code == tcIdentifier) {
        // Verify the definition and type of the control id
        symtabStackFind(scanner->token.string, &node);
        retrieveChunk(node.defnChunk, (unsigned char *)&defn);
        retrieveChunk(node.typeChunk, (unsigned char *)&controlType);
        if (defn.how != dcUndefined) {
            if (controlType.form == fcSubrange && controlType.subrange.baseType) {
                retrieveChunk(controlType.subrange.baseType, (unsigned char *)&controlType);
            }
        } else {
            defn.how = dcVariable;
            storeChunk(node.defnChunk, (unsigned char *)&defn);
            retrieveChunk(integerType, (unsigned char *)&controlType);
            node.typeChunk = integerType;
            storeChunk(node.nodeChunkNum, (unsigned char *)&node);
        }
        if (controlType.nodeChunkNum != integerType &&
            controlType.nodeChunkNum != charType &&
            controlType.form != fcEnum) {
            Error(errIncompatibleTypes);
            retrieveChunk(integerType, (unsigned char *)&controlType);
        }

        putSymtabNodeToIcode(Icode, &node);
        getTokenAppend(scanner, Icode);
    } else {
        Error(errMissingIdentifier);
    }

    // :=
    resync(scanner, tlColonEqual, tlExpressionStart, NULL);
    condGetTokenAppend(scanner, Icode, tcColonEqual, errMissingColonEqual);

    // <expr-1>
    parseExpression(scanner, Icode, &exprType);
    checkAssignmentCompatible(&controlType, &exprType, errIncompatibleTypes);

    // TO or DOWNTO
    resync(scanner, tlTODOWNTO, tlExpressionStart, NULL);
    if (tokenIn(scanner->token.code, tlTODOWNTO)) getTokenAppend(scanner, Icode);
    else Error(errMissingTOorDOWNTO);

    // <expr-2>
    parseExpression(scanner, Icode, &expr2Type);
    checkAssignmentCompatible(&controlType, &expr2Type, errIncompatibleTypes);

    // DO
    resync(scanner, tlDO, tlStatementStart, NULL);
    condGetTokenAppend(scanner, Icode, tcDO, errMissingDO);

    // <stmt>
    parseStatement(scanner, Icode);
}

void parseIF(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE resultType;

    // <expr>
    getTokenAppend(scanner, Icode);
    parseExpression(scanner, Icode, &resultType);
    checkBoolean(resultType.nodeChunkNum, 0);

    // THEN
    resync(scanner, tlTHEN, tlStatementStart, NULL);
    condGetTokenAppend(scanner, Icode, tcTHEN, errMissingTHEN);

    // <stmt-1>
    parseStatement(scanner, Icode);

    if (scanner->token.code == tcELSE) {
        // ELSE <stmt-2>
        getTokenAppend(scanner, Icode);
        parseStatement(scanner, Icode);
    }
    // exit(0);
}

void parseREPEAT(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE resultType;

    getTokenAppend(scanner, Icode);

    // <stmt-list>
    parseStatementList(scanner, Icode, tcUNTIL);

    // UNTIL
    condGetTokenAppend(scanner, Icode, tcUNTIL, errMissingUNTIL);

    // <expr>
    insertLineMarker(Icode);
    parseExpression(scanner, Icode, &resultType);
    checkBoolean(resultType.nodeChunkNum, 0);
}

void parseStatement(SCANNER *scanner, CHUNKNUM Icode)
{
    DEFN defn;
    SYMTABNODE node;

    insertLineMarker(Icode);

    // Call the appropriate parsing function based on
    // the statement's first token.
    switch (scanner->token.code) {
        case tcIdentifier:
            // Search for the identifier and enter it if
            // necessary.  Append the symbol table node handle
            // to the icode.
            findSymtabNode(&node, scanner->token.string);
            putSymtabNodeToIcode(Icode, &node);

            // Based on how the identifier is defined,
            // parse an assignment statement or procedure call.
            retrieveChunk(node.defnChunk, (unsigned char *)&defn);
            if (defn.how == dcUndefined) {
                defn.how = dcVariable;
                storeChunk(node.defnChunk, (unsigned char *)&defn);
                setType(&node.typeChunk, dummyType);
                storeChunk(node.nodeChunkNum, (unsigned char *)&node);
                parseAssignment(scanner, &node, Icode);
            } else if (defn.how == dcProcedure) {
                parseSubroutineCall(scanner, &node, 1, Icode);
            } else {
                parseAssignment(scanner, &node, Icode);
            }
            break;

        case tcREPEAT: parseREPEAT(scanner, Icode); break;
        case tcWHILE: parseWHILE(scanner, Icode); break;
        case tcIF: parseIF(scanner, Icode); break;
        case tcFOR: parseFOR(scanner, Icode); break;
        case tcCASE: parseCASE(scanner, Icode); break;
        case tcBEGIN: parseCompound(scanner, Icode); break;
    }

    // Resync at a proper statement ending
    if (scanner->token.code != tcEndOfFile) {
        resync(scanner, tlStatementFollow, tlStatementStart, NULL);
    }
}

void parseStatementList(SCANNER *scanner, CHUNKNUM Icode, TTokenCode terminator) {
    // Loop to parse statements and to check for and skip semicolons

    do {
        parseStatement(scanner, Icode);

        if (tokenIn(scanner->token.code, tlStatementStart)) {
            Error(errMissingSemicolon);
        } else if (tokenIn(scanner->token.code, tlStatementListNotAllowed)) {
            Error(errUnexpectedToken);
        } else while (scanner->token.code == tcSemicolon) {
            getTokenAppend(scanner, Icode);
        }
    } while (scanner->token.code != terminator && scanner->token.code != tcEndOfFile);
}

void parseWHILE(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE resultType;

    // <expr>
    getTokenAppend(scanner, Icode);
    parseExpression(scanner, Icode, &resultType);
    checkBoolean(resultType.nodeChunkNum, 0);

    // DO
    resync(scanner, tlDO, tlStatementStart, NULL);
    condGetTokenAppend(scanner, Icode, tcDO, errMissingDO);

    // <stmt>
    parseStatement(scanner, Icode);
}


