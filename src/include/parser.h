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

SYMTABNODE *enterGlobalSymtab(const char *pString);
void getTokenAppend(SCANNER *scanner, ICODE *Icode);
SYMTABNODE *searchGlobalSymtab(const char *pString);

#endif // end of PARSER_H
