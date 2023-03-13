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

#define STDPARM_INTEGER 0x1
#define STDPARM_ENUM    0x2
#define STDPARM_REAL    0x4
#define STDPARM_CHAR    0x8

static CHUNKNUM checkStdParms(CHUNKNUM Icode, char allowedParms, CHUNKNUM returnType);

CHUNKNUM parseStandardSubroutineCall(CHUNKNUM Icode) {
    switch (routineNode.defn.routine.which) {
        case rcRead:
        case rcReadln:
            return parseReadReadlnCall(Icode);

        case rcWrite:
        case rcWriteln:
            return parseWriteWritelnCall(Icode);

        case rcEof:
        case rcEoln:
            return parseEofEolnCall(Icode);

        case rcAbs:
        case rcSqr:
            return checkStdParms(Icode, STDPARM_INTEGER | STDPARM_REAL, 0);

        case rcPred:
        case rcSucc:
            return checkStdParms(Icode, STDPARM_INTEGER | STDPARM_ENUM, 0);

        case rcChr:
            return checkStdParms(Icode, STDPARM_INTEGER, charType);

        case rcOdd:
            return checkStdParms(Icode, STDPARM_INTEGER, booleanType);

        case rcOrd:
            return checkStdParms(Icode, STDPARM_CHAR | STDPARM_ENUM, integerType);
        
        case rcRound:
        case rcTrunc:
            return checkStdParms(Icode, STDPARM_REAL, integerType);

        default:
            return 0;
    }

    return 0;
}

static CHUNKNUM checkStdParms(CHUNKNUM Icode, char allowedParms, CHUNKNUM returnType) {
    TTYPE parmType;
    CHUNKNUM parmTypeChunk, baseTypeChunk, resultType;

    // There should be one integer parameter.
    if (parserToken == tcLParen) {
        getTokenAppend(Icode);

        parmTypeChunk = parseExpression(Icode);
        getChunkCopy(parmTypeChunk, &parmType);
        baseTypeChunk = getBaseType(getChunk(parmTypeChunk));
        if ((allowedParms & STDPARM_CHAR && baseTypeChunk == charType) ||
            (allowedParms & STDPARM_ENUM && parmType.form == fcEnum) ||
            (allowedParms & STDPARM_INTEGER && baseTypeChunk == integerType) ||
            (allowedParms & STDPARM_REAL && baseTypeChunk == realType)) {
            resultType = returnType ? returnType : parmTypeChunk;
        } else {
            Error(errIncompatibleTypes);
            resultType = integerType;
        }

        // There better not be any more parameters.
        if (parserToken != tcRParen) {
            skipExtraParms(Icode);
        }

        // right paren
        condGetTokenAppend(Icode, tcRParen, errMissingRightParen);
    } else {
        Error(errWrongNumberOfParams);
    }

    return resultType;
}

CHUNKNUM parseReadReadlnCall(CHUNKNUM Icode) {
    TTYPE parmType;
    SYMBNODE parmId;

    // Actual parameters are optional for readln.
    if (parserToken != tcLParen) {
        if (routineNode.defn.routine.which == rcRead) {
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
        if (parserToken == tcIdentifier) {
            findSymtabNode(&parmId, parserString);
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
    } while (parserToken == tcComma);

    // right paren
    condGetTokenAppend(Icode, tcRParen, errMissingRightParen);

    return dummyType;
}

CHUNKNUM parseWriteWritelnCall(CHUNKNUM Icode) {
    CHUNKNUM actualTypeChunk, baseTypeChunk;
    TTYPE actualType;

    // Actual parameters are optional only for writeln
    if (parserToken != tcLParen) {
        if (routineNode.defn.routine.which == rcWrite) {
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
        if (parserToken == tcColon) {
            getTokenAppend(Icode);
            if (getBaseType(getChunk(parseExpression(Icode))) != integerType) {
                Error(errIncompatibleTypes);
            }

            // Optional precision <expr>
            if (parserToken == tcColon) {
                getTokenAppend(Icode);
                if (getBaseType(getChunk(parseExpression(Icode))) != integerType) {
                    Error(errIncompatibleTypes);
                }
            }
        }
    } while (parserToken == tcComma);

    // right paren
    condGetTokenAppend(Icode, tcRParen, errMissingRightParen);

    return dummyType;
}

CHUNKNUM parseEofEolnCall(CHUNKNUM Icode) {
    // There should be no actual parameters, but parse
    // them anyway for error recovery.
    if (parserToken == tcLParen) {
        Error(errWrongNumberOfParams);
        parseActualParmList(0, 0, Icode);
    }

    return booleanType;
}

void skipExtraParms(CHUNKNUM Icode) {
    Error(errWrongNumberOfParams);

    while (parserToken == tcComma) {
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
        memset(&routineId.defn, 0, sizeof(DEFN));
        enterSymtab(symtabChunkNum, &routineId, pSR->pName, pSR->dc);
        routineId.defn.routine.which = pSR->rc;
        setType(&routineId.node.typeChunk, dummyType);
        saveSymbNode(&routineId);
    } while (stdRtnList[++i].pName);
}

