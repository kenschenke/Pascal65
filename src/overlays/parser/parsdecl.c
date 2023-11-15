#include <parser.h>
#include <membuf.h>
#include <string.h>
#include <ast.h>
#include <common.h>

static CHUNKNUM parseIdSublist(char decl_kind);
static void copyStringToMemBuf(char *pString, CHUNKNUM *firstChunk, int len);

static void copyStringToMemBuf(char* pString, CHUNKNUM* firstChunk, int len) {
    if (!(*firstChunk)) {
        // Memory buffer not allocated yet
        allocMemBuf(firstChunk);
    }

    reserveMemBuf(*firstChunk, len);
    copyToMemBuf(*firstChunk, pString, 0, len);
}

void copyQuotedString(char* pString, CHUNKNUM* firstChunk) {
    copyStringToMemBuf(pString + 1, firstChunk, (int)strlen(pString)-2);
}

void copyRealString(char* pString, CHUNKNUM* firstChunk) {
    copyStringToMemBuf(pString, firstChunk, (int)strlen(pString));
}

CHUNKNUM parseDeclarations(void) {
    CHUNKNUM firstDecl = 0, lastDecl = 0;

    if (parserToken == tcCONST) {
        getToken();
        lastDecl = parseConstantDefinitions(&firstDecl);
    }

    if (parserToken == tcTYPE) {
        getToken();
        lastDecl = parseTypeDefinitions(&firstDecl, lastDecl);
    }

    if (parserToken == tcVAR) {
        getToken();
        lastDecl = parseVariableDeclarations(&firstDecl, lastDecl);
    }

    if (tokenIn(parserToken, tlProcFuncStart)) {
        lastDecl = parseSubroutineDeclarations(&firstDecl, lastDecl);
    }

    return firstDecl;
}

CHUNKNUM parseConstant(CHUNKNUM* type) {
    CHUNKNUM expr = 0;
    TTokenCode sign = tcDummy;
    int length;

    // unary + or -
    if (tokenIn(parserToken, tlUnaryOps)) {
        if (parserToken == tcMinus) sign = tcMinus;
        getToken();
    }

    switch (parserToken) {
    case tcIdentifier: {
        struct type _type;
        *type = typeCreate(TYPE_DECLARED, 1, 0, 0);
        expr = exprCreate(EXPR_NAME, 0, 0, name_create(parserString), 0);
        retrieveChunk(*type, &_type);
        _type.name = name_create(parserString);
        storeChunk(*type, &_type);
        getToken();
        break;
    }

    // Number constant
    case tcNumber:
        *type = typeCreate(
            parserType == tyInteger ? TYPE_INTEGER : TYPE_REAL,
            1, 0, 0);
        if (parserType == tyReal) {
            parserValue.stringChunkNum = 0;
            copyRealString(parserString, &parserValue.stringChunkNum);
        }
        expr = exprCreate(
            parserType == tyInteger ? EXPR_INTEGER_LITERAL : EXPR_REAL_LITERAL,
            0, 0, 0, &parserValue);
        if (sign == tcMinus) {
            struct expr _expr;
            retrieveChunk(expr, &_expr);
            _expr.neg = 1;
            storeChunk(expr, &_expr);
        }
        getToken();
        break;

    case tcString:
        length = (int)strlen(parserString) - 2;  // skip quotes
        if (sign != tcDummy) Error(errInvalidConstant);

        if (length == 1) {
            // Single character
            parserValue.character = parserString[1];
            *type = typeCreate(TYPE_CHARACTER, 1, 0, 0);
            expr = exprCreate(EXPR_CHARACTER_LITERAL, 0, 0, 0, &parserValue);
        }
        else {
            parserValue.stringChunkNum = 0;
            copyQuotedString(parserString, &parserValue.stringChunkNum);
            *type = typeCreate(TYPE_STRING, 1, 0, 0);
            expr = exprCreate(EXPR_STRING_LITERAL, 0, 0, 0, &parserValue);
        }
        getToken();
        break;

    case tcTRUE:
    case tcFALSE:
        parserValue.integer = parserToken == tcTRUE ? 1 : 0;
        expr = exprCreate(EXPR_BOOLEAN_LITERAL, 0, 0, 0, &parserValue);
        *type = typeCreate(TYPE_BOOLEAN, 1, 0, 0);
        getToken();
        break;

    default:
        Error(errInvalidConstant);
        getToken();
    }

    return expr;
}

