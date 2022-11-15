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

void initParser(void);
CHUNKNUM parse(SCANNER *scanner);  // returns programId
char findSymtabNode(SYMBNODE *pNode, const char *identifier);
void condGetToken(SCANNER *scanner, TTokenCode tc, TErrorCode ec);
void condGetTokenAppend(SCANNER *scanner, CHUNKNUM Icode, TTokenCode tc, TErrorCode ec);
void resync(SCANNER *scanner, const TTokenCode *pList1,
    const TTokenCode *pList2,
    const TTokenCode *pList3);

// Routines
void parseActualParm(SCANNER *scanner, CHUNKNUM formalId, char parmCheckFlag, CHUNKNUM Icode);
void parseActualParmList(SCANNER *scanner, SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode);
void parseBlock(SCANNER *scanner, SYMBNODE *pRoutineId);
CHUNKNUM parseDeclaredSubroutineCall(SCANNER *scanner, SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode);
void parseFormalParmList(SCANNER *scanner, CHUNKNUM *pParmList, int *parmCount, int *totalParmSize);
void parseFuncOrProcHeader(SCANNER *scanner, SYMBNODE *pRoutineId, char isFunc);
void parseProgram(SCANNER *scanner, SYMBNODE *pProgramId);
void parseProgramHeader(SCANNER *scanner, SYMBNODE *pProgramId);
CHUNKNUM parseStandardSubroutineCall(SCANNER *scanner, CHUNKNUM Icode, SYMBNODE *pRoutineId);
void parseSubroutine(SCANNER *scanner, SYMBNODE *pRoutineId);
CHUNKNUM parseSubroutineCall(SCANNER *scanner, SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode);
void parseSubroutineDeclarations(SCANNER *scanner, SYMBNODE *pRoutineId);

// Standard Routines
void initStandardRoutines(CHUNKNUM symtabChunkNum);
CHUNKNUM parseReadReadlnCall(SCANNER *scanner, CHUNKNUM Icode, SYMBNODE *pRoutineId);
CHUNKNUM parseWriteWritelnCall(SCANNER *scanner, CHUNKNUM Icode, SYMBNODE *pRoutineId);
CHUNKNUM parseEofEolnCall(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parseAbsSqrCall(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parsePredSuccCall(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parseChrCall(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parseOddCall(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parseOrdCall(SCANNER *scanner, CHUNKNUM Icode);
void skipExtraParms(SCANNER *scanner, CHUNKNUM Icode);

// Declarations
int arraySize(TTYPE *pArrayType);
void copyQuotedString(const char *pString, CHUNKNUM *firstChunk);
void parseArrayType(SCANNER *scanner, CHUNKNUM *newTypeChunkNum);
void parseDeclarations(SCANNER *scanner, SYMBNODE *routineSymtab);
void parseConstant(SCANNER *scanner, SYMBNODE *constId);
void parseConstantDefinitions(SCANNER *scanner, SYMBNODE *routineSymtab);
void parseEnumerationType(SCANNER *scanner, CHUNKNUM *newTypeChunkNum);
void parseFieldDeclarations(SCANNER *scanner, TTYPE *pRecordType, int offset);
CHUNKNUM parseIdSublist(SCANNER *scanner, SYMBNODE *routineId, TTYPE *pRecordType, CHUNKNUM *pLastId);
void parseIdentifierConstant(SCANNER *scanner, SYMBNODE *id1, TTokenCode sign);
void parseIdentifierType(SCANNER *scanner);
void parseIndexType(SCANNER *scanner, TTYPE *pArrayType);
void parseRecordType(SCANNER *scanner, CHUNKNUM *newTypeChunkNum);
void parseSubrangeLimit(SCANNER *scanner, SYMBNODE *pLimit, int *limit, CHUNKNUM *limitTypeChunkNum);
void parseSubrangeType(SCANNER *scanner, SYMBNODE *pMinId, CHUNKNUM *newTypeChunkNum);
void parseTypeDefinitions(SCANNER *scanner, SYMBNODE *pRoutineId);
void parseTypeSpec(SCANNER *scanner, CHUNKNUM *newTypeChunkNum);
void parseVariableDeclarations(SCANNER *scanner, SYMBNODE *routineSymtab);
void parseVarOrFieldDecls(SCANNER *scanner, SYMBNODE *routineSymtab, TTYPE *pRecordType, int offset);

// Statements
void parseAssignment(SCANNER *scanner, SYMBNODE *pNode, CHUNKNUM Icode);
void parseStatement(SCANNER *scanner, CHUNKNUM Icode);
void parseStatementList(SCANNER *scanner, CHUNKNUM Icode, TTokenCode terminator);

void parseREPEAT(SCANNER *scanner, CHUNKNUM Icode);
void parseWHILE(SCANNER *scanner, CHUNKNUM Icode);
void parseIF(SCANNER *scanner, CHUNKNUM Icode);
void parseFOR(SCANNER *scanner, CHUNKNUM Icode);
void parseCASE(SCANNER *scanner, CHUNKNUM Icode);
void parseCaseBranch(SCANNER *scanner, CHUNKNUM Icode, CHUNKNUM exprTypeChunk);
void parseCaseLabel(SCANNER *scanner, CHUNKNUM Icode, CHUNKNUM exprTypeChunk);
void parseCompound(SCANNER *scanner, CHUNKNUM Icode);

// Expressions
CHUNKNUM parseExpression(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parseField(SCANNER *scanner, CHUNKNUM Icode, CHUNKNUM recordTypeChunk);
CHUNKNUM parseSimpleExpression(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parseTerm(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parseFactor(SCANNER *scanner, CHUNKNUM Icode);
CHUNKNUM parseSubscripts(SCANNER *scanner, CHUNKNUM Icode, CHUNKNUM arrayTypeChunk);
CHUNKNUM parseVariable(SCANNER *scanner, CHUNKNUM Icode, SYMBNODE *pId);

char enterGlobalSymtab(const char *pString, SYMBNODE *node);
void getToken(SCANNER *scanner);
void getTokenAppend(SCANNER *scanner, CHUNKNUM Icode);

#endif // end of PARSER_H
