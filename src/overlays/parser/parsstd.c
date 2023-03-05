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

CHUNKNUM parseStandardSubroutineCall(CHUNKNUM Icode, SYMBNODE *pRoutineId) {
    switch (pRoutineId->defn.routine.which) {
        case rcRead:
        case rcReadln:
            return parseReadReadlnCall(Icode, pRoutineId);

        case rcWrite:
        case rcWriteln:
            return parseWriteWritelnCall(Icode, pRoutineId);

        case rcEof:
        case rcEoln:
            return parseEofEolnCall(Icode);

        case rcAbs:
        case rcSqr:
            return parseAbsSqrCall(Icode);

        case rcPred:
        case rcSucc:
            return parsePredSuccCall(Icode);

        case rcChr:
            return parseChrCall(Icode);

        case rcOdd:
            return parseOddCall(Icode);

        case rcOrd:
            return parseOrdCall(Icode);
        
        case rcRound:
        case rcTrunc:
            return parseRoundTruncCall(Icode);

        default:
            return 0;
    }

    return 0;
}

CHUNKNUM parseReadReadlnCall(CHUNKNUM Icode, SYMBNODE *pRoutineId) {
    TTYPE parmType;
    SYMBNODE parmId;

    // Actual parameters are optional for readln.
    if (tokenCode != tcLParen) {
        if (pRoutineId->defn.routine.which == rcRead) {
            Error(errWrongNumberOfParams);
        }
        return dummyType;
    }

    // Loop to parse comma-separated list of actual parameters.
    do {
        // left paren or comma
        getTokenAppend(Icode);

        // Each actual parameter must be a scalar variable,
        // but parse an expression anyway for error recovery.
        if (tokenCode == tcIdentifier) {
            findSymtabNode(&parmId, tokenString);
            putSymtabNodeToIcode(Icode, &parmId);

            parseVariable(Icode, &parmId);
            getChunkCopy(getBaseType(&parmId.type), &parmType);
            if (parmType.form != fcScalar) {
                if (parmType.form != fcArray || parmType.array.elemType != charType) {
                    Error(errIncompatibleTypes);
                }
            }
        } else {
            parseExpression(Icode);
            Error(errInvalidVarParm);
        }

        // comma or right paren
        resync(tlActualVarParmFollow, tlStatementFollow, tlStatementStart);
    } while (tokenCode == tcComma);

    // right paren
    condGetTokenAppend(Icode, tcRParen, errMissingRightParen);

    return dummyType;
}

CHUNKNUM parseWriteWritelnCall(CHUNKNUM Icode, SYMBNODE *pRoutineId) {
    CHUNKNUM actualTypeChunk, baseTypeChunk;
    TTYPE actualType;

    // Actual parameters are optional only for writeln
    if (tokenCode != tcLParen) {
        if (pRoutineId->defn.routine.which == rcWrite) {
            Error(errWrongNumberOfParams);
        }
        return dummyType;
    }

    // Loop to parse comma-separated list of actual parameters.
    do {
        // left paren or comma
        getTokenAppend(Icode);

        // Value <expr> : The type must be either a
        //                scalar or a string.
        actualTypeChunk = parseExpression(Icode);
        retrieveChunk(actualTypeChunk, (unsigned char *)&actualType);
        baseTypeChunk = getBaseType(&actualType);
        if (baseTypeChunk != actualTypeChunk) {
            retrieveChunk(baseTypeChunk, (unsigned char *)&actualType);
        }
        if (actualType.form != fcScalar &&
            (actualType.form != fcEnum || baseTypeChunk != booleanType) &&
            (actualType.form != fcArray || actualType.array.elemType != charType)) {
            Error(errIncompatibleTypes);
        }

        // Optional field width <expr>
        if (tokenCode == tcColon) {
            getTokenAppend(Icode);
            if (getBaseType(getChunk(parseExpression(Icode))) != integerType) {
                Error(errIncompatibleTypes);
            }

            // Optional precision <expr>
            if (tokenCode == tcColon) {
                getTokenAppend(Icode);
                if (getBaseType(getChunk(parseExpression(Icode))) != integerType) {
                    Error(errIncompatibleTypes);
                }
            }
        }
    } while (tokenCode == tcComma);

    // right paren
    condGetTokenAppend(Icode, tcRParen, errMissingRightParen);

    return dummyType;
}

CHUNKNUM parseEofEolnCall(CHUNKNUM Icode) {
    // There should be no actual parameters, but parse
    // them anyway for error recovery.
    if (tokenCode == tcLParen) {
        Error(errWrongNumberOfParams);
        parseActualParmList(NULL, 0, Icode);
    }

    return booleanType;
}

