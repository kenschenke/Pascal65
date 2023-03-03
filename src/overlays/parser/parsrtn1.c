#include <string.h>
#include <common.h>
#include <symtab.h>
#include <parser.h>
#include <parscommon.h>

void parseBlock(void) {
    // declarations
    parseDeclarations();

    // <compound-statement>   reset the icode and append BEGIN to it,
    //                        and then parse the compound statement.
    resync(tlStatementStart, NULL, NULL);
    if (tokenCode != tcBEGIN) Error(errMissingBEGIN);

    allocMemBuf(&routineNode.defn.routine.Icode);
    saveSymbNodeDefn(&routineNode);
    parseCompound(routineNode.defn.routine.Icode);
}

void parseFuncOrProcHeader(char isFunc) {
    int parmCount;  // count of formal params
    int totalParmSize;  // total byte size of all parameters
    char forwardFlag = 0;
    SYMBNODE typeId;
    CHUNKNUM parmList;

    getToken();

    // <id>   If the routine id has already been declared in this scope,
    //        it must have been a forward declaration.
    if (tokenCode == tcIdentifier) {
        if (!symtabSearchLocal(&routineNode, tokenString)) {
            // Not already declared
            symtabEnterLocal(&routineNode, tokenString,
                isFunc ? dcFunction : dcProcedure);
            routineNode.defn.routine.totalLocalSize = 0;
        } else {
            if (routineNode.defn.how == isFunc ? dcFunction : dcProcedure && routineNode.defn.routine.which == rcForward) {
                forwardFlag = 1;
            } else {
                Error(errRedefinedIdentifier);
            }
        }

        getToken();
    } else {
        Error(errMissingIdentifier);
    }

    // ( or : or ;
    resync(isFunc ? tlFuncIdFollow : tlProgProcIdFollow,
        tlDeclarationStart, tlStatementStart);

    // Enter the next nesting level and open a new scope for the function
    symtabStackEnterScope();

    // Optional (<id-list>) : If there was a forward declaration, there
    //                        must not be a parameter list, but if there
    //                        is, parse it anyway for error recovery.
    if (tokenCode == tcLParen) {
        parseFormalParmList(&parmList, &parmCount, &totalParmSize);
        if (forwardFlag) {
            Error(errAlreadyForwarded);
        } else {
            // Not forwarded
            routineNode.defn.routine.parmCount = parmCount;
            routineNode.defn.routine.totalParmSize = totalParmSize;
            routineNode.defn.routine.locals.parmIds = parmList;
        }
    } else if (!forwardFlag) {
        // No parameters and no forward declaration
        routineNode.defn.routine.parmCount = 0;
        routineNode.defn.routine.totalParmSize = 0;
        routineNode.defn.routine.locals.parmIds = 0;
    }

    routineNode.defn.routine.locals.constantIds = 0;
    routineNode.defn.routine.locals.typeIds = 0;
    routineNode.defn.routine.locals.variableIds = 0;
    routineNode.defn.routine.locals.routineIds = 0;

    saveSymbNodeDefn(&routineNode);

    if (isFunc) {
        // Optional <type-id> : If there was a forward declaration, there must
        //                      not be a type id, but if there was, parse it
        //                      anyway for error recovery.
        if (!forwardFlag || tokenCode == tcColon) {
            condGetToken(tcColon, errMissingColon);
            if (tokenCode == tcIdentifier) {
                symtabStackFind(tokenString, &typeId);
                if (typeId.defn.how != dcType) Error(errInvalidType);
                if (forwardFlag) {
                    Error(errAlreadyForwarded);
                } else {
                    setType(&routineNode.node.typeChunk, typeId.node.typeChunk);
                }

                getToken();
            } else {
                Error(errMissingIdentifier);
                setType(&routineNode.node.typeChunk, dummyType);
            }
        }
    } else {
        setType(&routineNode.node.typeChunk, dummyType);
    }

    saveSymbNodeOnly(&routineNode);
}

void parseProgram(void) {
    // <program-header>
    parseProgramHeader();

    // ;
    resync(tlHeaderFollow, tlDeclarationStart, tlStatementStart);
    if (tokenCode == tcSemicolon) {
        getToken();
    } else if (tokenIn(tokenCode, tlDeclarationStart) ||
        tokenIn(tokenCode, tlStatementStart)) {
        Error(errMissingSemicolon);
    }

    // <block>
    parseBlock();
    symtabExitScope(&routineNode.defn.routine.symtab);
    saveSymbNodeDefn(&routineNode);

    // .
    resync(tlProgramEnd, NULL, NULL);
    condGetTokenAppend(routineNode.defn.routine.Icode, tcPeriod, errMissingPeriod);
}

