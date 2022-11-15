#include <string.h>
#include <common.h>
#include <symtab.h>
#include <parser.h>
#include <parscommon.h>

void parseBlock(SCANNER *scanner, SYMBNODE *pRoutineId) {
    // declarations
    parseDeclarations(scanner, pRoutineId);

    // <compound-statement>   reset the icode and append BEGIN to it,
    //                        and then parse the compound statement.
    resync(scanner, tlStatementStart, NULL, NULL);
    if (scanner->token.code != tcBEGIN) Error(errMissingBEGIN);

    makeIcode(&pRoutineId->defn.routine.Icode);
    saveSymbNodeDefn(pRoutineId);
    parseCompound(scanner, pRoutineId->defn.routine.Icode);
}

void parseFuncOrProcHeader(SCANNER *scanner, SYMBNODE *pRoutineId, char isFunc) {
    int parmCount;  // count of formal params
    int totalParmSize;  // total byte size of all parameters
    char forwardFlag = 0;
    SYMBNODE typeId;
    CHUNKNUM parmList;

    getToken(scanner);

    // <id>   If the routine id has already been declared in this scope,
    //        it must have been a forward declaration.
    if (scanner->token.code == tcIdentifier) {
        if (!symtabSearchLocal(pRoutineId, scanner->token.string)) {
            // Not already declared
            symtabEnterLocal(pRoutineId, scanner->token.string,
                isFunc ? dcFunction : dcProcedure);
            pRoutineId->defn.routine.totalLocalSize = 0;
        } else {
            if (pRoutineId->defn.how == isFunc ? dcFunction : dcProcedure && pRoutineId->defn.routine.which == rcForward) {
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
            pRoutineId->defn.routine.parmCount = parmCount;
            pRoutineId->defn.routine.totalParmSize = totalParmSize;
            pRoutineId->defn.routine.locals.parmIds = parmList;
        }
    } else if (!forwardFlag) {
        // No parameters and no forward declaration
        pRoutineId->defn.routine.parmCount = 0;
        pRoutineId->defn.routine.totalParmSize = 0;
        pRoutineId->defn.routine.locals.parmIds = 0;
    }

    pRoutineId->defn.routine.locals.constantIds = 0;
    pRoutineId->defn.routine.locals.typeIds = 0;
    pRoutineId->defn.routine.locals.variableIds = 0;
    pRoutineId->defn.routine.locals.routineIds = 0;

    saveSymbNodeDefn(pRoutineId);

    if (isFunc) {
        // Optional <type-id> : If there was a forward declaration, there must
        //                      not be a type id, but if there was, parse it
        //                      anyway for error recovery.
        if (!forwardFlag || scanner->token.code == tcColon) {
            condGetToken(scanner, tcColon, errMissingColon);
            if (scanner->token.code == tcIdentifier) {
                symtabStackFind(scanner->token.string, &typeId);
                if (typeId.defn.how != dcType) Error(errInvalidType);
                if (forwardFlag) {
                    Error(errAlreadyForwarded);
                } else {
                    setType(&pRoutineId->node.typeChunk, typeId.node.typeChunk);
                }

                getToken(scanner);
            } else {
                Error(errMissingIdentifier);
                setType(&pRoutineId->node.typeChunk, dummyType);
            }
        }
    } else {
        setType(&pRoutineId->node.typeChunk, dummyType);
    }

    saveSymbNodeOnly(pRoutineId);
}

void parseProgram(SCANNER *scanner, SYMBNODE *pProgramId) {
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
    symtabExitScope(&pProgramId->defn.routine.symtab);
    saveSymbNodeDefn(pProgramId);

    // .
    resync(scanner, tlProgramEnd, NULL, NULL);
    condGetTokenAppend(scanner, pProgramId->defn.routine.Icode, tcPeriod, errMissingPeriod);
}

void parseProgramHeader(SCANNER *scanner, SYMBNODE *pProgramId) {
    SYMBNODE parmId, prevParmId;

    // PROGRAM
    condGetToken(scanner, tcPROGRAM, errMissingPROGRAM);

    // <id>
    if (scanner->token.code == tcIdentifier) {
        symtabEnterNewLocal(pProgramId, scanner->token.string, dcProgram);

        pProgramId->defn.routine.which = rcDeclared;
        pProgramId->defn.routine.parmCount = 0;
        pProgramId->defn.routine.totalParmSize = 0;
        pProgramId->defn.routine.totalLocalSize = 0;
        pProgramId->defn.routine.locals.parmIds = 0;
        pProgramId->defn.routine.locals.constantIds = 0;
        pProgramId->defn.routine.locals.typeIds = 0;
        pProgramId->defn.routine.locals.variableIds = 0;
        pProgramId->defn.routine.locals.routineIds = 0;
        pProgramId->defn.routine.symtab = 0;
        pProgramId->defn.routine.Icode = 0;
        setType(&pProgramId->node.typeChunk, dummyType);
        saveSymbNode(pProgramId);
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
                setType(&parmId.node.typeChunk, dummyType);
                saveSymbNodeOnly(&parmId);
                getToken(scanner);

                // Link program parm id nodes together
                if (!pProgramId->defn.routine.locals.parmIds) {
                    pProgramId->defn.routine.locals.parmIds = parmId.node.nodeChunkNum;
                } else {
                    prevParmId.node.nextNode = parmId.node.nodeChunkNum;
                    saveSymbNodeOnly(&prevParmId);
                }
                memcpy(&prevParmId, &parmId, sizeof(SYMBNODE));
            } else {
                Error(errMissingIdentifier);
            }
        } while (scanner->token.code == tcComma);

        saveSymbNode(pProgramId);

        // )
        resync(scanner, tlFormalParmsFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(scanner, tcRParen, errMissingRightParen);
    }
}

void parseSubroutineDeclarations(SCANNER *scanner, SYMBNODE *pRoutineId) {
    SYMBNODE node;
    CHUNKNUM rtnId, lastId = 0;

    // Loop to parse procedure and function definitions
    while (tokenIn(scanner->token.code, tlProcFuncStart)) {
        parseSubroutine(scanner, &node);
        rtnId = node.node.nodeChunkNum;

        // Link the routine's local (nested) routine id nodes together.
        if (!pRoutineId->defn.routine.locals.routineIds) {
            pRoutineId->defn.routine.locals.routineIds = rtnId;
            saveSymbNode(pRoutineId);
        } else {
            retrieveChunk(lastId, (unsigned char *)&node);
            node.node.nextNode = rtnId;
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

void parseSubroutine(SCANNER *scanner, SYMBNODE *pRoutineId) {
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
    if (stricmp(scanner->token.string, "forward")) {
        pRoutineId->defn.routine.which = rcDeclared;
        saveSymbNode(pRoutineId);
        parseBlock(scanner, pRoutineId);
    } else {
        getToken(scanner);
        pRoutineId->defn.routine.which = rcForward;
        saveSymbNode(pRoutineId);
    }

    symtabExitScope(&pRoutineId->defn.routine.symtab);
}