CHUNKNUM parseAbsSqrCall(CHUNKNUM Icode) {
    CHUNKNUM parmTypeChunk, baseTypeChunk, resultType;

    // There should be one integer parameter.
    if (tokenCode == tcLParen) {
        getTokenAppend(Icode);

        parmTypeChunk = parseExpression(Icode);
        baseTypeChunk = getBaseType(getChunk(parmTypeChunk));
        if (baseTypeChunk != integerType && baseTypeChunk != realType) {
            Error(errIncompatibleTypes);
            resultType = integerType;
        } else {
            resultType = parmTypeChunk;
        }

        // There better not be any more parameters.
        if (tokenCode != tcRParen) {
            skipExtraParms(Icode);
        }

        // right paren
        condGetTokenAppend(Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return resultType;
}

CHUNKNUM parsePredSuccCall(CHUNKNUM Icode) {
    TTYPE *parmType;
    CHUNKNUM resultType, parmTypeChunk, baseTypeChunk;

    // There should be one integer or enumeration parameter
    if (tokenCode == tcLParen) {
        getTokenAppend(Icode);

        parmTypeChunk = parseExpression(Icode);
        parmType = getChunk(parmTypeChunk);
        baseTypeChunk = getBaseType(parmType);
        if (baseTypeChunk != integerType && parmType->form != fcEnum) {
            Error(errIncompatibleTypes);
            resultType = integerType;
        } else {
            resultType = parmTypeChunk;
        }

        // There better not be any more parameters
        if (tokenCode != tcRParen) {
            skipExtraParms(Icode);
        }

        // Right paren
        condGetTokenAppend(Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return resultType;
}

CHUNKNUM parseChrCall(CHUNKNUM Icode) {
    // There should be one character parameter.
    if (tokenCode == tcLParen) {
        getTokenAppend(Icode);

        if (getBaseType(getChunk(parseExpression(Icode))) != integerType) {
            Error(errIncompatibleTypes);
        }

        // There better not be any more paramters
        if (tokenCode != tcRParen) {
            skipExtraParms(Icode);
        }

        // right paren
        condGetTokenAppend(Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return charType;
}

CHUNKNUM parseOddCall(CHUNKNUM Icode) {
    // There should be one integer parameter.
    if (tokenCode == tcLParen) {
        getTokenAppend(Icode);

        if (getBaseType(getChunk(parseExpression(Icode))) != integerType) {
            Error(errIncompatibleTypes);
        }

        // There better not be any more paramters
        if (tokenCode != tcRParen) {
            skipExtraParms(Icode);
        }

        // right paren
        condGetTokenAppend(Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return booleanType;
}

CHUNKNUM parseOrdCall(CHUNKNUM Icode) {
    TTYPE parmType;
    CHUNKNUM parmTypeChunk, baseTypeChunk;

    // There should be one character or enumeration parameter.
    if (tokenCode == tcLParen) {
        getTokenAppend(Icode);

        parmTypeChunk = parseExpression(Icode);
        retrieveChunk(parmTypeChunk, (unsigned char *)&parmType);
        baseTypeChunk = getBaseType(&parmType);
        if (baseTypeChunk != charType && parmType.form != fcEnum) {
            Error(errIncompatibleTypes);
        }

        // There better not be any more paramters
        if (tokenCode != tcRParen) {
            skipExtraParms(Icode);
        }

        // right paren
        condGetTokenAppend(Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return integerType;
}

CHUNKNUM parseRoundTruncCall(CHUNKNUM Icode) {
    // There should be one real parameter
    if (tokenCode == tcLParen) {
        getTokenAppend(Icode);

        if (getBaseType(getChunk(parseExpression(Icode))) != realType) {
            Error(errIncompatibleTypes);
        }

        // There better not be any more parameters
        if (tokenCode != tcRParen) {
            skipExtraParms(Icode);
        }

        // )
        condGetTokenAppend(Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return integerType;
}

void skipExtraParms(CHUNKNUM Icode) {
    Error(errWrongNumberOfParams);

    while (tokenCode == tcComma) {
        getTokenAppend(Icode);
        parseExpression(Icode);
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
    {"pred",    rcPred,    dcFunction},
    {"succ",    rcSucc,    dcFunction},
    {"round",   rcRound,   dcFunction},
    {"sqr",     rcSqr,     dcFunction},
    {"trunc",   rcTrunc,   dcFunction},
    {NULL},
};

void initStandardRoutines(CHUNKNUM symtabChunkNum) {
    int i = 0;
    SYMBNODE routineId;

    do {
        struct TStdRtn *pSR = &stdRtnList[i];
        enterSymtab(symtabChunkNum, &routineId, pSR->pName, pSR->dc);
        routineId.defn.routine.which = pSR->rc;
        routineId.defn.routine.parmCount = 0;
        routineId.defn.routine.totalParmSize = 0;
        routineId.defn.routine.totalLocalSize = 0;
        routineId.defn.routine.locals.parmIds = 0;
        routineId.defn.routine.locals.constantIds = 0;
        routineId.defn.routine.locals.typeIds = 0;
        routineId.defn.routine.locals.variableIds = 0;
        routineId.defn.routine.locals.routineIds = 0;
        routineId.defn.routine.symtab = 0;
        routineId.defn.routine.Icode = 0;
        setType(&routineId.node.typeChunk, dummyType);
        saveSymbNode(&routineId);
    } while (stdRtnList[++i].pName);
}