void parseProgramHeader(void) {
    SYMBNODE parmId, prevParmId;

    // PROGRAM
    condGetToken(tcPROGRAM, errMissingPROGRAM);

    // <id>
    if (tokenCode == tcIdentifier) {
        symtabEnterNewLocal(&routineNode, tokenString, dcProgram);

        routineNode.defn.routine.which = rcDeclared;
        routineNode.defn.routine.parmCount = 0;
        routineNode.defn.routine.totalParmSize = 0;
        routineNode.defn.routine.totalLocalSize = 0;
        routineNode.defn.routine.locals.parmIds = 0;
        routineNode.defn.routine.locals.constantIds = 0;
        routineNode.defn.routine.locals.typeIds = 0;
        routineNode.defn.routine.locals.variableIds = 0;
        routineNode.defn.routine.locals.routineIds = 0;
        routineNode.defn.routine.symtab = 0;
        routineNode.defn.routine.Icode = 0;
        setType(&routineNode.node.typeChunk, dummyType);
        saveSymbNode(&routineNode);
        getToken();
    } else {
        Error(errMissingIdentifier);
    }

    // ( or ;
    resync(tlProgProcIdFollow, tlDeclarationStart, tlStatementStart);

    // Enter the nesting level 1 and open a new scope for the program
    symtabStackEnterScope();

    // Optional (<id-list>)
    if (tokenCode == tcLParen) {
        // Loop to parse a comma-separated identifier list.
        do {
            getToken();
            if (tokenCode == tcIdentifier) {
                symtabEnterNewLocal(&parmId, tokenString, dcVarParm);
                setType(&parmId.node.typeChunk, dummyType);
                saveSymbNodeOnly(&parmId);
                getToken();

                // Link program parm id nodes together
                if (!routineNode.defn.routine.locals.parmIds) {
                    routineNode.defn.routine.locals.parmIds = parmId.node.nodeChunkNum;
                } else {
                    prevParmId.node.nextNode = parmId.node.nodeChunkNum;
                    saveSymbNodeOnly(&prevParmId);
                }
                memcpy(&prevParmId, &parmId, sizeof(SYMBNODE));
            } else {
                Error(errMissingIdentifier);
            }
        } while (tokenCode == tcComma);

        saveSymbNode(&routineNode);

        // )
        resync(tlFormalParmsFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(tcRParen, errMissingRightParen);
    }
}

void parseSubroutineDeclarations(void) {
    CHUNKNUM parentRtnId, childRtnId, lastId = 0;

    saveSymbNode(&routineNode);
    parentRtnId = routineNode.node.nodeChunkNum;

    // Loop to parse procedure and function definitions
    while (tokenIn(tokenCode, tlProcFuncStart)) {
        saveSymbNode(&routineNode);
        parseSubroutine();
        childRtnId = routineNode.node.nodeChunkNum;

        // Link the routine's local (nested) routine id nodes together.
        loadSymbNode(parentRtnId, &routineNode);
        if (!routineNode.defn.routine.locals.routineIds) {
            routineNode.defn.routine.locals.routineIds = childRtnId;
            saveSymbNode(&routineNode);
        } else {
            ((SYMTABNODE *)getChunk(lastId))->nextNode = childRtnId;
        }
        lastId = childRtnId;

        // semicolon
        resync(tlDeclarationFollow, tlProcFuncStart, tlStatementStart);
        if (tokenCode == tcSemicolon) {
            getToken();
        } else if (tokenIn(tokenCode, tlProcFuncStart) ||
            tokenIn(tokenCode, tlStatementStart)) {
            Error(errMissingSemicolon);
        }
    }
}

void parseSubroutine(void) {
    // <routine-header>
    parseFuncOrProcHeader(tokenCode == tcFUNCTION);

    // ;
    resync(tlHeaderFollow, tlDeclarationStart, tlStatementStart);
    if (tokenCode == tcSemicolon) {
        getToken();
    } else if (tokenIn(tokenCode, tlDeclarationStart) ||
        tokenIn(tokenCode, tlStatementStart)) {
        Error(errMissingSemicolon);
    }

    // <block> or forward
    if (stricmp(tokenString, "forward")) {
        routineNode.defn.routine.which = rcDeclared;
        saveSymbNode(&routineNode);
        parseBlock();
    } else {
        getToken();
        routineNode.defn.routine.which = rcForward;
        saveSymbNode(&routineNode);
    }

    symtabExitScope(&routineNode.defn.routine.symtab);
}
