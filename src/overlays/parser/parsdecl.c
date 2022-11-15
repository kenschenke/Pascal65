#include <parser.h>
#include <scanner.h>
#include <error.h>
#include <common.h>
#include <symtab.h>
#include <parscommon.h>
#include <string.h>
#include <types.h>

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

void parseDeclarations(SCANNER *scanner, SYMBNODE *routineSymtab) {
    if (scanner->token.code == tcCONST) {
        getToken(scanner);
        parseConstantDefinitions(scanner, routineSymtab);
    }

    if (scanner->token.code == tcTYPE) {
        getToken(scanner);
        parseTypeDefinitions(scanner, routineSymtab);
    }

    if (scanner->token.code == tcVAR) {
        getToken(scanner);
        parseVariableDeclarations(scanner, routineSymtab);
    }

    if (tokenIn(scanner->token.code, tlProcFuncStart)) {
        parseSubroutineDeclarations(scanner, routineSymtab);
    }
}

void parseConstant(SCANNER *scanner, SYMBNODE *constId) {
    int length;
    TTokenCode sign = tcDummy;  // unary + or - sign, or none

    // unary + or -

    if (tokenIn(scanner->token.code, tlUnaryOps)) {
        if (scanner->token.code == tcMinus) sign = tcMinus;
        getToken(scanner);
    }

    switch (scanner->token.code) {
        // Numeric constant: integer
        case tcNumber:
            if (scanner->token.type == tyInteger) {
                constId->defn.constant.value.integer =
                    sign == tcMinus ? -scanner->token.value.integer :
                        scanner->token.value.integer;
                setType(&constId->node.typeChunk, integerType);
            }
            getToken(scanner);
            break;
        
        // Identifier constant
        case tcIdentifier:
            parseIdentifierConstant(scanner, constId, sign);
            break;
        
        // String constant
        case tcString:
            length = strlen(scanner->token.string) - 2;  // skip quotes
            if (sign != tcDummy) Error(errInvalidConstant);

            if (length == 1) {
                // Single character
                constId->defn.constant.value.character = scanner->token.string[1];
                setType(&constId->node.typeChunk, charType);
            } else {
                // String (character array) : create a new unnamed string type
                copyQuotedString(scanner->token.string, &constId->defn.constant.value.stringChunkNum);
                setType(&constId->node.typeChunk, makeStringType(length));
            }
            getToken(scanner);
            break;
    }

    saveSymbNode(constId);
}

void parseConstantDefinitions(SCANNER *scanner, SYMBNODE *routineSymtab) {
    SYMBNODE constId, lastId;

    // Loop to parse a list of constant definitions
    // separated by semicolons
    while (scanner->token.code == tcIdentifier) {
        if (symtabEnterNewLocal(&constId, scanner->token.string, dcUndefined) == 0) {
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
        getToken(scanner);
        condGetToken(scanner, tcEqual, errMissingEqual);

        // <constant>
        parseConstant(scanner, &constId);
        constId.defn.how = dcConstant;
        if (saveSymbNodeDefn(&constId) == 0) {
            return;
        }

        // ;
        resync(scanner, tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(scanner, tcSemicolon, errMissingSemicolon);

        // skip extra semicolons
        while (scanner->token.code == tcSemicolon) getToken(scanner);
        resync(scanner, tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
    }
}

void parseIdentifierConstant(SCANNER *scanner, SYMBNODE *id1, TTokenCode sign) {
    SYMBNODE id2;

    // id1 is the lhalf
    // id2 is the rhalf

    if (findSymtabNode(&id2, scanner->token.string) == 0) {
        return;
    }
    if (id2.defn.how != dcConstant) {
        Error(errNotAConstantIdentifier);
        setType(&id1->node.typeChunk, dummyType);
        saveSymbNode(id1);
        getToken(scanner);
        return;
    }

    if (id2.node.typeChunk == integerType) {
        // Integer identifier
        id1->defn.constant.value.integer =
            sign == tcMinus ? -id2.defn.constant.value.integer :
            id2.defn.constant.value.integer;
        setType(&id1->node.typeChunk, integerType);
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

    getToken(scanner);
}

CHUNKNUM parseIdSublist(SCANNER *scanner, SYMBNODE *routineId, TTYPE *pRecordType, CHUNKNUM *pLastId) {
    CHUNKNUM firstId = 0;
    SYMBNODE pId, lastId;
    *pLastId = 0;

    // Loop to parse each identifier in the sublist
    while (scanner->token.code == tcIdentifier) {
        // variable: enter into local symbol table
        // field:    enter into record symbol table
        if (routineId != NULL) {
            symtabEnterNewLocal(&pId, scanner->token.string, dcUndefined);
        } else {
            enterNew(pRecordType->record.symtab, &pId, scanner->token.string, dcUndefined);
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
        getToken(scanner);
        resync(scanner, tlIdentifierFollow, NULL, NULL);
        if (scanner->token.code == tcComma) {
            // Saw comma
            // Skip extra commas and look for an identifier
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
        }
        else if (scanner->token.code == tcIdentifier) {
            Error(errMissingComma);
        }
    }

    return firstId;
}

void parseVariableDeclarations(SCANNER *scanner, SYMBNODE *routineSymtab) {
    parseVarOrFieldDecls(scanner, routineSymtab, NULL, 0);
}

void parseFieldDeclarations(SCANNER *scanner, TTYPE *pRecordType, int offset) {
    parseVarOrFieldDecls(scanner, NULL, pRecordType, offset);
}

void parseVarOrFieldDecls(SCANNER *scanner, SYMBNODE *routineSymtab, TTYPE *pRecordType, int offset) {
    CHUNKNUM firstId, lastId, pId, newTypeChunkNum, prevSublistLastId = 0;
    TTYPE newType;
    SYMBNODE node;
    int totalSize = 0;

    // Loop to parse a list of variable or field declarations
    while (scanner->token.code == tcIdentifier) {
        // <id-sublist>
        firstId = parseIdSublist(scanner, routineSymtab, pRecordType, &lastId);

        // :
        resync(scanner, tlSublistFollow, tlDeclarationFollow, NULL);
        condGetToken(scanner, tcColon, errMissingColon);

        // <type>
        parseTypeSpec(scanner, &newTypeChunkNum);
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
            resync(scanner, tlDeclarationFollow, tlStatementStart, NULL);
            condGetToken(scanner, tcSemicolon, errMissingSemicolon);

            // skip extra semicolons
            while (scanner->token.code == tcSemicolon) getToken(scanner);
            resync(scanner, tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        } else {
            resync(scanner, tlFieldDeclFollow, NULL, NULL);
            if (scanner->token.code != tcEND) {
                condGetToken(scanner, tcSemicolon, errMissingSemicolon);

                // skip extra semicolons
                while (scanner->token.code == tcSemicolon) getToken(scanner);
                resync(scanner, tlFieldDeclFollow, tlDeclarationStart, tlStatementStart);
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

