#include <common.h>
#include <parser.h>
#include <chunks.h>
#include <parscommon.h>
#include <symtab.h>
#include <types.h>
#include <string.h>

void parseEnumerationType(CHUNKNUM *newTypeChunkNum) {
    TTYPE newType;
    CHUNKNUM lastChunk = 0, newChunkNum;
    SYMBNODE newNode;
    int constValue = -1;

    getToken();
    resync(tlEnumConstStart, NULL, NULL);

    *newTypeChunkNum = makeType(fcEnum, sizeof(int), 0);
    retrieveChunk(*newTypeChunkNum, (unsigned char *)&newType);

    // Loop to parse list of constant identifiers separated by commas.
    while (tokenCode == tcIdentifier) {
        symtabEnterNewLocal(&newNode, tokenString, dcUndefined);
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
                ((SYMTABNODE *)getChunk(lastChunk))->nextNode = newChunkNum;
                lastChunk = newChunkNum;
            }
        }

        memset(&newNode, 0, sizeof(SYMBNODE));

        // ,
        getToken();
        resync(tlEnumConstFollow, NULL, NULL);
        if (tokenCode == tcComma) {
            // Saw comma.  Skip extra commas and look for an identifier
            do {
                getToken();
                resync(tlEnumConstStart, tlEnumConstFollow, NULL);
                if (tokenCode == tcComma) Error(errMissingIdentifier);
            } while (tokenCode == tcComma);
            if (tokenCode != tcIdentifier) Error(errMissingIdentifier);
        }
        else if (tokenCode == tcIdentifier) Error(errMissingComma);
    }

    // )
    condGetToken(tcRParen, errMissingRightParen);

    newType.enumeration.max = constValue;
    storeChunk(*newTypeChunkNum, (unsigned char *)&newType);
}

void parseIdentifierType(void) {
    getToken();
}

void parseSubrangeLimit(SYMBNODE *pLimit, int *limit, CHUNKNUM *limitTypeChunkNum) {
    SYMBNODE node;
    TTokenCode sign = tcDummy;

    *limit = 0;
    *limitTypeChunkNum = dummyType;

    // Unary + or -
    if (tokenIn(tokenCode, tlUnaryOps)) {
        if (tokenCode == tcMinus) sign = tcMinus;
        getToken();
    }

    switch (tokenCode) {
        case tcNumber:
            // Numeric constant: integer type only
            if (tokenType == tyInteger) {
                *limit = sign == tcMinus ? -tokenValue.integer :
                    tokenValue.integer;
                *limitTypeChunkNum = integerType;
            } else {
                Error(errInvalidSubrangeType);
            }
            break;

        case tcIdentifier:
            // identifier limit: must be an integer, character, or
            // enumeration type.
            if (pLimit == NULL) {
                if (findSymtabNode(&node, tokenString) == 0) {
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
            if (pLimit->node.typeChunk == dummyType || pLimit->node.typeChunk == realType) {
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

            if (strlen(tokenString) != 3) {
                // length inludes quotes
                Error(errInvalidSubrangeType);
            }

            *limit = tokenString[1];
            *limitTypeChunkNum = charType;
            break;
        
        default:
            Error(errMissingConstant);
            break;
    }

    getToken();
}

void parseSubrangeType(SYMBNODE *pMinId, CHUNKNUM *newTypeChunkNum) {
    int temp;
    CHUNKNUM newMinChunkNum, maxTypeChunkNum;
    TTYPE newType;

    *newTypeChunkNum = makeType(fcSubrange, 0, 0);
    retrieveChunk(*newTypeChunkNum, (unsigned char *)&newType);

    // <min-const>
    parseSubrangeLimit(pMinId, &newType.subrange.min, &newMinChunkNum);
    setType(&newType.subrange.baseType, newMinChunkNum);

    // ..
    resync(tlSubrangeLimitFollow, tlDeclarationStart, NULL);
    condGetToken(tcDotDot, errMissingDotDot);

    // <max-const>
    parseSubrangeLimit(NULL, &newType.subrange.max, &maxTypeChunkNum);

    // check limits
    if (maxTypeChunkNum != newType.subrange.baseType) {
        Error(errIncompatibleTypes);
        newType.subrange.min = newType.subrange.max = 0;
    } else if (newType.subrange.min > newType.subrange.max) {
        Error(errMinGtMax);

        temp = newType.subrange.min;
        newType.subrange.min = newType.subrange.max;
        newType.subrange.max = temp;
    }

    newType.size = ((TTYPE *)getChunk(newType.subrange.baseType))->size;
    storeChunk(*newTypeChunkNum, (unsigned char *)&newType);
}

void parseTypeDefinitions(SYMBNODE *pRoutineId) {
    SYMBNODE idNode;
    CHUNKNUM newTypeChunkNum, lastId = 0;  // last type id node in local list

    // Loop to parse a list of type definitions
    // separated by semicolons.
    while (tokenCode == tcIdentifier) {
        // <id>
        if (symtabEnterNewLocal(&idNode, tokenString, dcUndefined) == 0) {
            return;
        }

        // Link the routine's local type id nodes together.
        if (!pRoutineId->defn.routine.locals.typeIds) {
            pRoutineId->defn.routine.locals.typeIds = idNode.node.nodeChunkNum;
            saveSymbNodeDefn(pRoutineId);
        } else {
            ((SYMTABNODE *)getChunk(lastId))->nextNode = idNode.node.nodeChunkNum;
        }
        lastId = idNode.node.nodeChunkNum;

        // =
        getToken();
        condGetToken(tcEqual, errMissingEqual);

        // <type>
        parseTypeSpec(&newTypeChunkNum);
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
        resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(tcSemicolon, errMissingSemicolon);

        // Skip extra semicolons
        while (tokenCode == tcSemicolon) getToken();
        resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
    }
}

void parseTypeSpec(CHUNKNUM *newTypeChunkNum) {
    SYMBNODE node;

    switch (tokenCode) {
        // type identifier
        case tcIdentifier:
            if (symtabStackSearchAll(tokenString, &node) == 0) {
                break;
            }

            switch (node.defn.how) {
                case dcType:
                    parseIdentifierType();
                    *newTypeChunkNum = node.node.typeChunk;
                    break;
                case dcConstant:
                    parseSubrangeType(&node, newTypeChunkNum);
                    break;
                default:
                    Error(errNotATypeIdentifier);
                    getToken();
                    break;
            }
            break;
        
        case tcLParen:
            parseEnumerationType(newTypeChunkNum);
            break;
        
        case tcARRAY:
            parseArrayType(newTypeChunkNum);
            break;
        
        case tcRECORD:
            parseRecordType(newTypeChunkNum);
            break;
        
        case tcPlus:
        case tcMinus:
        case tcNumber:
        case tcString:
            parseSubrangeType(NULL, newTypeChunkNum);
            break;
        
        default:
            Error(errInvalidType);
            *newTypeChunkNum = 0;
            break;
    }
}

