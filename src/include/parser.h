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

// Statements
void parseAssignment(SCANNER *scanner, ICODE *Icode);
void parseStatement(SCANNER *scanner, ICODE *Icode);

// Expressions
void parseExpression(SCANNER *scanner, ICODE *Icode);
void parseSimpleExpression(SCANNER *scanner, ICODE *Icode);
void parseTerm(SCANNER *scanner, ICODE *Icode);
void parseFactor(SCANNER *scanner, ICODE *Icode);

char enterGlobalSymtab(const char *pString, SYMTABNODE *node);
void getTokenAppend(SCANNER *scanner, ICODE *Icode);
char searchGlobalSymtab(const char *pString, SYMTABNODE *node);

#endif // end of PARSER_H
