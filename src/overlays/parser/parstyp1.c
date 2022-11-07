#include <common.h>
#include <parser.h>
#include <chunks.h>
#include <parscommon.h>
#include <symtab.h>
#include <types.h>
#include <string.h>

void parseEnumerationType(SCANNER *scanner, CHUNKNUM *newTypeChunkNum) {
    DEFN defn;
    TTYPE newType;
    CHUNKNUM lastChunk = 0, newChunkNum;
    SYMTABNODE newNode;
    int constValue = -1;

    getToken(scanner);
    resync(scanner, tlEnumConstStart, NULL, NULL);

    *newTypeChunkNum = makeType(fcEnum, sizeof(int), 0);
    retrieveChunk(*newTypeChunkNum, (unsigned char *)&newType);

    // Loop to parse list of constant identifiers separated by commas.
    while (scanner->token.code == tcIdentifier) {
        symtabEnterNewLocal(&newNode, scanner->token.string, dcUndefined);
        ++constValue;

        retrieveChunk(newNode.defnChunk, (unsigned char *)&defn);
        if (defn.how == dcUndefined) {
            defn.how = dcConstant;
            defn.constant.value.integer = constValue;
            storeChunk(newNode.defnChunk, (unsigned char *)&defn);
            setType(&newNode.typeChunk, *newTypeChunkNum);
            storeChunk(newNode.nodeChunkNum, (unsigned char *)&newNode);

            // Link constant identifier symbol table nodes together.
            if (!lastChunk) {
                newType.enumeration.constIds = lastChunk = newNode.nodeChunkNum;
            } else {
                newChunkNum = newNode.nodeChunkNum;
                retrieveChunk(lastChunk, (unsigned char *)&newNode);
                newNode.nextNode = newChunkNum;
                storeChunk(lastChunk, (unsigned char *)&newNode);
                lastChunk = newChunkNum;
            }
        }

        memset(&newNode, 0, sizeof(SYMTABNODE));

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

void parseSubrangeLimit(SCANNER *scanner, SYMTABNODE *pLimit, int *limit, CHUNKNUM *limitTypeChunkNum) {
    SYMTABNODE node;
    DEFN defn;
    TTYPE type;
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
            if (retrieveChunk(pLimit->defnChunk, (unsigned char *)&defn) == 0) {
                Error(errInvalidSubrangeType);
                break;
            }
            if (defn.how == dcUndefined) {
                defn.how = dcConstant;
                storeChunk(pLimit->defnChunk, (unsigned char *)&defn);
                *limitTypeChunkNum = dummyType;
                break;
            }
            if (pLimit->typeChunk == dummyType) {
                Error(errInvalidSubrangeType);
                break;
            }
            if (retrieveChunk(pLimit->typeChunk, (unsigned char *)&type) == 0) {
                Error(errInvalidSubrangeType);
                break;
            }
            if (type.form == fcArray) {
                Error(errInvalidSubrangeType);
                break;
            }
            if (defn.how == dcConstant) {
                // Use the value of the constant identifer.
                if (pLimit->typeChunk == integerType) {
                    *limit = sign == tcMinus ? -defn.constant.value.integer :
                        defn.constant.value.integer;
                } else if (pLimit->typeChunk == charType) {
                    if (sign != tcDummy) {
                        Error(errInvalidSubrangeType);
                        break;
                    }
                    *limit = defn.constant.value.character;
                } else if (type.form == fcEnum) {
                    if (sign != tcDummy) {
                        Error(errInvalidSubrangeType);
                        break;
                    }
                    *limit = defn.constant.value.integer;
                }
                *limitTypeChunkNum = pLimit->typeChunk;
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

void parseSubrangeType(SCANNER *scanner, SYMTABNODE *pMinId, CHUNKNUM *newTypeChunkNum) {
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

void parseTypeDefinitions(SCANNER *scanner, SYMTABNODE *pRoutineId) {
    DEFN defn;
    TTYPE typeNode;
    SYMTABNODE lastNode, idNode;
    CHUNKNUM newTypeChunkNum, lastId = 0;  // last type id node in local list

    // Loop to parse a list of type definitions
    // separated by semicolons.
    while (scanner->token.code == tcIdentifier) {
        // <id>
        if (symtabEnterNewLocal(&idNode, scanner->token.string, dcUndefined) == 0) {
            return;
        }

        // Link the routine's local type id nodes together.
        if (retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn) == 0) {
            return;
        }
        if (!defn.routine.locals.typeIds) {
            defn.routine.locals.typeIds = idNode.nodeChunkNum;
            storeChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
        } else {
            if (retrieveChunk(lastId, (unsigned char *)&lastNode) == 0) {
                return;
            }
            lastNode.nextNode = idNode.nodeChunkNum;
            if (storeChunk(lastId, (unsigned char *)&lastNode) == 0) {
                return;
            }
        }
        lastId = idNode.nodeChunkNum;

        // =
        getToken(scanner);
        condGetToken(scanner, tcEqual, errMissingEqual);

        // <type>
        parseTypeSpec(scanner, &newTypeChunkNum);
        // Retrieve the idNode again because it might have changed
        // while parsing the enumeration types
        retrieveChunk(idNode.nodeChunkNum, (unsigned char *)&idNode);
        retrieveChunk(newTypeChunkNum, (unsigned char *)&typeNode);
        setType(&idNode.typeChunk, newTypeChunkNum);
        storeChunk(idNode.nodeChunkNum, (unsigned char *)&idNode);
        retrieveChunk(idNode.defnChunk, (unsigned char *)&defn);
        defn.how = dcType;
        storeChunk(idNode.defnChunk, (unsigned char *)&defn);

        // If the type object doesn't have a name yet,
        // point it to the type id.
        if (!typeNode.typeId) {
            typeNode.typeId = idNode.nodeChunkNum;
            if (storeChunk(newTypeChunkNum, (unsigned char *)&typeNode) == 0) {
                return;
            }
        }

        // ;
        resync(scanner, tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(scanner, tcSemicolon, errMissingSemicolon);

        // Skip extra semicolons
        while (scanner->token.code == tcSemicolon) getToken(scanner);
        resync(scanner, tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
    }
}

void parseTypeSpec(SCANNER *scanner, CHUNKNUM *newTypeChunkNum) {
    DEFN defn;
    SYMTABNODE node;

    switch (scanner->token.code) {
        // type identifier
        case tcIdentifier:
            if (symtabStackSearchAll(scanner->token.string, &node) == 0) {
                break;
            }
            if (retrieveChunk(node.defnChunk, (unsigned char *)&defn) == 0) {
                break;
            }

            switch (defn.how) {
                case dcType:
                    parseIdentifierType(scanner);
                    *newTypeChunkNum = node.typeChunk;
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

