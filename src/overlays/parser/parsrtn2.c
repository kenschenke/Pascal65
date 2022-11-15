#include <string.h>
#include <common.h>
#include <symtab.h>
#include <parser.h>
#include <parscommon.h>

void parseFormalParmList(SCANNER *scanner, CHUNKNUM *pParmList, int *parmCount, int *totalParmSize) {
    SYMBNODE node;
    CHUNKNUM firstId, lastId, parmId;
    CHUNKNUM prevSublistLastId = 0;
    CHUNKNUM parmType;
    TDefnCode parmDefn;

    *pParmList = 0;
    *parmCount = *totalParmSize = 0;
    getToken(scanner);

    // Loop to parse parameter declarations separated by semicolons
    while (scanner->token.code == tcIdentifier || scanner->token.code == tcVAR) {
        parmType = 0;
        firstId = 0;

        // VAR or value parameter?
        if (scanner->token.code == tcVAR) {
            parmDefn = dcVarParm;
            getToken(scanner);
        } else {
            parmDefn = dcValueParm;
        }

        // Loop to parse the comma-separated sublist of parameter ids.
        while (scanner->token.code == tcIdentifier) {
            symtabEnterNewLocal(&node, scanner->token.string, parmDefn);
            parmId = node.node.nodeChunkNum;
            ++(*parmCount);
            if (!(*pParmList)) {
                *pParmList = parmId;
            }

            // Link the parm id nodes together
            if (!firstId) {
                firstId = lastId = parmId;
            } else {
                loadSymbNode(lastId, &node);
                node.node.nextNode = parmId;
                saveSymbNodeOnly(&node);
                lastId = parmId;
            }

            // comma
            getToken(scanner);
            resync(scanner, tlIdentifierFollow, NULL, NULL);
            if (scanner->token.code == tcComma) {
                // Saw comma.
                // Skip extra commas and look for an identifier.
                do {
                    getToken(scanner);
                    resync(scanner, tlIdentifierStart, tlIdentifierFollow, NULL);
                    if (scanner->token.code == tcComma) {
                        Error(errMissingIdentifier);
                    }
                } while (scanner->token.code == tcComma);
                if (scanner->token.code != tcIdentifier) {
                    Error(errMissingIdentifier);
                }
            } else if (scanner->token.code == tcIdentifier) {
                Error(errMissingComma);
            }
        }

        // colon
        resync(scanner, tlSublistFollow, tlDeclarationFollow, NULL);
        condGetToken(scanner, tcColon, errMissingColon);

        // <type-id>
        if (scanner->token.code == tcIdentifier) {
            findSymtabNode(&node, scanner->token.string);
            if (node.defn.how != dcType) {
                Error(errInvalidType);
            }
            parmType = node.node.typeChunk;
            getToken(scanner);
        } else {
            Error(errMissingIdentifier);
            parmType = dummyType;
        }

        // Loop to assign the offset and type to each
        // parm id in the sublist.
        for (parmId = firstId; parmId; parmId = node.node.nextNode) {
            loadSymbNode(parmId, &node);
            node.defn.data.offset = (*totalParmSize)++;
            setType(&node.node.typeChunk, parmType);
            saveSymbNode(&node);
        }

        // Link this sublist to the previous sublist.
        if (prevSublistLastId) {
            loadSymbNode(prevSublistLastId, &node);
            node.node.nextNode = firstId;
            saveSymbNodeOnly(&node);
        }
        prevSublistLastId = lastId;

        // semicolon or )
        resync(scanner, tlFormalParmsFollow, tlDeclarationFollow, NULL);
        if (scanner->token.code == tcIdentifier || scanner->token.code == tcVAR) {
            Error(errMissingSemicolon);
        } else {
            while (scanner->token.code == tcSemicolon) {
                getToken(scanner);
            }
        }
    }

    // right paren
    condGetToken(scanner, tcRParen, errMissingRightParen);
}

CHUNKNUM parseSubroutineCall(SCANNER *scanner, SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode) {
    getTokenAppend(scanner, Icode);

    if (pRoutineId->defn.routine.which == rcDeclared || pRoutineId->defn.routine.which == rcForward || !parmCheckFlag) {
        return parseDeclaredSubroutineCall(scanner, pRoutineId, parmCheckFlag, Icode);
    } else {
        return parseStandardSubroutineCall(scanner, Icode, pRoutineId);
    }
}

CHUNKNUM parseDeclaredSubroutineCall(SCANNER *scanner, SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode) {
    parseActualParmList(scanner, pRoutineId, parmCheckFlag, Icode);
    return pRoutineId->node.typeChunk;
}

void parseActualParmList(SCANNER *scanner, SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode) {
    SYMBNODE node;
    CHUNKNUM formalId = 0;

    if (pRoutineId) {
        formalId = pRoutineId->defn.routine.locals.parmIds;
    }

    // If there are no actual parameters, there better not be any
    // formal parameters either.
    if (scanner->token.code != tcLParen) {
        if (parmCheckFlag && formalId) {
            Error(errWrongNumberOfParams);
        }
        return;
    }

    // Loop to parse actual parameter expressions, separated by commas
    do {
        // ( or ,
        getTokenAppend(scanner, Icode);

        if (scanner->token.code == tcRParen) {
            if (formalId) {
                Error(errWrongNumberOfParams);
            }
            break;
        }

        parseActualParm(scanner, formalId, parmCheckFlag, Icode);
        if (formalId) {
            loadSymbNode(formalId, &node);
            formalId = node.node.nextNode;
        }
    } while (scanner->token.code == tcComma);

    // )
    condGetTokenAppend(scanner, Icode, tcRParen, errMissingRightParen);

    // There better not be any more formal parameters
    if (parmCheckFlag && formalId) {
        Error(errWrongNumberOfParams);
    }
}

void parseActualParm(SCANNER *scanner, CHUNKNUM formalId, char parmCheckFlag, CHUNKNUM Icode) {
    CHUNKNUM exprTypeChunk;
    SYMBNODE node, actualNode;

    // If we're not checking the actual parameters against the corresponding formal
    // parameters (as during error recovery), just parse the actual parameter.
    if (!parmCheckFlag) {
        exprTypeChunk = parseExpression(scanner, Icode);
        return;
    }

    // If we've already run out of formal parameters, we have an error.
    // Go into error recovery mode and parse the actual parameter anyway.
    if (!formalId) {
        Error(errWrongNumberOfParams);
        exprTypeChunk = parseExpression(scanner, Icode);
        return;
    }

    // Formal value parameter: The actual parameter can be an arbitrary
    //                         expression that is an assignment type
    //                         compatible with the formal parameter.
    loadSymbNode(formalId, &node);
    if (node.defn.how == dcValueParm) {
        exprTypeChunk = parseExpression(scanner, Icode);
        checkAssignmentCompatible(node.node.typeChunk, exprTypeChunk, errIncompatibleTypes);
    }

    // Formal VAR parameter: The actual parameter must be a variable of
    //                       the same type as the formal parameter.
    else if (scanner->token.code == tcIdentifier) {
        findSymtabNode(&actualNode, scanner->token.string);
        putSymtabNodeToIcode(Icode, &actualNode.node);
        
        exprTypeChunk = parseVariable(scanner, Icode, &actualNode);
        if (node.node.typeChunk != exprTypeChunk) {
            Error(errIncompatibleTypes);
        }
        resync(scanner, tlExpressionFollow, tlStatementFollow, tlStatementStart);
    }

    // Error: Parse the actual parameter anyway for error recovery.
    else {
        parseExpression(scanner, Icode);
        Error(errInvalidVarParm);
    }
}

