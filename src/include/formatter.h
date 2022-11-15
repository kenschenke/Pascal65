#ifndef FORMATTER_H
#define FORMATTER_H

#include <symtab.h>
#include <chunks.h>
#include <types.h>
#include <scanner.h>

// entry points
void fmtClose(void);
char fmtOpen(const char *filename);
void fmtSource(CHUNKNUM programId);

// internal use
void fmtDetent(void);
void fmtIndent(void);
void fmtPut(const char *pString);
void fmtPutLine(const char *pString);
void fmtPutName(CHUNKNUM nameChunkNum);
void fmtPutStringArray(CHUNKNUM stringChunkNum);
int fmtSetMargin(void);
void fmtResetMargin(int m);

// routines
void fmtPrintBlock(CHUNKNUM routineId);
void fmtPrintProgram(CHUNKNUM programId);
void fmtPrintSubroutine(SYMTABNODE *pRoutineId);
void fmtPrintSubroutineHeader(SYMTABNODE *pRoutineId);
void fmtPrintSubroutineFormals(CHUNKNUM parmId);

// declarations
void fmtPrintArrayType(TTYPE *pType);
void fmtPrintConstantDefinitions(CHUNKNUM constId);
void fmtPrintDeclarations(CHUNKNUM routineId);
void fmtPrintEnumType(TTYPE *pType);
void fmtPrintRecordType(TTYPE *pType);
void fmtPrintSubrangeLimit(int limit, TTYPE *pBaseType);
void fmtPrintSubrangeType(TTYPE *pType);
void fmtPrintSubroutineDeclarations(CHUNKNUM routineId);
void fmtPrintTypeDefinitions(CHUNKNUM typeId);
void fmtPrintTypeSpec(CHUNKNUM typeNum, char defnFlag);
void fmtPrintVarsOrFields(CHUNKNUM variableId);
void fmtPrintVariableDeclarations(CHUNKNUM variableId);

// statements
void fmtPrintAssignmentOrCall(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);
void fmtPrintCASE(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);
void fmtPrintCompound(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);
void fmtPrintFOR(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);
void fmtPrintIF(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);
void fmtPrintREPEAT(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);
void fmtPrintStatement(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);
void fmtPrintStatementList(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken, TTokenCode terminator);
void fmtPrintWHILE(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);

// expressions
void fmtPrintExpression(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);
void fmtPrintIdentifier(CHUNKNUM Icode, SYMTABNODE *pNode, TOKEN *pToken);

#endif // end of FORMATTER_H
