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
void checkForwardDeclaredParams(CHUNKNUM fwdParms, CHUNKNUM declParms);
void parseActualParm(CHUNKNUM formalId, char parmCheckFlag, CHUNKNUM Icode);
void parseActualParmList(char routineFlag, char parmCheckFlag, CHUNKNUM Icode);
void parseBlock(void);
CHUNKNUM parseDeclaredSubroutineCall(char parmCheckFlag, CHUNKNUM Icode);
void parseFormalParmList(CHUNKNUM *pParmList, int *parmCount, int *totalParmSize);
void parseFuncOrProcHeader(char isFunc);
void parseProgram(void);
void parseProgramHeader(void);
CHUNKNUM parseStandardSubroutineCall(CHUNKNUM Icode);
void parseSubroutine(void);
CHUNKNUM parseSubroutineCall(CHUNKNUM callChunkNum, char parmCheckFlag, CHUNKNUM Icode);
void parseSubroutineDeclarations(void);

// Standard Routines
void initStandardRoutines(CHUNKNUM symtabChunkNum);
CHUNKNUM parseReadReadlnCall(CHUNKNUM Icode);
CHUNKNUM parseWriteWritelnCall(CHUNKNUM Icode);
CHUNKNUM parseEofEolnCall(CHUNKNUM Icode);
void skipExtraParms(CHUNKNUM Icode);

// Declarations
int arraySize(TTYPE *pArrayType);
void copyQuotedString(char *pString, CHUNKNUM *firstChunk);
CHUNKNUM parseArrayType(void);
void parseDeclarations(void);
void parseConstant(CHUNKNUM constIdChunkNum);
void parseConstantDefinitions(void);
CHUNKNUM parseEnumerationType(void);
void parseFieldDeclarations(TTYPE *pRecordType, int offset);
CHUNKNUM parseIdSublist(SYMBNODE *routineId, TTYPE *pRecordType, CHUNKNUM *pLastId);
void parseIdentifierConstant(CHUNKNUM constIdChunkNum, TTokenCode sign);
void parseIdentifierType(void);
void parseIndexType(CHUNKNUM arrayTypeChunkNum);
CHUNKNUM parseRecordType(void);
void parseSubrangeLimit(CHUNKNUM limitIdChunkNum, int *limit, CHUNKNUM *limitTypeChunkNum);
CHUNKNUM parseSubrangeType(CHUNKNUM minIdChunkNum);
void parseTypeDefinitions(void);
CHUNKNUM parseTypeSpec(void);
void parseVariableDeclarations(void);
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