CHUNKNUM parseConstantDefinitions(CHUNKNUM* firstDecl) {
    // Loop to parse a list of constant definitions
    // separated by semicolons.

    CHUNKNUM lastDecl = 0;
    while (parserToken == tcIdentifier) {
        CHUNKNUM expr, decl, type, name = name_create(parserString);

        // =
        getToken();
        condGetToken(tcEqual, errMissingEqual);

        // <constant>
        expr = parseConstant(&type);
        decl = declCreate(DECL_CONST, name, type, expr);

        if (*firstDecl == 0) {
            *firstDecl = decl;
        }
        else {
            struct decl _decl;
            retrieveChunk(lastDecl, &_decl);
            _decl.next = decl;
            storeChunk(lastDecl, &_decl);
        }
        lastDecl = decl;

        // ;
        resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        condGetToken(tcSemicolon, errMissingSemicolon);

        // skip extra semicolons
        while (parserToken == tcSemicolon) getToken();
        resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
    }

    return lastDecl;
}

static CHUNKNUM parseIdSublist(char decl_kind)
{
    CHUNKNUM firstId = 0, lastId;
    CHUNKNUM name, newChunkNum;
    struct decl _decl;

    // Loop to parse each identifier in the sublist
    while (parserToken == tcIdentifier) {
        // create a decl node

        name = name_create(parserString);
        newChunkNum = declCreate(decl_kind, name, 0, 0);
        if (firstId) {
            retrieveChunk(lastId, &_decl);
            _decl.next = newChunkNum;
            storeChunk(lastId, &_decl);
        }

        if (!firstId) {
            firstId = newChunkNum;
        }
        lastId = newChunkNum;

        // ,
        getToken();
        resync(tlIdentifierFollow, 0, 0);
        if (parserToken == tcComma) {
            // Saw comma
            // Skip extra commas and look for an identifier
            do {
                getToken();
                resync(tlIdentifierStart, tlIdentifierFollow, 0);
                if (parserToken == tcComma) {
                    Error(errMissingIdentifier);
                }
            } while (parserToken == tcComma);
            if (parserToken != tcIdentifier) {
                Error(errMissingComma);
            }
        }
        else if (parserToken == tcIdentifier) {
            Error(errMissingComma);
        }
    }

    return firstId;
}

CHUNKNUM parseFieldDeclarations(void)
{
    CHUNKNUM firstField = 0;

    parseVarOrFieldDecls(&firstField, 0, 0);

    return firstField;
}

CHUNKNUM parseVariableDeclarations(CHUNKNUM* firstDecl, CHUNKNUM lastDecl)
{
    return parseVarOrFieldDecls(firstDecl, lastDecl, 1);
}

CHUNKNUM parseVarOrFieldDecls(CHUNKNUM* firstDecl, CHUNKNUM lastDecl, char isVarDecl)
{
    CHUNKNUM firstId, pId, newTypeChunkNum, lastId;
    struct decl _decl;

    // Loop to parse a list of variable or field declarations
    while (parserToken == tcIdentifier) {
        firstId = parseIdSublist(isVarDecl ? DECL_VARIABLE : DECL_TYPE);

        // :
        resync(tlSublistFollow, tlDeclarationFollow, 0);
        condGetToken(tcColon, errMissingColon);

        // <type>
        newTypeChunkNum = parseTypeSpec();

        // Now Loop to assign the type to each identifier in the sublist.
        pId = firstId;
        while (pId) {
            lastId = pId;
            retrieveChunk(pId, &_decl);
            _decl.type = newTypeChunkNum;
            storeChunk(pId, &_decl);
            pId = _decl.next;
        }

        // Is this the first declaration in the list?
        if (*firstDecl) {
            // No.  Add it to lastDecl.
            retrieveChunk(lastDecl, &_decl);
            _decl.next = firstId;
            storeChunk(lastDecl, &_decl);
        }
        else {
            // Yes.
            *firstDecl = firstId;
        }

        lastDecl = lastId;

        // ;
        // END for record field declaration
        if (isVarDecl) {
            resync(tlDeclarationFollow, tlStatementStart, 0);
            condGetToken(tcSemicolon, errMissingSemicolon);

            // skip extra semicolons
            while (parserToken == tcSemicolon) getToken();
            resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
        }
        else {
            resync(tlFieldDeclFollow, 0, 0);
            if (parserToken != tcEND) {
                condGetToken(tcSemicolon, errMissingSemicolon);

                // skip extra semicolons
                while (parserToken == tcSemicolon) getToken();
                resync(tlFieldDeclFollow, tlDeclarationStart, tlStatementStart);
            }
        }
    }

    return lastDecl;
}
