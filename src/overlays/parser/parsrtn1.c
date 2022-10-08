#include <string.h>
#include <common.h>
#include <symtab.h>
#include <parser.h>
#include <parscommon.h>

void parseBlock(SCANNER *scanner, SYMTABNODE *pRoutineId) {
    DEFN defn;

    // declarations
    parseDeclarations(scanner, pRoutineId);

    // <compound-statement>   reset the icode and append BEGIN to it,
    //                        and then parse the compound statement.
    resync(scanner, tlStatementStart, NULL, NULL);
    if (scanner->token.code != tcBEGIN) Error(errMissingBEGIN);

    retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
    makeIcode(&defn.routine.Icode);
    storeChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
    parseCompound(scanner, defn.routine.Icode);
}

void parseFuncOrProcHeader(SCANNER *scanner, SYMTABNODE *pRoutineId, char isFunc) {
    DEFN defn;
    int parmCount;  // count of formal params
    int totalParmSize;  // total byte size of all parameters
    char forwardFlag = 0;
    SYMTABNODE typeId;
    CHUNKNUM parmList;

    getToken(scanner);

    // <id>   If the routine id has already been declared in this scope,
    //        it must have been a forward declaration.
    if (scanner->token.code == tcIdentifier) {
        if (!symtabSearchLocal(pRoutineId, scanner->token.string)) {
            // Not already declared
            symtabEnterLocal(pRoutineId, scanner->token.string,
                isFunc ? dcFunction : dcProcedure);
            retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
            defn.routine.totalLocalSize = 0;
        } else {
            retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
            if (defn.how == isFunc ? dcFunction : dcProcedure && defn.routine.which == rcForward) {
                forwardFlag = 1;
            } else {
                Error(errRedefinedIdentifier);
            }
        }

        getToken(scanner);
    } else {
        Error(errMissingIdentifier);
    }

    // ( or : or ;
    resync(scanner, isFunc ? tlFuncIdFollow : tlProgProcIdFollow,
        tlDeclarationStart, tlStatementStart);

    // Enter the next nesting level and open a new scope for the function
    symtabStackEnterScope();

    // Optional (<id-list>) : If there was a forward declaration, there
    //                        must not be a parameter list, but if there
    //                        is, parse it anyway for error recovery.
    if (scanner->token.code == tcLParen) {
        parseFormalParmList(scanner, &parmList, &parmCount, &totalParmSize);
        if (forwardFlag) {
            Error(errAlreadyForwarded);
        } else {
            // Not forwarded
            defn.routine.parmCount = parmCount;
            defn.routine.totalParmSize = totalParmSize;
            defn.routine.locals.parmIds = parmList;
        }
    } else if (!forwardFlag) {
        // No parameters and no forward declaration
        defn.routine.parmCount = 0;
        defn.routine.totalParmSize = 0;
        defn.routine.locals.parmIds = 0;
    }

    defn.routine.locals.constantIds = 0;
    defn.routine.locals.typeIds = 0;
    defn.routine.locals.variableIds = 0;
    defn.routine.locals.routineIds = 0;

    storeChunk(pRoutineId->defnChunk, (unsigned char *)&defn);

    if (isFunc) {
        // Optional <type-id> : If there was a forward declaration, there must
        //                      not be a type id, but if there was, parse it
        //                      anyway for error recovery.
        if (!forwardFlag || scanner->token.code == tcColon) {
            condGetToken(scanner, tcColon, errMissingColon);
            if (scanner->token.code == tcIdentifier) {
                symtabStackFind(scanner->token.string, &typeId);
                retrieveChunk(typeId.defnChunk, (unsigned char *)&defn);
                if (defn.how != dcType) Error(errInvalidType);
                if (forwardFlag) {
                    Error(errAlreadyForwarded);
                } else {
                    setType(&pRoutineId->typeChunk, typeId.typeChunk);
                    storeChunk(pRoutineId->nodeChunkNum, (unsigned char *)pRoutineId);
                }

                getToken(scanner);
            } else {
                Error(errMissingIdentifier);
                setType(&pRoutineId->typeChunk, dummyType);
                storeChunk(pRoutineId->nodeChunkNum, (unsigned char *)pRoutineId);
            }
        }
    } else {
        setType(&pRoutineId->typeChunk, dummyType);
        storeChunk(pRoutineId->nodeChunkNum, (unsigned char *)pRoutineId);
    }
}

void parseProgram(SCANNER *scanner, SYMTABNODE *pProgramId) {
    DEFN defn;

    // <program-header>
    parseProgramHeader(scanner, pProgramId);

    // ;
    resync(scanner, tlHeaderFollow, tlDeclarationStart, tlStatementStart);
    if (scanner->token.code == tcSemicolon) {
        getToken(scanner);
    } else if (tokenIn(scanner->token.code, tlDeclarationStart) ||
        tokenIn(scanner->token.code, tlStatementStart)) {
        Error(errMissingSemicolon);
    }

    // <block>
    parseBlock(scanner, pProgramId);
    retrieveChunk(pProgramId->defnChunk, (unsigned char *)&defn);
    symtabExitScope(&defn.routine.symtab);
    storeChunk(pProgramId->defnChunk, (unsigned char *)&defn);

    // .
    resync(scanner, tlProgramEnd, NULL, NULL);
    condGetTokenAppend(scanner, defn.routine.Icode, tcPeriod, errMissingPeriod);
}

