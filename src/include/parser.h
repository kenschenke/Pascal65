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
#include <membuf.h>
#include <types.h>

extern SYMBNODE routineNode;

void initParser(void);
CHUNKNUM parse(const char *filename);  // returns programId
char findSymtabNode(SYMBNODE *pNode, const char *identifier);
void condGetToken(TTokenCode tc, TErrorCode ec);
void condGetTokenAppend(CHUNKNUM Icode, TTokenCode tc, TErrorCode ec);
void resync(const TTokenCode *pList1,
    const TTokenCode *pList2,
    const TTokenCode *pList3);

// Routines
void parseActualParm(CHUNKNUM formalId, char parmCheckFlag, CHUNKNUM Icode);
void parseActualParmList(SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode);
void parseBlock(SYMBNODE *pRoutineId);
CHUNKNUM parseDeclaredSubroutineCall(SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode);
void parseFormalParmList(CHUNKNUM *pParmList, int *parmCount, int *totalParmSize);
void parseFuncOrProcHeader(SYMBNODE *pRoutineId, char isFunc);
void parseProgram(void);
void parseProgramHeader(void);
CHUNKNUM parseStandardSubroutineCall(CHUNKNUM Icode, SYMBNODE *pRoutineId);
void parseSubroutine(SYMBNODE *pRoutineId);
CHUNKNUM parseSubroutineCall(SYMBNODE *pRoutineId, char parmCheckFlag, CHUNKNUM Icode);
void parseSubroutineDeclarations(SYMBNODE *pRoutineId);

// Standard Routines
void initStandardRoutines(CHUNKNUM symtabChunkNum);
CHUNKNUM parseReadReadlnCall(CHUNKNUM Icode, SYMBNODE *pRoutineId);
CHUNKNUM parseWriteWritelnCall(CHUNKNUM Icode, SYMBNODE *pRoutineId);
CHUNKNUM parseEofEolnCall(CHUNKNUM Icode);
CHUNKNUM parseAbsSqrCall(CHUNKNUM Icode);
CHUNKNUM parsePredSuccCall(CHUNKNUM Icode);
CHUNKNUM parseChrCall(CHUNKNUM Icode);
CHUNKNUM parseOddCall(CHUNKNUM Icode);
CHUNKNUM parseOrdCall(CHUNKNUM Icode);
CHUNKNUM parseRoundTruncCall(CHUNKNUM Icode);
void skipExtraParms(CHUNKNUM Icode);

// Declarations
int arraySize(TTYPE *pArrayType);
void copyQuotedString(char *pString, CHUNKNUM *firstChunk);
void parseArrayType(CHUNKNUM *newTypeChunkNum);
void parseDeclarations(SYMBNODE *routineSymtab);
void parseConstant(SYMBNODE *constId);
void parseConstantDefinitions(SYMBNODE *routineSymtab);
void parseEnumerationType(CHUNKNUM *newTypeChunkNum);
void parseFieldDeclarations(TTYPE *pRecordType, int offset);
CHUNKNUM parseIdSublist(SYMBNODE *routineId, TTYPE *pRecordType, CHUNKNUM *pLastId);
void parseIdentifierConstant(SYMBNODE *id1, TTokenCode sign);
void parseIdentifierType(void);
void parseIndexType(TTYPE *pArrayType);
void parseRecordType(CHUNKNUM *newTypeChunkNum);
void parseSubrangeLimit(SYMBNODE *pLimit, int *limit, CHUNKNUM *limitTypeChunkNum);
void parseSubrangeType(SYMBNODE *pMinId, CHUNKNUM *newTypeChunkNum);
void parseTypeDefinitions(SYMBNODE *pRoutineId);
void parseTypeSpec(CHUNKNUM *newTypeChunkNum);
void parseVariableDeclarations(SYMBNODE *routineSymtab);
void parseVarOrFieldDecls(SYMBNODE *routineSymtab, TTYPE *pRecordType, int offset);

// Statements
void parseAssignment(SYMBNODE *pNode, CHUNKNUM Icode);
void parseStatement(CHUNKNUM Icode);
void parseStatementList(CHUNKNUM Icode, TTokenCode terminator);

void parseREPEAT(CHUNKNUM Icode);
void parseWHILE(CHUNKNUM Icode);
void parseIF(CHUNKNUM Icode);
void parseFOR(CHUNKNUM Icode);
void parseCASE(CHUNKNUM Icode);
void parseCaseBranch(CHUNKNUM Icode, CHUNKNUM exprTypeChunk, CHUNKNUM caseItems);
void parseCaseLabel(CHUNKNUM Icode, CHUNKNUM exprTypeChunk, CHUNKNUM caseItems);
void parseCompound(CHUNKNUM Icode);

// Expressions
CHUNKNUM parseExpression(CHUNKNUM Icode);
CHUNKNUM parseField(CHUNKNUM Icode, CHUNKNUM recordTypeChunk);
CHUNKNUM parseSimpleExpression(CHUNKNUM Icode);
CHUNKNUM parseTerm(CHUNKNUM Icode);
CHUNKNUM parseFactor(CHUNKNUM Icode);
CHUNKNUM parseSubscripts(CHUNKNUM Icode, CHUNKNUM arrayTypeChunk);
CHUNKNUM parseVariable(CHUNKNUM Icode, SYMBNODE *pId);

char enterGlobalSymtab(const char *pString, SYMBNODE *node);
void getToken(void);
void getTokenAppend(CHUNKNUM Icode);

#endif // end of PARSER_H
