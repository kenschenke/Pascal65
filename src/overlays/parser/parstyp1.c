#include <common.h>
#include <parser.h>
#include <chunks.h>
#include <parscommon.h>
#include <symtab.h>
#include <types.h>
#include <string.h>

void parseEnumerationType(SCANNER *scanner, CHUNKNUM *newTypeChunkNum) {
    TTYPE newType;
    CHUNKNUM lastChunk = 0, newChunkNum;
    SYMBNODE newNode;
    int constValue = -1;

    getToken(scanner);
    resync(scanner, tlEnumConstStart, NULL, NULL);

    *newTypeChunkNum = makeType(fcEnum, sizeof(int), 0);
    retrieveChunk(*newTypeChunkNum, (unsigned char *)&newType);

    // Loop to parse list of constant identifiers separated by commas.
    while (scanner->token.code == tcIdentifier) {
        symtabEnterNewLocal(&newNode, scanner->token.string, dcUndefined);
        ++constValue;

        if (newNode.defn.how == dcUndefined) {
            newNode.defn.how = dcConstant;
            newNode.defn.constant.value.integer = constValue;
            setType(&newNode.node.typeChunk, *newTypeChunkNum);
            saveSymbNode(&newNode);

            // Link constant identifier symbol table nodes together.
            if (!lastChunk) {
                newType.enumeration.constIds = lastChunk = newNode.node.nodeChunkNum;
            } else {
                newChunkNum = newNode.node.nodeChunkNum;
                loadSymbNode(lastChunk, &newNode);
                newNode.node.nextNode = newChunkNum;
                saveSymbNodeOnly(&newNode);
                lastChunk = newChunkNum;
            }
        }

        memset(&newNode, 0, sizeof(SYMBNODE));

        // ,
        getToken(scanner);
        resync(scanner, tlEnumConstFollow, NULL, NULL);
        if (scanner->token.code == tcComma) {
            // Saw comma.  Skip extra commas and look for an identifier
            do {
                getToken(scanner);
                resync(scanner, tlEnumConstStart, tlEnumConstFollow, NULL);
                if (scanner->token.code == tcComma) Error(errMissingIdentifier);
            } while (scanner->token.code == tcComma);
            if (scanner->token.code != tcIdentifier) Error(errMissingIdentifier);
        }
        else if (scanner->token.code == tcIdentifier) Error(errMissingComma);
    }

    // )
    condGetToken(scanner, tcRParen, errMissingRightParen);

    newType.enumeration.max = constValue;
    storeChunk(*newTypeChunkNum, (unsigned char *)&newType);
}

void parseIdentifierType(SCANNER *scanner) {
    getToken(scanner);
}

void parseSubrangeLimit(SCANNER *scanner, SYMBNODE *pLimit, int *limit, CHUNKNUM *limitTypeChunkNum) {
    SYMBNODE node;
    TTokenCode sign = tcDummy;

    *limit = 0;
    *limitTypeChunkNum = dummyType;

    // Unary + or -
    if (tokenIn(scanner->token.code, tlUnaryOps)) {
        if (scanner->token.code == tcMinus) sign = tcMinus;
        getToken(scanner);
    }

    switch (scanner->token.code) {
        case tcNumber:
            // Numeric constant: integer type only
            if (scanner->token.type == tyInteger) {
                *limit = sign == tcMinus ? -scanner->token.value.integer :
                    scanner->token.value.integer;
                *limitTypeChunkNum = integerType;
            } else {
                Error(errInvalidSubrangeType);
            }
            break;

        case tcIdentifier:
            // identifier limit: must be an integer, character, or
            // enumeration type.
            if (pLimit == NULL) {
                if (findSymtabNode(&node, scanner->token.string) == 0) {
                    Error(errInvalidSubrangeType);
                    break;
                }
                pLimit = &node;
            }
            if (pLimit->defn.how == dcUndefined) {
                pLimit->defn.how = dcConstant;
                saveSymbNodeDefn(pLimit);
                *limitTypeChunkNum = dummyType;
                break;
            }
            if (pLimit->node.typeChunk == dummyType) {
                Error(errInvalidSubrangeType);
                break;
            }
            if (pLimit->type.form == fcArray) {
                Error(errInvalidSubrangeType);
                break;
            }
            if (pLimit->defn.how == dcConstant) {
                // Use the value of the constant identifer.
                if (pLimit->node.typeChunk == integerType) {
                    *limit = sign == tcMinus ? -pLimit->defn.constant.value.integer :
                        pLimit->defn.constant.value.integer;
                } else if (pLimit->node.typeChunk == charType) {
                    if (sign != tcDummy) {
                        Error(errInvalidSubrangeType);
                        break;
                    }
                    *limit = pLimit->defn.constant.value.character;
                } else if (pLimit->type.form == fcEnum) {
                    if (sign != tcDummy) {
                        Error(errInvalidSubrangeType);
                        break;
                    }
                    *limit = pLimit->defn.constant.value.integer;
                }
                *limitTypeChunkNum = pLimit->node.typeChunk;
            } else {
                Error(errNotAConstantIdentifier);
            }
            break;
        
        case tcString:
            // String limit: character type only
            if (sign != tcDummy) {
                Error(errInvalidConstant);
            }

            if (strlen(scanner->token.string) != 3) {
                // length inludes quotes
                Error(errInvalidSubrangeType);
            }

            *limit = scanner->token.string[1];
            *limitTypeChunkNum = charType;
            break;
        
        default:
            Error(errMissingConstant);
            break;
    }

    getToken(scanner);
}

