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
#include <types.h>

void parse(SCANNER *scanner);
char findSymtabNode(SYMTABNODE *pNode, const char *identifier);
void condGetToken(SCANNER *scanner, TTokenCode tc, TErrorCode ec);
void condGetTokenAppend(SCANNER *scanner, TTokenCode tc, TErrorCode ec);
void resync(SCANNER *scanner, const TTokenCode *pList1,
    const TTokenCode *pList2,
    const TTokenCode *pList3);

// Declarations
int arraySize(TTYPE *pArrayType);
void copyQuotedString(const char *pString, CHUNKNUM *firstChunk);
void parseArrayType(SCANNER *scanner, CHUNKNUM *newTypeChunkNum);
void parseDeclarations(SCANNER *scanner, SYMTABNODE *routineSymtab);
void parseConstant(SCANNER *scanner, SYMTABNODE *constId);
void parseConstantDefinitions(SCANNER *scanner, SYMTABNODE *routineSymtab);
void parseEnumerationType(SCANNER *scanner, CHUNKNUM *newTypeChunkNum);
void parseFieldDeclarations(SCANNER *scanner, TTYPE *pRecordType, int offset);
CHUNKNUM parseIdSublist(SCANNER *scanner, SYMTABNODE *routineId, TTYPE *pRecordType, CHUNKNUM *pLastId);
void parseIdentifierConstant(SCANNER *scanner, SYMTABNODE *id1, TTokenCode sign);
void parseIdentifierType(SCANNER *scanner);
void parseIndexType(SCANNER *scanner, TTYPE *pArrayType);
void parseRecordType(SCANNER *scanner, CHUNKNUM *newTypeChunkNum);
void parseSubrangeLimit(SCANNER *scanner, SYMTABNODE *pLimit, int *limit, CHUNKNUM *limitTypeChunkNum);
void parseSubrangeType(SCANNER *scanner, SYMTABNODE *pMinId, CHUNKNUM *newTypeChunkNum);
void parseTypeDefinitions(SCANNER *scanner, SYMTABNODE *pRoutineId);
void parseTypeSpec(SCANNER *scanner, CHUNKNUM *newTypeChunkNum);
void parseVariableDeclarations(SCANNER *scanner, SYMTABNODE *routineSymtab);
void parseVarOrFieldDecls(SCANNER *scanner, SYMTABNODE *routineSymtab, TTYPE *pRecordType, int offset);

// Statements
void parseAssignment(SCANNER *scanner, ICODE *Icode);
void parseStatement(SCANNER *scanner, ICODE *Icode);
void parseStatementList(SCANNER *scanner, ICODE *Icode, TTokenCode terminator);

void parseREPEAT(SCANNER *scanner, ICODE *Icode);
void parseWHILE(SCANNER *scanner, ICODE *Icode);
void parseIF(SCANNER *scanner, ICODE *Icode);
void parseFOR(SCANNER *scanner, ICODE *Icode);
void parseCASE(SCANNER *scanner, ICODE *Icode);
void parseCaseBranch(SCANNER *scanner, ICODE *Icode, TTYPE *pExprType);
void parseCaseLabel(SCANNER *scanner, ICODE *Icode, TTYPE *pExprType);
void parseCompound(SCANNER *scanner, ICODE *Icode);

// Expressions
void parseExpression(SCANNER *scanner, ICODE *Icode, TTYPE *pResultType);
void parseField(SCANNER *scanner, ICODE *Icode, TTYPE *pType);
void parseSimpleExpression(SCANNER *scanner, ICODE *Icode, TTYPE *pResultType);
void parseTerm(SCANNER *scanner, ICODE *Icode, TTYPE *pResultType);
void parseFactor(SCANNER *scanner, ICODE *Icode, TTYPE *pResultType);
void parseSubscripts(SCANNER *scanner, ICODE *Icode, TTYPE *pType);
void parseVariable(SCANNER *scanner, ICODE *Icode, SYMTABNODE *pId, TTYPE *pResultType);

char enterGlobalSymtab(const char *pString, SYMTABNODE *node);
void getToken(SCANNER *scanner);
void getTokenAppend(SCANNER *scanner, ICODE *Icode);
char searchGlobalSymtab(const char *pString, SYMTABNODE *node);

#endif // end of PARSER_H
