#include <string.h>
#include <common.h>
#include <symtab.h>
#include <parser.h>
#include <parscommon.h>

void parseFormalParmList(CHUNKNUM *pParmList, int *parmCount, int *totalParmSize) {
    SYMBNODE node;
    CHUNKNUM firstId, lastId, parmId;
    CHUNKNUM prevSublistLastId = 0;
    CHUNKNUM parmType;
    TDefnCode parmDefn;

    *pParmList = 0;
    *parmCount = *totalParmSize = 0;
    getToken();

    // Loop to parse parameter declarations separated by semicolons
    while (tokenCode == tcIdentifier || tokenCode == tcVAR) {
        parmType = 0;
        firstId = 0;

        // VAR or value parameter?
        if (tokenCode == tcVAR) {
            parmDefn = dcVarParm;
            getToken();
        } else {
            parmDefn = dcValueParm;
        }

        // Loop to parse the comma-separated sublist of parameter ids.
        while (tokenCode == tcIdentifier) {
            symtabEnterNewLocal(&node, tokenString, parmDefn);
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
            getToken();
            resync(tlIdentifierFollow, NULL, NULL);
            if (tokenCode == tcComma) {
                // Saw comma.
                // Skip extra commas and look for an identifier.
                do {
                    getToken();
                    resync(tlIdentifierStart, tlIdentifierFollow, NULL);
                    if (tokenCode == tcComma) {
                        Error(errMissingIdentifier);
                    }
                } while (tokenCode == tcComma);
                if (tokenCode != tcIdentifier) {
                    Error(errMissingIdentifier);
                }
            } else if (tokenCode == tcIdentifier) {
                Error(errMissingComma);
            }
        }

        // colon
        resync(tlSublistFollow, tlDeclarationFollow, NULL);
        condGetToken(tcColon, errMissingColon);

        // <type-id>
        if (tokenCode == tcIdentifier) {
            findSymtabNode(&node, tokenString);
            if (node.defn.how != dcType) {
                Error(errInvalidType);
            }
            parmType = node.node.typeChunk;
            getToken();
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
        resync(tlFormalParmsFollow, tlDeclarationFollow, NULL);
        if (tokenCode == tcIdentifier || tokenCode == tcVAR) {
            Error(errMissingSemicolon);
        } else {
            while (tokenCode == tcSemicolon) {
                getToken();
            }
        }
    }

    // right paren
    condGetToken(tcRParen, errMissingRightParen);
}

CHUNKNUM parseSubroutineCall(CHUNKNUM callChunkNum, char parmCheckFlag, CHUNKNUM Icode) {
    CHUNKNUM resultChunkNum;
    CHUNKNUM routineChunkNum = routineNode.node.nodeChunkNum;

    getTokenAppend(Icode);

    saveSymbNode(&routineNode);
    loadSymbNode(callChunkNum, &routineNode);
    if (routineNode.defn.routine.which == rcDeclared || routineNode.defn.routine.which == rcForward || !parmCheckFlag) {
        resultChunkNum = parseDeclaredSubroutineCall(parmCheckFlag, Icode);
    } else {
        resultChunkNum = parseStandardSubroutineCall(Icode);
    }

    loadSymbNode(routineChunkNum, &routineNode);
    return resultChunkNum;
}

CHUNKNUM parseDeclaredSubroutineCall(char parmCheckFlag, CHUNKNUM Icode) {
    parseActualParmList(1, parmCheckFlag, Icode);
    return routineNode.node.typeChunk;
}

void parseActualParmList(char routineFlag, char parmCheckFlag, CHUNKNUM Icode) {
    SYMBNODE node;
    CHUNKNUM formalId = 0;

    if (routineFlag) {
        formalId = routineNode.defn.routine.locals.parmIds;
    }

    // If there are no actual parameters, there better not be any
    // formal parameters either.
    if (tokenCode != tcLParen) {
        if (parmCheckFlag && formalId) {
            Error(errWrongNumberOfParams);
        }
        return;
    }

    // Loop to parse actual parameter expressions, separated by commas
    do {
        // ( or ,
        getTokenAppend(Icode);

        if (tokenCode == tcRParen) {
            if (formalId) {
                Error(errWrongNumberOfParams);
            }
            break;
        }

        parseActualParm(formalId, parmCheckFlag, Icode);
        if (formalId) {
            loadSymbNode(formalId, &node);
            formalId = node.node.nextNode;
        }
    } while (tokenCode == tcComma);

    // )
    condGetTokenAppend(Icode, tcRParen, errMissingRightParen);

    // There better not be any more formal parameters
    if (parmCheckFlag && formalId) {
        Error(errWrongNumberOfParams);
    }
}

void parseActualParm(CHUNKNUM formalId, char parmCheckFlag, CHUNKNUM Icode) {
    CHUNKNUM exprTypeChunk;
    SYMBNODE node, actualNode;

    // If we're not checking the actual parameters against the corresponding formal
    // parameters (as during error recovery), just parse the actual parameter.
    if (!parmCheckFlag) {
        exprTypeChunk = parseExpression(Icode);
        return;
    }

    // If we've already run out of formal parameters, we have an error.
    // Go into error recovery mode and parse the actual parameter anyway.
    if (!formalId) {
        Error(errWrongNumberOfParams);
        exprTypeChunk = parseExpression(Icode);
        return;
    }

    // Formal value parameter: The actual parameter can be an arbitrary
    //                         expression that is an assignment type
    //                         compatible with the formal parameter.
    loadSymbNode(formalId, &node);
    if (node.defn.how == dcValueParm) {
        exprTypeChunk = parseExpression(Icode);
        checkAssignmentCompatible(node.node.typeChunk, exprTypeChunk, errIncompatibleTypes);
    }

    // Formal VAR parameter: The actual parameter must be a variable of
    //                       the same type as the formal parameter.
    else if (tokenCode == tcIdentifier) {
        findSymtabNode(&actualNode, tokenString);
        putSymtabNodeToIcode(Icode, &actualNode);
        
        exprTypeChunk = parseVariable(Icode, &actualNode);
        if (node.node.typeChunk != exprTypeChunk) {
            Error(errIncompatibleTypes);
        }
        resync(tlExpressionFollow, tlStatementFollow, tlStatementStart);
    }

    // Error: Parse the actual parameter anyway for error recovery.
    else {
        parseExpression(Icode);
        Error(errInvalidVarParm);
    }
}

