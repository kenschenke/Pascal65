/**
 * parsstmt.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for parsing statements.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <error.h>
#include <icode.h>
#include <parscommon.h>
#include <string.h>

void parseAssignment(SCANNER *scanner, ICODE *Icode)
{
    SYMTABNODE targetNode;
    
    // Search for the target variable's identifier and enter it
    // if necessary.  Append the symbol table node handle
    // to the icode.
    if (searchGlobalSymtab(scanner->token.string, &targetNode) == 0) {
        enterGlobalSymtab(scanner->token.string, &targetNode);
    }

    putSymtabNodeToIcode(Icode, &targetNode);
    getTokenAppend(scanner, Icode);

    resync(scanner, tlColonEqual, tlExpressionStart, NULL);
    condGetTokenAppend(scanner, tcColonEqual, errMissingColonEqual);

    // <expr>
    parseExpression(scanner, Icode);
}

void parseCASE(SCANNER *scanner, ICODE *Icode) {
    char caseBranchFlag;  // true if another CASE branch, else false

    // <expr>
    getTokenAppend(scanner, Icode);
    parseExpression(scanner, Icode);

    // OF
    resync(scanner, tlOF, tlCaseLabelStart, NULL);
    condGetTokenAppend(scanner, tcOF, errMissingOF);

    // Loop to parse CASE branches
    caseBranchFlag = tokenIn(scanner->token.code, tlCaseLabelStart);
    while (caseBranchFlag) {
        if (tokenIn(scanner->token.code, tlCaseLabelStart)) parseCaseBranch(scanner, Icode);

        if (scanner->token.code == tcSemicolon) {
            getTokenAppend(scanner, Icode);
            caseBranchFlag = 0;
        } else if (tokenIn(scanner->token.code, tlCaseLabelStart)) {
            Error(errMissingSemicolon);
            caseBranchFlag = 1;
        } else {
            caseBranchFlag = 0;
        }
    }

    // END
    resync(scanner, tlEND, tlStatementStart, NULL);
    condGetTokenAppend(scanner, tcEND, errMissingEND);
}

void parseCaseBranch(SCANNER *scanner, ICODE *Icode) {
    char caseLabelFlag;  // true if another CASE label, else false

    // <case-label-list>
    do {
        parseCaseLabel(scanner, Icode);
        if (scanner->token.code == tcComma) {
            // Saw comma, look for another CASE label
            getTokenAppend(scanner, Icode);
            if (tokenIn(scanner->token.code, tlCaseLabelStart)) caseLabelFlag = 1;
            else {
                Error(errMissingConstant);
                caseLabelFlag = 0;
            }
        } else {
            caseLabelFlag = 0;
        }
    } while (caseLabelFlag);

    // :
    resync(scanner, tlColon, tlStatementStart, NULL);
    condGetTokenAppend(scanner, tcColon, errMissingColon);

    // <stmt>
    parseStatement(scanner, Icode);
}

void parseCaseLabel(SCANNER *scanner, ICODE *Icode) {
    char signFlag = 0;  // true if unary sign, else false
    SYMTABNODE node;

    // Unary + or -
    if (tokenIn(scanner->token.code, tlUnaryOps)) {
        signFlag = 1;
        getTokenAppend(scanner, Icode);
    }

    switch (scanner->token.code) {
        // Identifier
        case tcIdentifier:
            if (!searchGlobalSymtab(scanner->token.string, &node)) {
                Error(errUndefinedIdentifier);
            }
            getTokenAppend(scanner, Icode);
            break;

        // Number - must be an integer.
        case tcNumber:
            if (scanner->token.type != tyInteger) Error(errInvalidConstant);
            getTokenAppend(scanner, Icode);
            break;
        
        // String - must be a single character with a unary sign
        case tcString:
            if (signFlag || strlen(scanner->token.string) != 3) {
                Error(errInvalidConstant);
            }
            getTokenAppend(scanner, Icode);
            break;
    }
}

void parseCompound(SCANNER *scanner, ICODE *Icode) {
    getTokenAppend(scanner, Icode);

    // <stmt-list>
    parseStatementList(scanner, Icode, tcEND);

    // END
    condGetTokenAppend(scanner, tcEND, errMissingEND);
}

void parseFOR(SCANNER *scanner, ICODE *Icode) {
    SYMTABNODE node;

    // <id>
    getTokenAppend(scanner, Icode);
    if (scanner->token.code == tcIdentifier && !searchGlobalSymtab(scanner->token.string, &node)) {
        Error(errUndefinedIdentifier);
    }
    condGetTokenAppend(scanner, tcIdentifier, errMissingIdentifier);

    // :=
    resync(scanner, tlColonEqual, tlExpressionStart, NULL);
    condGetTokenAppend(scanner, tcColonEqual, errMissingColonEqual);

    // <expr-1>
    parseExpression(scanner, Icode);

    // TO or DOWNTO
    resync(scanner, tlTODOWNTO, tlExpressionStart, NULL);
    if (!tokenIn(scanner->token.code, tlTODOWNTO)) getTokenAppend(scanner, Icode);
    else Error(errMissingTOorDOWNTO);

    // <expr-2>
    parseExpression(scanner, Icode);

    // DO
    resync(scanner, tlDO, tlStatementStart, NULL);
    condGetTokenAppend(scanner, tcDO, errMissingDO);

    // <stmt>
    parseStatement(scanner, Icode);
}

void parseIF(SCANNER *scanner, ICODE *Icode) {
    // <expr>
    getTokenAppend(scanner, Icode);
    parseExpression(scanner, Icode);

    // THEN
    resync(scanner, tlTHEN, tlStatementStart, NULL);
    condGetTokenAppend(scanner, tcTHEN, errMissingTHEN);

    // <stmt-1>
    parseStatement(scanner, Icode);

    if (scanner->token.code == tcELSE) {
        // ELSE <stmt-2>
        getTokenAppend(scanner, Icode);
        parseStatement(scanner, Icode);
    }
}

void parseREPEAT(SCANNER *scanner, ICODE *Icode) {
    getTokenAppend(scanner, Icode);

    // <stmt-list>
    parseStatementList(scanner, Icode, tcUNTIL);

    // UNTIL
    condGetTokenAppend(scanner, tcUNTIL, errMissingUNTIL);

    // <expr>
    insertLineMarker(Icode);
    parseExpression(scanner, Icode);
}

void parseStatement(SCANNER *scanner, ICODE *Icode)
{
    insertLineMarker(Icode);

    // Call the appropriate parsing function based on
    // the statement's first token.
    switch (scanner->token.code) {
        case tcIdentifier: parseAssignment(scanner, Icode); break;
        case tcREPEAT: parseREPEAT(scanner, Icode); break;
        case tcWHILE: parseWHILE(scanner, Icode); break;
        case tcIF: parseIF(scanner, Icode); break;
        case tcFOR: parseFOR(scanner, Icode); break;
        case tcCASE: parseCASE(scanner, Icode); break;
        case tcBEGIN: parseCompound(scanner, Icode); break;
    }

    // Resync at a proper statement ending
    if (scanner->token.code != tcEndOfFile) {
        resync(scanner, tlStatementFollow, tlStatementStart, NULL);
    }
}

void parseStatementList(SCANNER *scanner, ICODE *Icode, TTokenCode terminator) {
    // Loop to parse statements and to check for and skip semicolons

    do {
        parseStatement(scanner, Icode);

        if (tokenIn(scanner->token.code, tlStatementStart)) {
            Error(errMissingSemicolon);
        } else while (scanner->token.code == tcSemicolon) {
            getTokenAppend(scanner, Icode);
        }
    } while (scanner->token.code != terminator && scanner->token.code != tcEndOfFile);
}

void parseWHILE(SCANNER *scanner, ICODE *Icode) {
    // <expr>
    getTokenAppend(scanner, Icode);
    parseExpression(scanner, Icode);

    // DO
    resync(scanner, tlDO, tlStatementStart, NULL);
    condGetTokenAppend(scanner, tcDO, errMissingDO);

    // <stmt>
    parseStatement(scanner, Icode);
}


