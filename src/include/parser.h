/**
 * parser.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for parser
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef PARSER_H
#define PARSER_H

#include <buffer.h>
#include <chunks.h>
#include <misc.h>
#include <error.h>
#include <tokenizer.h>
#include <ast.h>

extern TTokenCode parserToken;
extern TDataValue parserValue;
extern TDataType parserType;
extern type_t parserModuleType;
extern char isInUnitInterface;
extern CHUNKNUM parserIdentifier;
extern char parserString[MAX_LINE_LEN + 1];

CHUNKNUM parse(CHUNKNUM Icode);  // returns root of AST
void condGetToken(TTokenCode tc, TErrorCode ec);
void condGetTokenAppend(CHUNKNUM Icode, TTokenCode tc, TErrorCode ec);
void resync(const TTokenCode *pList1,
    const TTokenCode *pList2,
    const TTokenCode *pList3);
char tokenIn(TTokenCode tc, const TTokenCode* pList);

// Routines
CHUNKNUM parseActualParm(char isWriteWriteln);
CHUNKNUM parseActualParmList(char isWriteWriteln);
CHUNKNUM parseBlock(char isProgramOrUnitBlock, char *isLibrary);
CHUNKNUM parseDeclaredSubroutineCall(char parmCheckFlag, CHUNKNUM Icode);
CHUNKNUM parseFormalParmList(void);
CHUNKNUM parseFuncOrProcHeader(char isFunc, char isRtnType);
CHUNKNUM parseModule(void);
CHUNKNUM parseModuleHeader(void);
CHUNKNUM parseSubroutine(void);
CHUNKNUM parseSubroutineCall(CHUNKNUM name, char isWriteWriteln);
CHUNKNUM parseSubroutineDeclarations(CHUNKNUM* firstDecl, CHUNKNUM lastDecl);

// Standard Routines
CHUNKNUM parseReadReadlnCall(CHUNKNUM Icode);
CHUNKNUM parseWriteWritelnCall(CHUNKNUM Icode);
CHUNKNUM parseEofEolnCall(CHUNKNUM Icode);

// Declarations
void copyQuotedString(char *pString, CHUNKNUM *firstChunk);
void copyRealString(char *pString, CHUNKNUM *firstChunk);
CHUNKNUM parseArrayType(void);
CHUNKNUM parseDeclarations(char isProgramOrUnitBlock);
CHUNKNUM parseConstant(CHUNKNUM* type);
CHUNKNUM parseConstantDefinitions(CHUNKNUM* firstDecl, CHUNKNUM lastDecl);
CHUNKNUM parseEnumerationType(void);
CHUNKNUM parseFieldDeclarations(void);
CHUNKNUM parseFileType(void);
CHUNKNUM parseRecordType(void);
type_t parseSubrangeLimit(CHUNKNUM name, CHUNKNUM* limit);
CHUNKNUM parseSubrangeType(CHUNKNUM name, char allowShorthand);
CHUNKNUM parseTypeDefinitions(CHUNKNUM* firstDecl, CHUNKNUM lastDecl);
CHUNKNUM parseTypeSpec(char allowSubrangeShorthand);
CHUNKNUM parseUsesReferences(CHUNKNUM *firstDecl, CHUNKNUM lastDecl);
CHUNKNUM parseVariableDeclarations(CHUNKNUM* firstDecl, CHUNKNUM lastDecl);
CHUNKNUM parseVarOrFieldDecls(CHUNKNUM* firstDecl, CHUNKNUM lastDecl, char isVarDecl);

// Statements
CHUNKNUM parseAssignment(CHUNKNUM nameChunk);
CHUNKNUM parseStatement(void);
CHUNKNUM parseStatementList(TTokenCode terminator);

CHUNKNUM parseREPEAT(void);
CHUNKNUM parseWHILE(void);
CHUNKNUM parseIF(void);
CHUNKNUM parseFOR(void);
CHUNKNUM parseCASE(void);
CHUNKNUM parseCaseBranch(void);
CHUNKNUM parseCaseLabel(void);
CHUNKNUM parseCompound(void);

// Expressions
CHUNKNUM parseExpression(char isVarInit);
CHUNKNUM parseField(CHUNKNUM expr);
CHUNKNUM parseSimpleExpression(char isVarInit);
CHUNKNUM parseTerm(char isVarInit);
CHUNKNUM parseFactor(char isVarInit);
CHUNKNUM parseSubscripts(CHUNKNUM expr);
CHUNKNUM parseVariable(CHUNKNUM nameChunk);

void getToken(void);

// Token Lists

extern const TTokenCode tlStatementStart[], tlStatementFollow[];
extern const TTokenCode tlStatementListNotAllowed[];
extern const TTokenCode tlCaseLabelStart[];

extern const TTokenCode tlExpressionStart[], tlExpressionFollow[];
extern const TTokenCode tlRelOps[], tlUnaryOps[],
tlAddOps[], tlMulOps[];

extern const TTokenCode tlProgramEnd[];

extern const TTokenCode tlColonEqual[];
extern const TTokenCode tlDO[];
extern const TTokenCode tlTHEN[];
extern const TTokenCode tlTODOWNTO[];
extern const TTokenCode tlOF[];
extern const TTokenCode tlColon[];
extern const TTokenCode tlEND[];

#endif // end of PARSER_H
