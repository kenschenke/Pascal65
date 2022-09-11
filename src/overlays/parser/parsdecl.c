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

void parseDeclarations(SCANNER *scanner, SYMTABNODE *routineSymtab) {
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
}

void parseConstant(SCANNER *scanner, SYMTABNODE *constId) {
    DEFN defn;
    int length;
    TTokenCode sign = tcDummy;  // unary + or - sign, or none

    if (retrieveChunk(constId->defnChunk, (unsigned char *)&defn) == 0) {
        return;
    }

    // unary + or -

    if (tokenIn(scanner->token.code, tlUnaryOps)) {
        if (scanner->token.code == tcMinus) sign = tcMinus;
        getToken(scanner);
    }

    switch (scanner->token.code) {
        // Numeric constant: integer
        case tcNumber:
            if (scanner->token.type == tyInteger) {
                defn.constant.value.integer =
                    sign == tcMinus ? -scanner->token.value.integer :
                        scanner->token.value.integer;
                setType(&constId->typeChunk, integerType);
                if (storeChunk(constId->defnChunk, (unsigned char *)&defn) == 0) {
                    return;
                }
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
                defn.constant.value.character = scanner->token.string[1];
                setType(&constId->typeChunk, charType);
            } else {
                // String (character array) : create a new unnamed string type
                copyQuotedString(scanner->token.string, &defn.constant.value.stringChunkNum);
                setType(&constId->typeChunk, makeStringType(length));
            }
            if (storeChunk(constId->defnChunk, (unsigned char *)&defn) == 0) {
                return;
            }
            getToken(scanner);
            break;
    }

    if (storeChunk(constId->nodeChunkNum, (unsigned char *)constId) == 0) {
        return;
    }
}