void parseSubrangeType(SCANNER *scanner, SYMBNODE *pMinId, CHUNKNUM *newTypeChunkNum) {
    int temp;
    CHUNKNUM newMinChunkNum, maxTypeChunkNum;
    TTYPE newType, baseType, maxType;

    *newTypeChunkNum = makeType(fcSubrange, 0, 0);
    retrieveChunk(*newTypeChunkNum, (unsigned char *)&newType);

    // <min-const>
    parseSubrangeLimit(scanner, pMinId, &newType.subrange.min, &newMinChunkNum);
    setType(&newType.subrange.baseType, newMinChunkNum);

    // ..
    resync(scanner, tlSubrangeLimitFollow, tlDeclarationStart, NULL);
    condGetToken(scanner, tcDotDot, errMissingDotDot);

    // <max-const>
    parseSubrangeLimit(scanner, NULL, &newType.subrange.max, &maxTypeChunkNum);
    retrieveChunk(maxTypeChunkNum, (unsigned char *)&maxType);

    // check limits
    if (maxTypeChunkNum != newType.subrange.baseType) {
        Error(errIncompatibleTypes);
        newType.subrange.min = newType.subrange.max = 0;
        storeChunk(maxTypeChunkNum, (unsigned char *)&maxType);
    } else if (newType.subrange.min > newType.subrange.max) {
        Error(errMinGtMax);

        temp = newType.subrange.min;
        newType.subrange.min = newType.subrange.max;
        newType.subrange.max = temp;
    }

    retrieveChunk(newType.subrange.baseType, (unsigned char *)&baseType);
    newType.size = baseType.size;
    storeChunk(*newTypeChunkNum, (unsigned char *)&newType);
}

void parseTypeDefinitions(SCANNER *scanner, SYMBNODE *pRoutineId) {
    SYMBNODE lastNode, idNode;
    CHUNKNUM newTypeChunkNum, lastId = 0;  // last type id node in local list

    // Loop to parse a list of type definitions
    // separated by semicolons.
    while (scanner->token.code == tcIdentifier) {
        // <id>
        if (symtabEnterNewLocal(&idNode, scanner->token.string, dcUndefined) == 0) {
            return;
        }

        // Link the routine's local type id nodes together.
        if (!pRoutineId->defn.routine.locals.typeIds) {
            pRoutineId->defn.routine.locals.typeIds = idNode.node.nodeChunkNum;
            saveSymbNodeDefn(pRoutineId);
        } else {
            if (loadSymbNode(lastId, &lastNode) == 0) {
                return;
            }
            lastNode.node.nextNode = idNode.node.nodeChunkNum;
            if (saveSymbNodeOnly(&lastNode) == 0) {
                return;
            }
        }
        lastId = idNode.node.nodeChunkNum;

        // =
        getToken(scanner);
        condGetToken(scanner, tcEqual, errMissingEqual);

        // <type>
        parseTypeSpec(scanner, &newTypeChunkNum);
        // Retrieve the idNode again because it might have changed
        // while parsing the enumeration types
        loadSymbNode(idNode.node.nodeChunkNum, &idNode);
        setType(&idNode.node.typeChunk, newTypeChunkNum);
        retrieveChunk(newTypeChunkNum, (unsigned char *)&idNode.type);
        idNode.defn.how = dcType;

        // If the type object doesn't have a name yet,
        // point it to the type id.
        if (!idNode.type.typeId) {
            idNode.type.typeId = idNode.node.nodeChunkNum;
            if (storeChunk(newTypeChunkNum, (unsigned char *)&idNode.type) == 0) {
                return;
            }
        }

        saveSymbNode(&idNode);

        // ;
        resync(scanner, tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(scanner, tcSemicolon, errMissingSemicolon);

        // Skip extra semicolons
        while (scanner->token.code == tcSemicolon) getToken(scanner);
        resync(scanner, tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
    }
}

void parseTypeSpec(SCANNER *scanner, CHUNKNUM *newTypeChunkNum) {
    SYMBNODE node;

    switch (scanner->token.code) {
        // type identifier
        case tcIdentifier:
            if (symtabStackSearchAll(scanner->token.string, &node) == 0) {
                break;
            }

            switch (node.defn.how) {
                case dcType:
                    parseIdentifierType(scanner);
                    *newTypeChunkNum = node.node.typeChunk;
                    break;
                case dcConstant:
                    parseSubrangeType(scanner, &node, newTypeChunkNum);
                    break;
                default:
                    Error(errNotATypeIdentifier);
                    getToken(scanner);
                    break;
            }
            break;
        
        case tcLParen:
            parseEnumerationType(scanner, newTypeChunkNum);
            break;
        
        case tcARRAY:
            parseArrayType(scanner, newTypeChunkNum);
            break;
        
        case tcRECORD:
            parseRecordType(scanner, newTypeChunkNum);
            break;
        
        case tcPlus:
        case tcMinus:
        case tcNumber:
        case tcString:
            parseSubrangeType(scanner, NULL, newTypeChunkNum);
            break;
        
        default:
            Error(errInvalidType);
            *newTypeChunkNum = 0;
            break;
    }
}

