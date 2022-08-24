/**
 * parsexpr.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for parsing expressions.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <error.h>
#include <icode.h>

void parseExpression(SCANNER *scanner, ICODE *Icode)
{
    parseSimpleExpression(scanner, Icode);

    // If we now see a relational operator,
    // parse a second simple expression.
    if (scanner->token.code == tcEqual || scanner->token.code == tcNe ||
        scanner->token.code == tcLt    || scanner->token.code == tcGt ||
        scanner->token.code == tcLe    || scanner->token.code == tcGe) {
        getTokenAppend(scanner, Icode);
        parseSimpleExpression(scanner, Icode);
    }
}

void parseSimpleExpression(SCANNER *scanner, ICODE *Icode)
{
    // Unary + or -
    if (scanner->token.code == tcPlus || scanner->token.code == tcMinus) {
        getTokenAppend(scanner, Icode);
    }

    // Parse the first term
    parseTerm(scanner, Icode);

    // Loop to parse subsequent additive operators and terms
    while (scanner->token.code == tcPlus ||
            scanner->token.code == tcMinus ||
            scanner->token.code == tcOR) {
        getTokenAppend(scanner, Icode);
        parseTerm(scanner, Icode);
    }
}

void parseTerm(SCANNER *scanner, ICODE *Icode)
{
    // Parse the first factor
    parseFactor(scanner, Icode);

    // Loop to parse subsequent multiplicative operators and factors
    while (scanner->token.code == tcStar ||
            scanner->token.code == tcSlash ||
            scanner->token.code == tcDIV ||
            scanner->token.code == tcMOD ||
            scanner->token.code == tcAND) {
        getTokenAppend(scanner, Icode);
        parseFactor(scanner, Icode);
    }
}

void parseFactor(SCANNER *scanner, ICODE *Icode)
{
    SYMTABNODE node;

    switch (scanner->token.code) {
        case tcIdentifier:
            // Search for the identifier.  If found, append the
            // symbol table node handle to the icode.  If not
            // found, enter it and flag an undefined identifier error.
            if (searchGlobalSymtab(scanner->token.string, &node) == 1) {
                putSymtabNodeToIcode(Icode, &node);
            } else {
                Error(errUndefinedIdentifier);
                enterGlobalSymtab(scanner->token.string, &node);
            }

            getTokenAppend(scanner, Icode);
            break;

        case tcNumber:
            // Search for the number and enter it if necessary.
            // See the number's value in the symbol table node.
            // Append the symbol table node handle to the icode.
            if (searchGlobalSymtab(scanner->token.string, &node) == 0) {
                enterGlobalSymtab(scanner->token.string, &node);
                setSymtabInt(&node, scanner->token.value.integer);
            }
            putSymtabNodeToIcode(Icode, &node);

            getTokenAppend(scanner, Icode);
            break;

        case tcString:
            getTokenAppend(scanner, Icode);
            break;

        case tcNOT:
            getTokenAppend(scanner, Icode);
            parseFactor(scanner, Icode);
            break;

        case tcLParen:
            // Parenthesized subexpression: call parseExpression recursively
            getTokenAppend(scanner, Icode);
            parseExpression(scanner, Icode);

            // and check for the closing right parenthesis
            if (scanner->token.code == tcRParen) {
                getTokenAppend(scanner, Icode);
            } else {
                Error(errMissingRightParen);
            }
            break;

        default:
            Error(errInvalidExpression);
            break;
    }
}

