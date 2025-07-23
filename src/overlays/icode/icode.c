/**
 * icode.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Intermediate Code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <icode.h>
#include <ast.h>
#include <misc.h>
#include <string.h>
#include <membuf.h>
#include <codegen.h>
#include <buffer.h>
#include <common.h>
#include <int16.h>

static FILE *fhi;

static struct icode_operand operands[3];

static char strBuf[25 + 1];

static void icode_write_operand(struct icode_operand *operand);
static int icodeUnitDeclarations(void);
static void icodeUnitRoutines(void);

void icodeFormatLabel(char *label, const char *str, short num)
{
    strcpy(label, str);
    strcat(label, formatInt16(num));
}

struct icode_operand* icodeOperChar(char num, char value)
{
    operands[num-1].type = IC_CHR;
    operands[num-1].literal.ch = value;

    return &operands[num-1];
}

struct icode_operand* icodeOperBool(char num, char value)
{
    operands[num-1].type = IC_BOO;
    operands[num-1].literal.boolean = value;

    return &operands[num-1];
}

struct icode_operand* icodeOperByte(char num, unsigned char value)
{
    operands[num-1].type = IC_IBU;
    operands[num-1].literal.uint8 = value;

    return &operands[num-1];
}

struct icode_operand* icodeOperShort(char num, char value)
{
    operands[num-1].type = IC_IBS;
    operands[num-1].literal.sint8 = value;

    return &operands[num-1];
}

struct icode_operand* icodeOperWord(char num, unsigned short value)
{
    operands[num-1].type = IC_IWU;
    operands[num-1].literal.uint16 = value;

    return &operands[num-1];
}

struct icode_operand* icodeOperInt(char num, short value)
{
    operands[num-1].type = IC_IWS;
    operands[num-1].literal.sint16 = value;

    return &operands[num-1];
}

struct icode_operand* icodeOperLong(char num, long value)
{
    operands[num-1].type = IC_ILS;
    operands[num-1].literal.sint32 = value;

    return &operands[num-1];
}

struct icode_operand* icodeOperCardinal(char num, unsigned long value)
{
    operands[num-1].type = IC_ILU;
    operands[num-1].literal.uint32 = value;

    return &operands[num-1];
}

struct icode_operand* icodeOperReal(char num, CHUNKNUM realBuf)
{
    operands[num-1].type = IC_FLT;
    operands[num-1].literal.realBuf = realBuf;

    return &operands[num-1];
}

struct icode_operand* icodeOperLabel(char num, char *label)
{
    operands[num-1].type = IC_LBL;
    operands[num-1].label = strBuf;

    strcpy(strBuf, label);

    return &operands[num-1];
}

struct icode_operand* icodeOperStr(char num, CHUNKNUM strBuf)
{
    operands[num-1].type = IC_STR;
    operands[num-1].literal.strBuf = strBuf;

    return &operands[num-1];
}

struct icode_operand* icodeOperVar(char num, char oper, char type, char level, char offset)
{
    operands[num-1].type = oper;
    operands[num-1].var.type = type;
    operands[num-1].var.level = level;
    operands[num-1].var.offset = offset;

    return &operands[num-1];
}

void icodeWriteMnemonic(ICODE_MNE instruction)
{
    fwrite(&instruction, 1, 1, fhi);
}

static int icodeUnitDeclarations(void)
{
	int numToPop = 0;
	struct unit _unit;
	struct decl _decl;
	struct stmt _stmt;
	CHUNKNUM chunkNum = units;
    char localVars[MAX_LOCAL_VARS];

    memset(localVars, 0, sizeof(localVars));
	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);
		retrieveChunk(_unit.astRoot, &_decl);
		retrieveChunk(_decl.code, &_stmt);
		numToPop += icodeVariableDeclarations(_stmt.decl, localVars);
		numToPop += icodeVariableDeclarations(_stmt.interfaceDecl, localVars);

		chunkNum = _unit.next;
	}

	return numToPop;
}

static void icodeUnitRoutines(void)
{
	struct decl _decl;
	struct stmt _stmt;
	struct unit _unit;
	CHUNKNUM chunkNum = units;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);
		retrieveChunk(_unit.astRoot, &_decl);
		retrieveChunk(_decl.code, &_stmt);

		icodeRoutineDeclarations(_stmt.decl);

		chunkNum = _unit.next;
	}
}

void icodeWrite(CHUNKNUM astRoot)
{
	struct decl _decl;
	struct stmt _stmt;
	// int i;
    int numToPop;
    char localVars[MAX_LOCAL_VARS];

    fhi = fopen(TMP_ZZICODE, "w");

	retrieveChunk(astRoot, &_decl);
	scope_enter_symtab(_decl.symtab);
	retrieveChunk(_decl.code, &_stmt);

	// Create stack entries for the global variables
    memset(localVars, 0, sizeof(localVars));
	numToPop = icodeVariableDeclarations(_stmt.decl, localVars);
	numToPop += icodeUnitDeclarations();

	// Skip over global function/procedure declarations and start main code
    icodeWriteUnaryLabel(IC_BRA, "MAIN");

	icodeRoutineDeclarations(_stmt.decl);

    icodeUnitRoutines();

    icodeWriteUnaryLabel(IC_LOC, "MAIN");
	icodeStmts(_stmt.body);

	scope_exit();
    fclose(fhi);
}

static void icodeWriteOperand(struct icode_operand *pOper)
{
    fwrite(&pOper->type, 1, 1, fhi);

    if (pOper->type == IC_VDR || pOper->type == IC_VDW ||
        pOper->type == IC_VVR || pOper->type == IC_VVW) {
        fwrite(&pOper->var.type, 1, 1, fhi);
        fwrite(&pOper->var.level, 1, 1, fhi);
        fwrite(&pOper->var.offset, 1, 1, fhi);
    } else if (pOper->type == IC_LBL) {
        fwrite(pOper->label, 1, strlen(pOper->label)+1, fhi);
    } else if (pOper->type == IC_STR || pOper->type == IC_FLT) {
        fwrite(&pOper->literal.strBuf, 2, 1, fhi);
    } else if (pOper->type != IC_RET) {
        unsigned char size;
        switch (pOper->type) {
            case IC_CHR:
            case IC_IBU:
            case IC_IBS:
            case IC_BOO:
                size = 1;
                break;

            case IC_IWU:
            case IC_IWS:
                size = 2;
                break;
            
            case IC_ILU:
            case IC_ILS:
                size = 4;
                break;
        }
        fwrite(&pOper->literal, size, 1, fhi);
    }
}

void icodeWriteUnary(ICODE_MNE instruction, struct icode_operand *pOper)
{
    icodeWriteMnemonic(instruction);
    icodeWriteOperand(pOper);
}

void icodeWriteUnaryLabel(ICODE_MNE instruction, char *operand)
{
    icodeWriteUnary(instruction, icodeOperLabel(1, operand));
}

void icodeWriteUnaryShort(ICODE_MNE instruction, char operand)
{
    icodeWriteUnary(instruction, icodeOperShort(1, operand));
}

void icodeWriteUnaryWord(ICODE_MNE instruction, unsigned short operand)
{
    icodeWriteUnary(instruction, icodeOperWord(1, operand));
}

void icodeWriteBinary(ICODE_MNE instruction, struct icode_operand *pOper1,
    struct icode_operand *pOper2)
{
    icodeWriteMnemonic(instruction);
    icodeWriteOperand(pOper1);
    icodeWriteOperand(pOper2);
}

void icodeWriteBinaryShort(ICODE_MNE instruction, char oper1, char oper2)
{
    icodeWriteBinary(instruction, icodeOperShort(1, oper1), icodeOperShort(2, oper2));
}

void icodeWriteTrinary(ICODE_MNE instruction, struct icode_operand *pOper1,
    struct icode_operand *pOper2, struct icode_operand *pOper3)
{
    icodeWriteMnemonic(instruction);
    icodeWriteOperand(pOper1);
    icodeWriteOperand(pOper2);
    icodeWriteOperand(pOper3);
}

void icodeWriteTrinaryShort(ICODE_MNE instruction, char oper1, char oper2, char oper3)
{
    icodeWriteTrinary(instruction, icodeOperShort(1, oper1),
        icodeOperShort(2, oper2), icodeOperShort(3, oper3));
}

char icodeDWordValue(CHUNKNUM chunkNum)
{
	struct expr _expr;
    struct type _type;

	if (!chunkNum) {
        _expr.value.cardinal = 0;
        _type.kind = TYPE_CARDINAL;
	} else {
        retrieveChunk(chunkNum, &_expr);
        retrieveChunk(_expr.evalType, &_type);
        if (_expr.neg) {
            _expr.value.longInt = -_expr.value.longInt;
            _type.kind = TYPE_LONGINT;
        }
    }

    icodeWriteUnary(IC_PSH, icodeOperCardinal(1, _expr.value.cardinal));
    return _type.kind;
}

void icodeRealValue(CHUNKNUM chunkNum)
{
    icodeWriteUnary(IC_PSH, icodeOperReal(1, chunkNum));
}

char icodeBoolValue(CHUNKNUM chunkNum)
{
	struct expr _expr;
    struct type _type;

	if (!chunkNum) {
        _expr.value.byte = 0;
        _type.kind = TYPE_BOOLEAN;
	} else {
        retrieveChunk(chunkNum, &_expr);
        retrieveChunk(_expr.evalType, &_type);
    }

    icodeWriteUnary(IC_PSH, icodeOperBool(1, _expr.value.byte));
    return _type.kind;
}

char icodeCharValue(CHUNKNUM chunkNum)
{
	struct expr _expr;
    struct type _type;

	if (!chunkNum) {
        _expr.value.character = 0;
        _type.kind = TYPE_CHARACTER;
	} else {
        retrieveChunk(chunkNum, &_expr);
        retrieveChunk(_expr.evalType, &_type);
    }

    icodeWriteUnary(IC_PSH, icodeOperChar(1, _expr.value.character));
    return _type.kind;
}

char icodeShortValue(CHUNKNUM chunkNum)
{
	struct expr _expr;
    struct type _type;

    _type.kind = TYPE_BYTE;
	if (!chunkNum) {
        _expr.value.shortInt = 0;
	} else {
        retrieveChunk(chunkNum, &_expr);
        if (_expr.evalType) {
            retrieveChunk(_expr.evalType, &_type);
            if (_expr.neg) {
                _expr.value.shortInt = -_expr.value.shortInt;
                _type.kind = TYPE_SHORTINT;
            }
        }
    }

    icodeWriteUnaryShort(IC_PSH, _expr.value.shortInt);
    return _type.kind;
}

void icodeStringValue(CHUNKNUM chunkNum)
{
    icodeWriteUnary(IC_PSH, icodeOperStr(1, chunkNum));
}

void icodeVar(char oper, char kind, unsigned char level, unsigned char offset)
{
    icodeWriteUnary(IC_PSH, icodeOperVar(1, oper, kind, level, offset));
}

char icodeWordValue(CHUNKNUM chunkNum)
{
	struct expr _expr;
    struct type _type;

	if (!chunkNum) {
        _expr.value.word = 0;
        _type.kind = TYPE_WORD;
	} else {
        retrieveChunk(chunkNum, &_expr);
        retrieveChunk(_expr.evalType, &_type);
        if (_expr.neg) {
            _expr.value.integer = -_expr.value.integer;
            _type.kind = TYPE_INTEGER;
        }
    }

    icodeWriteUnaryWord(IC_PSH, _expr.value.word);
    return _type.kind;
}

