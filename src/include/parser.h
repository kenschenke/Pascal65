/**
 * parser.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for parser
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef PARSER_H
#define PARSER_H

#include <scanner.h>
#include <icode.h>

void parse(SCANNER *scanner);
void condGetToken(SCANNER *scanner, TTokenCode tc, TErrorCode ec);
void condGetTokenAppend(SCANNER *scanner, TTokenCode tc, TErrorCode ec);
void resync(SCANNER *scanner, const TTokenCode *pList1,
    const TTokenCode *pList2,
    const TTokenCode *pList3);

// Statements
void parseAssignment(SCANNER *scanner, ICODE *Icode);
void parseStatement(SCANNER *scanner, ICODE *Icode);
void parseStatementList(SCANNER *scanner, ICODE *Icode, TTokenCode terminator);

void parseREPEAT(SCANNER *scanner, ICODE *Icode);
void parseWHILE(SCANNER *scanner, ICODE *Icode);
void parseIF(SCANNER *scanner, ICODE *Icode);
void parseFOR(SCANNER *scanner, ICODE *Icode);
void parseCASE(SCANNER *scanner, ICODE *Icode);
void parseCaseBranch(SCANNER *scanner, ICODE *Icode);
void parseCaseLabel(SCANNER *scanner, ICODE *Icode);
void parseCompound(SCANNER *scanner, ICODE *Icode);

// Expressions
void parseExpression(SCANNER *scanner, ICODE *Icode);
void parseSimpleExpression(SCANNER *scanner, ICODE *Icode);
void parseTerm(SCANNER *scanner, ICODE *Icode);
void parseFactor(SCANNER *scanner, ICODE *Icode);

char enterGlobalSymtab(const char *pString, SYMTABNODE *node);
void getTokenAppend(SCANNER *scanner, ICODE *Icode);
char searchGlobalSymtab(const char *pString, SYMTABNODE *node);

#endif // end of PARSER_H