void parseProgramHeader(SCANNER *scanner, SYMTABNODE *pProgramId) {
    DEFN defn;
    SYMTABNODE parmId, prevParmId;

    // PROGRAM
    condGetToken(scanner, tcPROGRAM, errMissingPROGRAM);

    // <id>
    if (scanner->token.code == tcIdentifier) {
        symtabEnterNewLocal(pProgramId, scanner->token.string, dcProgram);

        retrieveChunk(pProgramId->defnChunk, (unsigned char *)&defn);
        defn.routine.which = rcDeclared;
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
        storeChunk(pProgramId->defnChunk, (unsigned char *)&defn);
        setType(&pProgramId->typeChunk, dummyType);
        storeChunk(pProgramId->nodeChunkNum, (unsigned char *)pProgramId);
        getToken(scanner);
    } else {
        Error(errMissingIdentifier);
    }

    // ( or ;
    resync(scanner, tlProgProcIdFollow, tlDeclarationStart, tlStatementStart);

    // Enter the nesting level 1 and open a new scope for the program
    symtabStackEnterScope();

    // Optional (<id-list>)
    if (scanner->token.code == tcLParen) {
        // Loop to parse a comma-separated identifier list.
        do {
            getToken(scanner);
            if (scanner->token.code == tcIdentifier) {
                symtabEnterNewLocal(&parmId, scanner->token.string, dcVarParm);
                setType(&parmId.typeChunk, dummyType);
                storeChunk(parmId.nodeChunkNum, (unsigned char *)&parmId);
                getToken(scanner);

                // Link program parm id nodes together
                if (!defn.routine.locals.parmIds) {
                    defn.routine.locals.parmIds = parmId.nodeChunkNum;
                    storeChunk(parmId.defnChunk, (unsigned char *)&defn);
                } else {
                    prevParmId.nextNode = parmId.nodeChunkNum;
                    storeChunk(prevParmId.nodeChunkNum, (unsigned char *)&prevParmId);
                }
                memcpy(&prevParmId, &parmId, sizeof(SYMTABNODE));
            } else {
                Error(errMissingIdentifier);
            }
        } while (scanner->token.code == tcComma);

        storeChunk(pProgramId->defnChunk, (unsigned char *)&defn);

        // )
        resync(scanner, tlFormalParmsFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(scanner, tcRParen, errMissingRightParen);
    }
}

void parseSubroutineDeclarations(SCANNER *scanner, SYMTABNODE *pRoutineId) {
    DEFN defn;
    SYMTABNODE node;
    CHUNKNUM rtnId, lastId = 0;

    // Loop to parse procedure and function definitions
    while (tokenIn(scanner->token.code, tlProcFuncStart)) {
        parseSubroutine(scanner, &node);
        rtnId = node.nodeChunkNum;

        // Link the routine's local (nested) routine id nodes together.
        retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
        if (!defn.routine.locals.routineIds) {
            defn.routine.locals.routineIds = rtnId;
            storeChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
        } else {
            retrieveChunk(lastId, (unsigned char *)&node);
            node.nextNode = rtnId;
            storeChunk(lastId, (unsigned char *)&node);
        }
        lastId = rtnId;

        // semicolon
        resync(scanner, tlDeclarationFollow, tlProcFuncStart, tlStatementStart);
        if (scanner->token.code == tcSemicolon) {
            getToken(scanner);
        } else if (tokenIn(scanner->token.code, tlProcFuncStart) ||
            tokenIn(scanner->token.code, tlStatementStart)) {
            Error(errMissingSemicolon);
        }
    }
}

void parseSubroutine(SCANNER *scanner, SYMTABNODE *pRoutineId) {
    DEFN defn;

    // <routine-header>
    parseFuncOrProcHeader(scanner, pRoutineId, scanner->token.code == tcFUNCTION);

    // ;
    resync(scanner, tlHeaderFollow, tlDeclarationStart, tlStatementStart);
    if (scanner->token.code == tcSemicolon) {
        getToken(scanner);
    } else if (tokenIn(scanner->token.code, tlDeclarationStart) ||
        tokenIn(scanner->token.code, tlStatementStart)) {
        Error(errMissingSemicolon);
    }

    // <block> or forward
    retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
    if (stricmp(scanner->token.string, "forward")) {
        defn.routine.which = rcDeclared;
        storeChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
        parseBlock(scanner, pRoutineId);
    } else {
        getToken(scanner);
        defn.routine.which = rcForward;
        storeChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
    }

    symtabExitScope(&defn.routine.symtab);
}
