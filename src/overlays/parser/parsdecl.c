#include <parser.h>
#include <scanner.h>
#include <error.h>
#include <common.h>
#include <symtab.h>
#include <parscommon.h>
#include <string.h>
#include <types.h>
#include <real.h>

void copyQuotedString(const char *pString, CHUNKNUM *firstChunk) {
    CHUNKNUM chunkNum, nextChunkNum;
    const char *p = pString + 1;
    char isAlloc;  // non-zero if the next chunk is new
    STRVALCHUNK chunk;
    int toCopy, len = strlen(p) - 1;

    // Store the string as one or more chunks

    // If there is already a string value for this node, replace it.
    chunkNum = *firstChunk;
    if (chunkNum) {
        // There's already a chunk - retrieve it
        if (retrieveChunk(chunkNum, (unsigned char *)&chunk) == 0) {
            abortTranslation(abortOutOfMemory);
            return;
        }
    } else {
        // No value assigned yet - allocate a new chunk
        if (allocChunk(&chunkNum) == 0) {
            abortTranslation(abortOutOfMemory);
            return;
        }
        // Store the chunkNum in the node as the first value chunk
        *firstChunk = chunkNum;
        chunk.nextChunkNum = 0;
    }

    while (len) {
        memset(chunk.value, 0, sizeof(chunk.value));
        toCopy = len > sizeof(chunk.value) ? sizeof(chunk.value) : len;
        memcpy(chunk.value, p, toCopy);
        len -= toCopy;
        p += toCopy;

        nextChunkNum = chunk.nextChunkNum;
        if (len) {
            if (nextChunkNum == 0) {
                if (allocChunk(&nextChunkNum) == 0) {
                    abortTranslation(abortOutOfMemory);
                    return;
                }
                isAlloc = 1;
                chunk.nextChunkNum = nextChunkNum;
            } else {
                isAlloc = 0;
            }
        } else {
            chunk.nextChunkNum = 0;
        }

        if (storeChunk(chunkNum, (unsigned char *)&chunk) == 0) {
            abortTranslation(abortOutOfMemory);
            return;
        }

        chunkNum = nextChunkNum;
        if (chunkNum) {
            if (isAlloc) {
                memset(&chunk, 0, sizeof(chunk));
            } else {
                if (retrieveChunk(chunkNum, (unsigned char *)&chunk) == 0) {
                    abortTranslation(abortOutOfMemory);
                    return;
                }
            }
        }
    }

    while (nextChunkNum) {
        if (retrieveChunk(nextChunkNum, (unsigned char *)&chunk) == 0) {
            abortTranslation(abortOutOfMemory);
            return;
        }

        freeChunk(nextChunkNum);
        nextChunkNum = chunk.nextChunkNum;
    }
}

void parseDeclarations(SYMBNODE *routineSymtab) {
    if (tokenCode == tcCONST) {
        getToken();
        parseConstantDefinitions(routineSymtab);
    }

    if (tokenCode == tcTYPE) {
        getToken();
        parseTypeDefinitions(routineSymtab);
    }

    if (tokenCode == tcVAR) {
        getToken();
        parseVariableDeclarations(routineSymtab);
    }

    if (tokenIn(tokenCode, tlProcFuncStart)) {
        parseSubroutineDeclarations(routineSymtab);
    }
}

void parseConstant(SYMBNODE *constId) {
    int length;
    TTokenCode sign = tcDummy;  // unary + or - sign, or none

    // unary + or -

    if (tokenIn(tokenCode, tlUnaryOps)) {
        if (tokenCode == tcMinus) sign = tcMinus;
        getToken();
    }

    switch (tokenCode) {
        // Numeric constant: integer
        case tcNumber:
            if (tokenType == tyInteger) {
                constId->defn.constant.value.integer =
                    sign == tcMinus ? -tokenValue.integer :
                        tokenValue.integer;
                setType(&constId->node.typeChunk, integerType);
            } else {
                constId->defn.constant.value.real =
                    sign == tcMinus ? floatNeg(tokenValue.real) :
                        tokenValue.real;
                setType(&constId->node.typeChunk, realType);
            }
            getToken();
            break;
        
        // Identifier constant
        case tcIdentifier:
            parseIdentifierConstant(constId, sign);
            break;
        
        // String constant
        case tcString:
            length = strlen(tokenString) - 2;  // skip quotes
            if (sign != tcDummy) Error(errInvalidConstant);

            if (length == 1) {
                // Single character
                constId->defn.constant.value.character = tokenString[1];
                setType(&constId->node.typeChunk, charType);
            } else {
                // String (character array) : create a new unnamed string type
                copyQuotedString(tokenString, &constId->defn.constant.value.stringChunkNum);
                setType(&constId->node.typeChunk, makeStringType(length));
            }
            getToken();
            break;
    }

    saveSymbNode(constId);
}

