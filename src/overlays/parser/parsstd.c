/**
 * parsstd.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for parsing standard procedures and functions.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <error.h>
#include <icode.h>
#include <string.h>
#include <parscommon.h>
#include <common.h>

CHUNKNUM parseStandardSubroutineCall(SCANNER *scanner, CHUNKNUM Icode, SYMTABNODE *pRoutineId) {

    DEFN defn;

    retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);

    switch (defn.routine.which) {
        case rcRead:
        case rcReadln:
            return parseReadReadlnCall(scanner, Icode, pRoutineId);

        case rcWrite:
        case rcWriteln:
            return parseWriteWritelnCall(scanner, Icode, pRoutineId);

        case rcEof:
        case rcEoln:
            return parseEofEolnCall(scanner, Icode);

        case rcAbs:
        case rcSqr:
            return parseAbsSqrCall(scanner, Icode);

        case rcPred:
        case rcSucc:
            return parsePredSuccCall(scanner, Icode);

        case rcChr:
            return parseChrCall(scanner, Icode);

        case rcOdd:
            return parseOddCall(scanner, Icode);

        case rcOrd:
            return parseOrdCall(scanner, Icode);

        default:
            return 0;
    }

    return 0;
}

CHUNKNUM parseReadReadlnCall(SCANNER *scanner, CHUNKNUM Icode, SYMTABNODE *pRoutineId) {
    DEFN defn;
    TTYPE parmType, resultType;
    SYMTABNODE parmId;

    // Actual parameters are optional for readln.
    if (scanner->token.code != tcLParen) {
        retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
        if (defn.routine.which == rcRead) {
            Error(errWrongNumberOfParams);
        }
        return dummyType;
    }

    // Loop to parse comma-separated list of actual parameters.
    do {
        // left paren or comma
        getTokenAppend(scanner, Icode);

        // Each actual parameter must be a scalar variable,
        // but parse an expression anyway for error recovery.
        if (scanner->token.code == tcIdentifier) {
            findSymtabNode(&parmId, scanner->token.string);
            putSymtabNodeToIcode(Icode, &parmId);

            parseVariable(scanner, Icode, &parmId, &resultType);
            retrieveChunk(parmId.typeChunk, (unsigned char *)&parmType);
            if (parmType.form == fcSubrange) {
                retrieveChunk(parmType.subrange.baseType, (unsigned char *)&parmType);
            }
            if (parmType.form != fcScalar) {
                Error(errIncompatibleTypes);
            }
        } else {
            parseExpression(scanner, Icode, &resultType);
            Error(errInvalidVarParm);
        }

        // comma or right paren
        resync(scanner, tlActualVarParmFollow, tlStatementFollow, tlStatementStart);
    } while (scanner->token.code == tcComma);

    // right paren
    condGetTokenAppend(scanner, Icode, tcRParen, errMissingRightParen);

    return dummyType;
}

CHUNKNUM parseWriteWritelnCall(SCANNER *scanner, CHUNKNUM Icode, SYMTABNODE *pRoutineId) {
    DEFN defn;
    TTYPE actualType;

    // Actual parameters are optional only for writeln
    if (scanner->token.code != tcLParen) {
        retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
        if (defn.routine.which == rcWrite) {
            Error(errWrongNumberOfParams);
        }
        return dummyType;
    }

    // Loop to parse comma-separated list of actual parameters.
    do {
        // left paren or comma
        getTokenAppend(scanner, Icode);

        // Value <expr> : The type must be either a non-boolean
        //                scalar or a string.
        parseExpression(scanner, Icode, &actualType);
        if (actualType.form == fcSubrange) {
            retrieveChunk(actualType.subrange.baseType, (unsigned char *)&actualType);
        }
        if ((actualType.form != fcScalar || actualType.typeId == booleanType) &&
            (actualType.form != fcArray || actualType.array.elemType != charType)) {
            Error(errIncompatibleTypes);
        }

        // Optional field width <expr>
        if (scanner->token.code == tcColon) {
            getTokenAppend(scanner, Icode);
            parseExpression(scanner, Icode, &actualType);
            if (actualType.form == fcSubrange) {
                retrieveChunk(actualType.subrange.baseType, (unsigned char *)&actualType);
            }
            if (actualType.typeId != integerType) {
                Error(errIncompatibleTypes);
            }

            // Optional precision <expr>
            if (scanner->token.code == tcColon) {
                getTokenAppend(scanner, Icode);
            }
            parseExpression(scanner, Icode, &actualType);
            if (actualType.form == fcSubrange) {
                retrieveChunk(actualType.subrange.baseType, (unsigned char *)&actualType);
            }
            if (actualType.typeId != integerType) {
                Error(errIncompatibleTypes);
            }
        }
    } while (scanner->token.code == tcComma);

    // right paren
    condGetTokenAppend(scanner, Icode, tcRParen, errMissingRightParen);

    return dummyType;
}

CHUNKNUM parseEofEolnCall(SCANNER *scanner, CHUNKNUM Icode) {
    // There should be no actual parameters, but parse
    // them anyway for error recovery.
    if (scanner->token.code == tcLParen) {
        Error(errWrongNumberOfParams);
        parseActualParmList(scanner, NULL, 0, Icode);
    }

    return booleanType;
}

CHUNKNUM parseAbsSqrCall(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE parmType;
    CHUNKNUM resultType;

    // There should be one integer parameter.
    if (scanner->token.code == tcLParen) {
        getTokenAppend(scanner, Icode);

        parseExpression(scanner, Icode, &parmType);
        if (parmType.form == fcSubrange) {
            retrieveChunk(parmType.subrange.baseType, (unsigned char *)&parmType);
        }
        if (parmType.typeId != integerType) {
            Error(errIncompatibleTypes);
            resultType = integerType;
        } else {
            resultType = parmType.typeId;
        }

        // There better not be any more parameters.
        if (scanner->token.code != tcRParen) {
            skipExtraParms(scanner, Icode);
        }

        // right paren
        condGetTokenAppend(scanner, Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return resultType;
}

CHUNKNUM parsePredSuccCall(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE parmType;
    CHUNKNUM resultType;

    // There should be one integer or enumeration parameter
    if (scanner->token.code == tcLParen) {
        getTokenAppend(scanner, Icode);

        parseExpression(scanner, Icode, &parmType);
        if (parmType.form == fcSubrange) {
            retrieveChunk(parmType.subrange.baseType, (unsigned char *)&parmType);
        }
        if (parmType.typeId != integerType && parmType.form != fcEnum) {
            Error(errIncompatibleTypes);
            resultType = integerType;
        } else {
            resultType = parmType.typeId;
        }

        // There better not be any more parameters
        if (scanner->token.code != tcRParen) {
            skipExtraParms(scanner, Icode);
        }

        // Right paren
        condGetTokenAppend(scanner, Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return resultType;
}

CHUNKNUM parseChrCall(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE parmType;

    // There should be one character parameter.
    if (scanner->token.code == tcLParen) {
        getTokenAppend(scanner, Icode);

        parseExpression(scanner, Icode, &parmType);
        if (parmType.form == fcSubrange) {
            retrieveChunk(parmType.subrange.baseType, (unsigned char *)&parmType);
        }
        if (parmType.typeId != integerType) {
            Error(errIncompatibleTypes);
        }

        // There better not be any more paramters
        if (scanner->token.code != tcRParen) {
            skipExtraParms(scanner, Icode);
        }

        // right paren
        condGetTokenAppend(scanner, Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return charType;
}

CHUNKNUM parseOddCall(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE parmType;

    // There should be one integer parameter.
    if (scanner->token.code == tcLParen) {
        getTokenAppend(scanner, Icode);

        parseExpression(scanner, Icode, &parmType);
        if (parmType.form == fcSubrange) {
            retrieveChunk(parmType.subrange.baseType, (unsigned char *)&parmType);
        }
        if (parmType.typeId != integerType) {
            Error(errIncompatibleTypes);
        }

        // There better not be any more paramters
        if (scanner->token.code != tcRParen) {
            skipExtraParms(scanner, Icode);
        }

        // right paren
        condGetTokenAppend(scanner, Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return booleanType;
}

CHUNKNUM parseOrdCall(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE parmType;

    // There should be one character or enumeration parameter.
    if (scanner->token.code == tcLParen) {
        getTokenAppend(scanner, Icode);

        parseExpression(scanner, Icode, &parmType);
        if (parmType.form == fcSubrange) {
            retrieveChunk(parmType.subrange.baseType, (unsigned char *)&parmType);
        }
        if (parmType.typeId != charType && parmType.form != fcEnum) {
            Error(errIncompatibleTypes);
        }

        // There better not be any more paramters
        if (scanner->token.code != tcRParen) {
            skipExtraParms(scanner, Icode);
        }

        // right paren
        condGetTokenAppend(scanner, Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return integerType;
}

void skipExtraParms(SCANNER *scanner, CHUNKNUM Icode) {
    TTYPE type;

    Error(errWrongNumberOfParams);

    while (scanner->token.code == tcComma) {
        getTokenAppend(scanner, Icode);
        parseExpression(scanner, Icode, &type);
    }
}

static struct TStdRtn {
    char *pName;
    TRoutineCode rc;
    TDefnCode dc;
} stdRtnList[] = {
    {"read",    rcRead,    dcProcedure},
    {"readln",  rcReadln,  dcProcedure},
    {"write",   rcWrite,   dcProcedure},
    {"writeln", rcWriteln, dcProcedure},
    {"abs",     rcAbs,     dcFunction},
    {"chr",     rcChr,     dcFunction},
    {"eof",     rcEof,     dcFunction},
    {"eoln",    rcEoln,    dcFunction},
    {"odd",     rcOdd,     dcFunction},
    {"ord",     rcOrd,     dcFunction},
    {"prec",    rcPred,    dcFunction},
    {"succ",    rcSucc,    dcFunction},
    {NULL},
};

void initStandardRoutines(CHUNKNUM symtabChunkNum) {
    int i = 0;
    DEFN defn;
    SYMTABNODE routineId;

    do {
        struct TStdRtn *pSR = &stdRtnList[i];
        enterSymtab(symtabChunkNum, &routineId, pSR->pName, pSR->dc);
        retrieveChunk(routineId.defnChunk, (unsigned char *)&defn);
        defn.routine.which = pSR->rc;
        defn.routine.parmCount = 0;
        defn.routine.totalParmSize = 0;
        defn.routine.totalLocalSize = 0;
        defn.routine.locals.parmIds = 0;
        defn.routine.locals.constantIds = 0;
        defn.routine.locals.typeIds = 0;
        defn.routine.locals.variableIds = 0;
        defn.routine.locals.routineIds = 0;
        defn.routine.symtab = 0;
        defn.routine.Icode = 0;
        storeChunk(routineId.defnChunk, (unsigned char *)&defn);
        setType(&routineId.typeChunk, dummyType);
        storeChunk(routineId.nodeChunkNum, (unsigned char *)&routineId);
    } while (stdRtnList[++i].pName);
}