void parseConstantDefinitions(SCANNER *scanner, SYMTABNODE *routineSymtab) {
    DEFN defn;
    SYMTAB global;
    SYMTABNODE constId, lastId;

    if (retrieveChunk(globalSymtab, (unsigned char *)&global) == 0) {
        return;
    }

    // Loop to parse a list of constant definitions
    // separated by semicolons
    while (scanner->token.code == tcIdentifier) {
        if (enterNew(&global, &constId, scanner->token.string, dcUndefined) == 0) {
            return;
        }

        // Link the routine's local constant id nodes together
        if (retrieveChunk(routineSymtab->defnChunk, (unsigned char *)&defn) == 0) {
            return;
        }
        if (!defn.routine.locals.constantIds) {
            defn.routine.locals.constantIds = constId.nodeChunkNum;
            storeChunk(routineSymtab->defnChunk, (unsigned char *)&defn);
        } else {
            if (retrieveChunk(lastId.nodeChunkNum, (unsigned char *)&lastId) == 0) {
                return;
            }
            lastId.nextNode = constId.nodeChunkNum;
            if (storeChunk(lastId.nodeChunkNum, (unsigned char *)&lastId) == 0) {
                return;
            }
        }
        lastId.nodeChunkNum = constId.nodeChunkNum;

        // =
        getToken(scanner);
        condGetToken(scanner, tcEqual, errMissingEqual);

        // <constant>
        parseConstant(scanner, &constId);
        retrieveChunk(constId.defnChunk, (unsigned char *)&defn);
        defn.how = dcConstant;
        if (storeChunk(constId.defnChunk, (unsigned char *)&defn) == 0) {
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

void parseIdentifierConstant(SCANNER *scanner, SYMTABNODE *id1, TTokenCode sign) {
    DEFN defn1, defn2;
    TTYPE type2;
    SYMTABNODE id2;

    // id1 is the lhalf
    // id2 is the rhalf

    if (retrieveChunk(id1->defnChunk, (unsigned char *)&defn1) == 0) {
        return;
    }

    if (findSymtabNode(&id2, scanner->token.string) == 0) {
        return;
    }
    if (retrieveChunk(id2.defnChunk, (unsigned char *)&defn2) == 0) {
        return;
    }
    if (defn2.how != dcConstant) {
        Error(errNotAConstantIdentifier);
        setType(&id1->typeChunk, dummyType);
        getToken(scanner);
        return;
    }

    if (id2.typeChunk) {
        retrieveChunk(id2.typeChunk, (unsigned char *)&type2);
    }

    if (id2.typeChunk == integerType) {
        // Integer identifier
        defn1.constant.value.integer =
            sign == tcMinus ? -defn2.constant.value.integer :
            defn2.constant.value.integer;
        setType(&id1->typeChunk, integerType);
    } else if (id2.typeChunk == charType) {
        // character identifer - no unary sign allowed
        if (sign != tcDummy) Error(errInvalidConstant);
        defn1.constant.value.character =
            defn2.constant.value.character;
        setType(&id1->typeChunk, charType);
    } else if (id2.typeChunk && type2.form == fcEnum) {
        // enumeration identifier: no unary sign allowed
        if (sign != tcDummy) Error(errInvalidConstant);
        defn1.constant.value.integer =
            defn2.constant.value.integer;
        setType(&id1->typeChunk, id2.typeChunk);
    } else if (id2.typeChunk && type2.form == fcArray) {
        // array identifier
        // must be character array, and no unary sign allowed
        if (sign != tcDummy || type2.array.elemType != charType) {
            Error(errInvalidConstant);
        }

        defn1.constant.value.stringChunkNum = defn2.constant.value.stringChunkNum;
        setType(&id1->typeChunk, id2.typeChunk);
    }

    storeChunk(id1->defnChunk, (unsigned char *)&defn1);
    storeChunk(id1->nodeChunkNum, (unsigned char *)id1);

    getToken(scanner);
}

CHUNKNUM parseIdSublist(SCANNER *scanner, SYMTABNODE *routineId, TTYPE *pRecordType, CHUNKNUM *pLastId) {
    DEFN defn;
    SYMTAB symtab;
    CHUNKNUM firstId = 0;
    SYMTABNODE pId, lastId;
    *pLastId = 0;

    // Loop to parse each identifier in the sublist
    while (scanner->token.code == tcIdentifier) {
        // variable: enter into local symbol table
        // field:    enter into record symbol table
        if (routineId != NULL) {
            enterGlobalSymtab(scanner->token.string, &pId);
        } else {
            if (retrieveChunk(pRecordType->record.symtab, (unsigned char *)&symtab) == 0) {
                return 0;
            }
            enterNew(&symtab, &pId, scanner->token.string, dcUndefined);
        }

        // Link newly-declared identifier nodes together
        // into a sublist.
        if (retrieveChunk(pId.defnChunk, (unsigned char *)&defn) == 0) {
            return 0;
        }
        if (defn.how == dcUndefined) {
            defn.how = routineId != NULL ? dcVariable : dcField;
            if (!firstId) firstId = *pLastId = pId.nodeChunkNum;
            else {
                if (retrieveChunk(*pLastId, (unsigned char *)&lastId) == 0) {
                    return 0;
                }
                lastId.nextNode = pId.nodeChunkNum;
                if (storeChunk(*pLastId, (unsigned char *)&lastId) == 0) {
                    return 0;
                }
                *pLastId = pId.nodeChunkNum;
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

void parseVariableDeclarations(SCANNER *scanner, SYMTABNODE *routineSymtab) {
    parseVarOrFieldDecls(scanner, routineSymtab, NULL, 0);
}

void parseFieldDeclarations(SCANNER *scanner, TTYPE *pRecordType, int offset) {
    parseVarOrFieldDecls(scanner, NULL, pRecordType, offset);
}

void parseVarOrFieldDecls(SCANNER *scanner, SYMTABNODE *routineSymtab, TTYPE *pRecordType, int offset) {
    CHUNKNUM firstId, lastId, pId, newTypeChunkNum, prevSublistLastId = 0;
    TTYPE newType;
    DEFN defn;
    SYMTABNODE node;
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
        for (pId = firstId; pId; pId = node.nextNode) {
            if (retrieveChunk(pId, (unsigned char *)&node) == 0) {
                return;
            }
            setType(&node.typeChunk, newTypeChunkNum);
            storeChunk(pId, (unsigned char *)&node);

            if (retrieveChunk(node.defnChunk, (unsigned char *)&defn) == 0) {
                return;
            }

            if (routineSymtab != NULL) {
                // Variables
                defn.data.offset = offset++;
                totalSize += newType.size;
            } else {
                // Record fields
                defn.data.offset = offset;
                offset += newType.size;
            }

            if (storeChunk(node.defnChunk, (unsigned char *)&defn) == 0) {
                return;
            }
        }

        if (firstId) {
            // Set the first sublist into the routine id's symtab node.
            if (routineSymtab) {
                if (retrieveChunk(routineSymtab->defnChunk, (unsigned char *)&defn) == 0) {
                    return;
                }
                if (!defn.routine.locals.variableIds) {
                    defn.routine.locals.variableIds = firstId;
                    if (storeChunk(routineSymtab->defnChunk, (unsigned char *)&defn) == 0) {
                        return;
                    }
                }
            }

            // Link this list to the previous sublist
            if (prevSublistLastId) {
                if (retrieveChunk(prevSublistLastId, (unsigned char *)&node) == 0) {
                    return;
                }
                node.nextNode = firstId;
                if (storeChunk(prevSublistLastId, (unsigned char *)&node) == 0) {
                    return;
                }
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
        if (retrieveChunk(routineSymtab->defnChunk, (unsigned char *)&defn) == 0) {
            return;
        }
        defn.routine.totalLocalSize = totalSize;
        if (storeChunk(routineSymtab->defnChunk, (unsigned char *)&defn) == 0) {
            return;
        }
    } else {
        pRecordType->size = offset;
    }
}