void parseConstantDefinitions(SYMBNODE *routineSymtab) {
    SYMBNODE constId, lastId;

    // Loop to parse a list of constant definitions
    // separated by semicolons
    while (tokenCode == tcIdentifier) {
        if (symtabEnterNewLocal(&constId, tokenString, dcUndefined) == 0) {
            return;
        }

        // Link the routine's local constant id nodes together
        if (!routineSymtab->defn.routine.locals.constantIds) {
            routineSymtab->defn.routine.locals.constantIds = constId.node.nodeChunkNum;
            saveSymbNodeDefn(routineSymtab);
        } else {
            if (loadSymbNode(lastId.node.nodeChunkNum, &lastId) == 0) {
                return;
            }
            lastId.node.nextNode = constId.node.nodeChunkNum;
            if (saveSymbNodeOnly(&lastId) == 0) {
                return;
            }
        }
        lastId.node.nodeChunkNum = constId.node.nodeChunkNum;

        // =
        getToken();
        condGetToken(tcEqual, errMissingEqual);

        // <constant>
        parseConstant(&constId);
        constId.defn.how = dcConstant;
        if (saveSymbNodeDefn(&constId) == 0) {
            return;
        }

        // ;
        resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(tcSemicolon, errMissingSemicolon);

        // skip extra semicolons
        while (tokenCode == tcSemicolon) getToken();
        resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
    }
}

void parseIdentifierConstant(SYMBNODE *id1, TTokenCode sign) {
    SYMBNODE id2;

    // id1 is the lhalf
    // id2 is the rhalf

    if (findSymtabNode(&id2, tokenString) == 0) {
        return;
    }
    if (id2.defn.how != dcConstant) {
        Error(errNotAConstantIdentifier);
        setType(&id1->node.typeChunk, dummyType);
        saveSymbNode(id1);
        getToken();
        return;
    }

    if (id2.node.typeChunk == integerType) {
        // Integer identifier
        id1->defn.constant.value.integer =
            sign == tcMinus ? -id2.defn.constant.value.integer :
            id2.defn.constant.value.integer;
        setType(&id1->node.typeChunk, integerType);
    } else if (id2.node.typeChunk == realType) {
        id1->defn.constant.value.real =
            sign == tcMinus ? floatNeg(id2.defn.constant.value.real) :
                id2.defn.constant.value.real;
        setType(&id1->node.typeChunk, realType);
    } else if (id2.node.typeChunk == charType) {
        // character identifer - no unary sign allowed
        if (sign != tcDummy) Error(errInvalidConstant);
        id1->defn.constant.value.character =
            id2.defn.constant.value.character;
        setType(&id1->node.typeChunk, charType);
    } else if (id2.node.typeChunk && id2.type.form == fcEnum) {
        // enumeration identifier: no unary sign allowed
        if (sign != tcDummy) Error(errInvalidConstant);
        id1->defn.constant.value.integer =
            id2.defn.constant.value.integer;
        setType(&id1->node.typeChunk, id2.node.typeChunk);
    } else if (id2.node.typeChunk && id2.type.form == fcArray) {
        // array identifier
        // must be character array, and no unary sign allowed
        if (sign != tcDummy || id2.type.array.elemType != charType) {
            Error(errInvalidConstant);
        }

        id1->defn.constant.value.stringChunkNum = id2.defn.constant.value.stringChunkNum;
        setType(&id1->node.typeChunk, id2.node.typeChunk);
    }

    saveSymbNode(id1);

    getToken();
}

CHUNKNUM parseIdSublist(SYMBNODE *routineId, TTYPE *pRecordType, CHUNKNUM *pLastId) {
    CHUNKNUM firstId = 0;
    SYMBNODE pId, lastId;
    *pLastId = 0;

    // Loop to parse each identifier in the sublist
    while (tokenCode == tcIdentifier) {
        // variable: enter into local symbol table
        // field:    enter into record symbol table
        if (routineId != NULL) {
            symtabEnterNewLocal(&pId, tokenString, dcUndefined);
        } else {
            enterNew(pRecordType->record.symtab, &pId, tokenString, dcUndefined);
        }

        // Link newly-declared identifier nodes together
        // into a sublist.
        if (pId.defn.how == dcUndefined) {
            pId.defn.how = routineId != NULL ? dcVariable : dcField;
            storeChunk(pId.node.defnChunk, (unsigned char *)&pId.defn);
            if (!firstId) firstId = *pLastId = pId.node.nodeChunkNum;
            else {
                if (loadSymbNode(*pLastId, &lastId) == 0) {
                    return 0;
                }
                lastId.node.nextNode = pId.node.nodeChunkNum;
                if (saveSymbNodeOnly(&lastId) == 0) {
                    return 0;
                }
                *pLastId = pId.node.nodeChunkNum;
            }
        }

        // ,
        getToken();
        resync(tlIdentifierFollow, NULL, NULL);
        if (tokenCode == tcComma) {
            // Saw comma
            // Skip extra commas and look for an identifier
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
        }
        else if (tokenCode == tcIdentifier) {
            Error(errMissingComma);
        }
    }

    return firstId;
}

void parseVariableDeclarations(SYMBNODE *routineSymtab) {
    parseVarOrFieldDecls(routineSymtab, NULL, routineSymtab->defn.routine.parmCount);
}

void parseFieldDeclarations(TTYPE *pRecordType, int offset) {
    parseVarOrFieldDecls(NULL, pRecordType, offset);
}

void parseVarOrFieldDecls(SYMBNODE *routineSymtab, TTYPE *pRecordType, int offset) {
    CHUNKNUM firstId, lastId, pId, newTypeChunkNum, prevSublistLastId = 0;
    TTYPE newType;
    SYMBNODE node;
    int totalSize = 0;

    // Loop to parse a list of variable or field declarations
    while (tokenCode == tcIdentifier) {
        // <id-sublist>
        firstId = parseIdSublist(routineSymtab, pRecordType, &lastId);

        // :
        resync(tlSublistFollow, tlDeclarationFollow, NULL);
        condGetToken(tcColon, errMissingColon);

        // <type>
        parseTypeSpec(&newTypeChunkNum);
        retrieveChunk(newTypeChunkNum, (unsigned char *)&newType);

        // Now loop to assign the type and offset to each
        // identifier in the sublist.
        for (pId = firstId; pId; pId = node.node.nextNode) {
            if (loadSymbNode(pId, &node) == 0) {
                return;
            }
            setType(&node.node.typeChunk, newTypeChunkNum);
            saveSymbNodeOnly(&node);

            if (routineSymtab != NULL) {
                // Variables
                node.defn.data.offset = offset++;
                totalSize += newType.size;
            } else {
                // Record fields
                node.defn.data.offset = offset;
                offset += newType.size;
            }

            saveSymbNodeDefn(&node);
        }

        if (firstId) {
            // Set the first sublist into the routine id's symtab node.
            if (routineSymtab) {
                if (!routineSymtab->defn.routine.locals.variableIds) {
                    routineSymtab->defn.routine.locals.variableIds = firstId;
                    saveSymbNodeDefn(routineSymtab);
                }
            }

            // Link this list to the previous sublist
            if (prevSublistLastId) {
                retrieveChunk(prevSublistLastId, (unsigned char *)&node.node);
                node.node.nextNode = firstId;
                saveSymbNodeOnly(&node);
            }
            prevSublistLastId = lastId;
        }

        // ;
        // END for record field declaration
        if (routineSymtab) {
            resync(tlDeclarationFollow, tlStatementStart, NULL);
            condGetToken(tcSemicolon, errMissingSemicolon);

            // skip extra semicolons
            while (tokenCode == tcSemicolon) getToken();
            resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        } else {
            resync(tlFieldDeclFollow, NULL, NULL);
            if (tokenCode != tcEND) {
                condGetToken(tcSemicolon, errMissingSemicolon);

                // skip extra semicolons
                while (tokenCode == tcSemicolon) getToken();
                resync(tlFieldDeclFollow, tlDeclarationStart, tlStatementStart);
            }
        }
    }

    // Set the routine identifier node or the record type object
    if (routineSymtab) {
        routineSymtab->defn.routine.totalLocalSize = totalSize;
        saveSymbNodeDefn(routineSymtab);
    } else {
        pRecordType->size = offset;
    }
}

