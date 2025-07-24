/**
 * icodegen.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Intermediate Code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <icode.h>
#include <ast.h>
#include <codegen.h>
#include <asm.h>
#include <buffer.h>
#include <string.h>
#include <libcommon.h>
#include <int16.h>
#include <membuf.h>
#include <stdlib.h>

static char strBuf[MAX_LINE_LEN + 1];

static CHUNKNUM addArrayLiteral(CHUNKNUM exprChunk, int *bufSize, int elemSize);
static CHUNKNUM addRealArrayLiteral(CHUNKNUM exprChunk, int *bufSize);
static CHUNKNUM addStringArrayLiteral(CHUNKNUM exprChunk, short *numLiterals);
static int addStringLiteral(CHUNKNUM chunkNum);
static void genArrayInit(CHUNKNUM chunkNum);
static void genBinary(FILE *fh, ICODE_MNE mnemonic);
static void genComp(char compExpr, char leftType, char rightType);
static void genRecordInit(CHUNKNUM chunkNum);
static void genTrinary(FILE *fh, ICODE_MNE mnemonic);
static void genUnary(FILE *fh, ICODE_MNE mnemonic);
static int getArrayLimit(CHUNKNUM chunkNum);
static void icodeArrayInit(char *label, struct type* pType,
	CHUNKNUM exprInitChunk, CHUNKNUM declChunkNum);
static void icodeRecordInit(char *label, struct type* pType, CHUNKNUM declChunkNum);
static void readOperand(FILE *fh, struct icode_operand *pOper);

static CHUNKNUM addArrayLiteral(CHUNKNUM exprChunk, int *bufSize, int elemSize)
{
	struct expr _expr;
	CHUNKNUM memChunk;

	*bufSize = 0;
	if (!exprChunk) {
		return 0;
	}

	allocMemBuf(&memChunk);

	while (exprChunk) {
		retrieveChunk(exprChunk, &_expr);
		if (_expr.neg) _expr.value.longInt = -_expr.value.longInt;
		writeToMemBuf(memChunk, &_expr.value, elemSize);

		exprChunk = _expr.right;
		*bufSize += elemSize;
	}

	return memChunk;
}

static CHUNKNUM addRealArrayLiteral(CHUNKNUM exprChunk, int *bufSize)
{
	struct expr _expr;
	CHUNKNUM memChunk;

	allocMemBuf(&memChunk);
	*bufSize = 0;

	while (exprChunk) {
		retrieveChunk(exprChunk, &_expr);
		writeToMemBuf(memChunk, &_expr.neg, 1);
		writeToMemBuf(memChunk, &_expr.value.stringChunkNum, 2);

		exprChunk = _expr.right;
		*bufSize += 3;
	}

	return memChunk;
}

static CHUNKNUM addStringArrayLiteral(CHUNKNUM exprChunk, short *numLiterals)
{
	char ch;
	struct expr _expr;
	CHUNKNUM memChunk;

	if (!exprChunk) {
		return 0;
	}

	allocMemBuf(&memChunk);

	while (exprChunk) {
		retrieveChunk(exprChunk, &_expr);
		setMemBufPos(_expr.value.stringChunkNum, 0);
		while (!isMemBufAtEnd(_expr.value.stringChunkNum)) {
			readFromMemBuf(_expr.value.stringChunkNum, &ch, 1);
			writeToMemBuf(memChunk, &ch, 1);
		}
		ch = 0;
		writeToMemBuf(memChunk, &ch, 1);

		exprChunk = _expr.right;
		(*numLiterals)++;
	}

	return memChunk;
}

static int addStringLiteral(CHUNKNUM chunkNum)
{
	if (numStringLiterals == 0) {
		allocMemBuf(&stringLiterals);
	}

	writeToMemBuf(stringLiterals, &chunkNum, sizeof(CHUNKNUM));

	return ++numStringLiterals;
}

static void genArrayInit(CHUNKNUM chunkNum)
{
    struct decl _decl;
    struct expr _expr;
    struct type _type;
    char label[125];

    retrieveChunk(chunkNum, &_decl);
    retrieveChunk(_decl.type, &_type);
    getBaseType(&_type);

    heapOffset = 0;
    strcpy(label, "di");
    strcat(label, formatInt16(chunkNum));
    if (_decl.value) {
        retrieveChunk(_decl.value, &_expr);
        _decl.value = _expr.left;
    }
    icodeArrayInit(label, &_type, _decl.value, chunkNum);
}

static void genBinary(FILE *fh, ICODE_MNE mnemonic)
{
    struct icode_operand oper1, oper2;

    readOperand(fh, &oper1);
    readOperand(fh, &oper2);

    switch (mnemonic) {
    case IC_MOD:
        genTwo(LDA_IMMEDIATE, oper1.literal.sint8);
        genTwo(LDX_IMMEDIATE, oper2.literal.sint8);
        genThreeAddr(JSR, RT_MOD);
        break;
    
    case IC_DIV:
        genTwo(LDA_IMMEDIATE, oper1.literal.sint8);
        genTwo(LDX_IMMEDIATE, oper2.literal.sint8);
        genThreeAddr(JSR, RT_DIVIDE);
        break;
    
    case IC_SET:
        if (oper1.literal.sint8 == TYPE_STRING_VAR) {
            genThreeAddr(JSR, RT_POPEAX);  // pop the variable address off the stack
            genTwo(STA_ZEROPAGE, ZP_PTR1L);
            genTwo(STX_ZEROPAGE, ZP_PTR1H);
            genThreeAddr(JSR, RT_POPEAX);  // pop the rvalue off the stack
            genTwo(STA_ZEROPAGE, ZP_TMP1);
            genTwo(STX_ZEROPAGE, ZP_TMP2);
			genTwo(LDA_IMMEDIATE, oper2.literal.sint8);
			genThreeAddr(JSR, RT_PUSHAX);  // push the rvalue type onto the stack
            genTwo(LDA_ZEROPAGE, ZP_PTR1L);
            genTwo(LDX_ZEROPAGE, ZP_PTR1H);
			genThreeAddr(JSR, RT_PUSHAX);  // push the lvalue address onto the stack
            genTwo(LDA_ZEROPAGE, ZP_TMP1);
            genTwo(LDX_ZEROPAGE, ZP_TMP2);
            genThreeAddr(JSR, RT_ASSIGNSTRING);
            break;
        }
        genThreeAddr(JSR, RT_POPEAX);  // pop the variable info off the stack
        genTwo(STA_ZEROPAGE, ZP_PTR1L);
        genTwo(STX_ZEROPAGE, ZP_PTR1H);
        genTwo(LDX_IMMEDIATE, oper1.literal.sint8);
        genTwo(LDA_IMMEDIATE, oper2.literal.sint8);
        genThreeAddr(JSR, RT_ASSIGN);
        break;

    case IC_CCT:
        genThreeAddr(JSR, RT_POPEAX);
        genTwo(STA_ZEROPAGE, ZP_PTR2L);
        genTwo(STX_ZEROPAGE, ZP_PTR2H);
        genThreeAddr(JSR, RT_POPEAX);
        genTwo(STA_ZEROPAGE, ZP_PTR1L);
        genTwo(STX_ZEROPAGE, ZP_PTR1H);
        genTwo(LDA_IMMEDIATE, oper1.literal.sint8);
        genTwo(LDX_IMMEDIATE, oper2.literal.sint8);
        genThreeAddr(JSR, RT_CONCATSTRING);
        genThreeAddr(JSR, RT_PUSHEAX);
        break;

    case IC_EQU: genComp(EXPR_EQ,  oper1.literal.sint8, oper2.literal.sint8); break;
    case IC_NEQ: genComp(EXPR_NE,  oper1.literal.sint8, oper2.literal.sint8); break;
    case IC_LST: genComp(EXPR_LT,  oper1.literal.sint8, oper2.literal.sint8); break;
    case IC_LSE: genComp(EXPR_LTE, oper1.literal.sint8, oper2.literal.sint8); break;
    case IC_GRT: genComp(EXPR_GT,  oper1.literal.sint8, oper2.literal.sint8); break;
    case IC_GTE: genComp(EXPR_GTE, oper1.literal.sint8, oper2.literal.sint8); break;

    case IC_POF:
        // Restore the nesting level
        genTwo(LDA_IMMEDIATE, oper1.literal.uint8);
        genThreeAddr(JSR, RT_LIBSTACKCLEANUP);
        break;

    case IC_PUF:
        linkAddressLookup(oper2.label, codeOffset + 1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(oper2.label, codeOffset + 1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genTwo(LDY_IMMEDIATE, oper1.literal.uint8);
        genThreeAddr(JSR, RT_PUSHSTACKFRAMEHEADER);
        // Push the stack frame pointer onto the CPU stack.
        // This is popped back off by the ASF and JRP instructions.
        genOne(PHA);
        genOne(TXA);
        genOne(PHA);
        break;

    case IC_SFH:
        if (oper1.literal.uint8 == FH_FILENUM) {
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(LDA_ZEROPAGE, ZP_SREGL);
        } else {
            genTwo(LDA_IMMEDIATE, oper1.literal.uint8);
        }
        genTwo(LDX_IMMEDIATE, oper2.literal.uint8);
        genThreeAddr(JSR, RT_SETFH);
        if (oper1.literal.uint8 == FH_STRING) {
            genThreeAddr(JSR, RT_RESETSTRBUFFER);
        }
        break;

    case IC_CVI:
        genThreeAddr(JSR, RT_POPTOINTOP1AND2);
        genTwo(LDA_IMMEDIATE, oper1.literal.uint8);
        genTwo(LDX_IMMEDIATE, oper2.literal.uint8);
        genThreeAddr(JSR, RT_CONVERTINT);
        genThreeAddr(JSR, RT_PUSHFROMINTOP1AND2);
        break;

    case IC_DCF:
        linkAddressLookup(oper1.label, codeOffset + 1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(oper1.label, codeOffset + 1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genTwo(LDY_IMMEDIATE, oper2.literal.uint8);
        genThreeAddr(JSR, RT_FREEDECL);
        break;

    case IC_DCC:
        linkAddressLookup(oper1.label, codeOffset + 1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(oper1.label, codeOffset + 1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genTwo(LDY_IMMEDIATE, oper2.literal.uint8);
        genThreeAddr(JSR, RT_CLONEDECL);
        break;
    }
}

static void genComp(char compExpr, char leftType, char rightType)
{
    if (leftType == TYPE_ENUMERATION || leftType == TYPE_ENUMERATION_VALUE) {
        leftType = TYPE_WORD;
    }
    if (rightType == TYPE_ENUMERATION || rightType == TYPE_ENUMERATION_VALUE) {
        rightType = TYPE_WORD;
    }
    genTwo(LDA_IMMEDIATE, leftType);
    genTwo(LDX_IMMEDIATE, rightType);
    genTwo(LDY_IMMEDIATE, compExpr);
    genThreeAddr(JSR, RT_COMP);
}

static void genRecordInit(CHUNKNUM chunkNum)
{
    struct decl _decl;
    // struct expr _expr;
    struct type _type;
    char label[25];

    retrieveChunk(chunkNum, &_decl);
    retrieveChunk(_decl.type, &_type);
    getBaseType(&_type);

    heapOffset = 0;
    strcpy(label, "di");
    strcat(label, formatInt16(chunkNum));
    icodeRecordInit(label, &_type, chunkNum);
}

static void genTrinary(FILE *fh, ICODE_MNE mnemonic)
{
    unsigned short routine;
    struct icode_operand oper1, oper2, oper3;

    readOperand(fh, &oper1);
    readOperand(fh, &oper2);
    readOperand(fh, &oper3);

    switch (mnemonic) {
    case IC_ADD:
    case IC_SUB:
    case IC_MUL:
    case IC_DVI:
    case IC_BWA:
    case IC_BWO:
    case IC_BSL:
    case IC_BSR:
        switch(mnemonic) {
        case IC_ADD: routine = RT_ADD; break;
        case IC_SUB: routine = RT_SUBTRACT; break;
        case IC_MUL: routine = RT_MULTIPLY; break;
        case IC_DVI: routine = RT_DIVINT; break;
        case IC_BWA: routine = RT_BITWISEAND; break;
        case IC_BWO: routine = RT_BITWISEOR; break;
        case IC_BSL: routine = RT_BITWISELSHIFT; break;
        case IC_BSR: routine = RT_BITWISERSHIFT; break;
        }
        genTwo(LDA_IMMEDIATE, oper1.literal.sint8);
        genTwo(LDX_IMMEDIATE, oper2.literal.sint8);
        genTwo(LDY_IMMEDIATE, oper3.literal.sint8);
        genThreeAddr(JSR, routine);
        break;

    case IC_JSR:
        linkAddressLookup(oper1.label, codeOffset+1, LINKADDR_BOTH);
        genThreeAddr(oper3.literal.uint8 ? JSR : JMP, 0);
        break;

    case IC_PRP:
        genTwo(LDA_IMMEDIATE, oper2.literal.uint8);
        genTwo(STA_ZEROPAGE, ZP_SREGL);
        genTwo(LDA_IMMEDIATE, oper3.literal.uint8);
        genTwo(STA_ZEROPAGE, ZP_SREGH);
        linkAddressLookup(oper1.label, codeOffset+1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(oper1.label, codeOffset+1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genThreeAddr(JSR, RT_PUSHEAX);
        break;
    }
}

static void genUnary(FILE *fh, ICODE_MNE mnemonic)
{
    // char isAddr = 0;
    struct icode_operand oper;

    readOperand(fh, &oper);

    switch (mnemonic) {
    case IC_PSH:    // Push
        switch (oper.type) {
            case IC_BOO:
            case IC_CHR:
            case IC_IBU:
            case IC_IBS:
                genTwo(LDA_IMMEDIATE, oper.literal.boolean);
                genThreeAddr(JSR, RT_PUSHBYTESTACK);
                break;

            case IC_IWU:
            case IC_IWS:
                genTwo(LDA_IMMEDIATE, WORD_LOW(oper.literal.uint16));
                genTwo(LDX_IMMEDIATE, WORD_HIGH(oper.literal.uint16));
                genThreeAddr(JSR, RT_PUSHINTSTACK);
                break;

            case IC_ILU:
            case IC_ILS:
                genTwo(LDA_IMMEDIATE, DWORD_NMSB(oper.literal.uint32));
                genTwo(STA_ZEROPAGE, ZP_SREGL);
                genTwo(LDA_IMMEDIATE, DWORD_MSB(oper.literal.uint32));
                genTwo(STA_ZEROPAGE, ZP_SREGH);
                genTwo(LDA_IMMEDIATE, DWORD_LSB(oper.literal.uint32));
                genTwo(LDX_IMMEDIATE, DWORD_NLSB(oper.literal.uint32));
                genThreeAddr(JSR, RT_PUSHEAX);
                break;

            case IC_STR:
            case IC_FLT: {
                char label[15];

                int num = addStringLiteral(oper.literal.strBuf);
                strcpy(label, "strVal");
                strcat(label, formatInt16(num));
                linkAddressLookup(label, codeOffset + 1, LINKADDR_LOW);
                genTwo(LDA_IMMEDIATE, 0);
                linkAddressLookup(label, codeOffset + 1, LINKADDR_HIGH);
                genTwo(LDX_IMMEDIATE, 0);
                if (oper.type == IC_FLT) {
                    // Convert the string into a floating point value
                	genThreeAddr(JSR, RT_STRTOFLOAT);
                }
                genThreeAddr(JSR, RT_PUSHEAX);
                break;
            }

            case IC_VDR:
                genTwo(LDA_IMMEDIATE, oper.var.level);
                genTwo(LDX_IMMEDIATE, oper.var.offset);
                genTwo(LDY_IMMEDIATE, oper.var.type);
                genThreeAddr(JSR, RT_PUSHVAR);
                break;
            
            case IC_VDW:
                genTwo(LDA_IMMEDIATE, oper.var.level);
                genTwo(LDX_IMMEDIATE, oper.var.offset);
                genThreeAddr(JSR, RT_CALCSTACKOFFSET);
                genTwo(LDA_ZEROPAGE, ZP_PTR1L);
                genTwo(LDX_ZEROPAGE, ZP_PTR1H);
                genThreeAddr(JSR, RT_PUSHADDRSTACK);
                break;
            
            case IC_VVR:
                genTwo(LDA_IMMEDIATE, oper.var.level);
                genTwo(LDX_IMMEDIATE, oper.var.offset);
                genThreeAddr(JSR, RT_CALCSTACKOFFSET);
                genTwo(LDA_ZEROPAGE, ZP_PTR1L);
                genTwo(LDX_ZEROPAGE, ZP_PTR1H);
                genTwo(LDY_IMMEDIATE, 1);
                genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
                genOne(TAX);
                genOne(DEY);
                genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
                genThreeAddr(JSR, RT_PUSHINTSTACK);
                break;
            
            case IC_VVW:
                genTwo(LDA_IMMEDIATE, oper.var.level);
                genTwo(LDX_IMMEDIATE, oper.var.offset);
                genThreeAddr(JSR, RT_CALCSTACKOFFSET);
                genTwo(LDA_IMMEDIATE, 0);
                genTwo(STA_ZEROPAGE, ZP_SREGL);
                genTwo(STA_ZEROPAGE, ZP_SREGH);
                genTwo(LDY_IMMEDIATE, 1);
                genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
                genOne(TAX);
                genOne(DEY);
                genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
                genThreeAddr(JSR, RT_PUSHEAX);
                break;

            case IC_RET:
                genTwo(LDA_ZEROPAGE, ZP_STACKFRAMEL);
                genOne(SEC);
                genTwo(SBC_IMMEDIATE, 4);
                genOne(PHA);
                genTwo(LDA_ZEROPAGE, ZP_STACKFRAMEH);
                genTwo(SBC_IMMEDIATE, 0);
                genOne(TAX);
                genOne(PLA);
                genThreeAddr(JSR, RT_PUSHEAX);
                break;
        }
        break;

    case IC_OUT:
        if (oper.literal.uint8 == TYPE_SCALAR_BYTES) {
            genThreeAddr(JSR, RT_POPEAX);
            genOne(PHA);
            genOne(TXA);
            genOne(PHA);
            genThreeAddr(JSR, RT_POPTOINTOP1AND2);
            genTwo(LDA_IMMEDIATE, ZP_INTOP1L);
            genTwo(LDX_IMMEDIATE, 0);
            genThreeAddr(JSR, RT_PUSHEAX);
            genOne(PLA);
            genOne(TAX);
            genOne(PLA);
            genThreeAddr(JSR, RT_PUSHEAX);
            genThreeAddr(JSR, RT_WRITEBYTES);
        } else if (oper.literal.uint8 == TYPE_HEAP_BYTES) {
            genThreeAddr(JSR, RT_WRITEBYTES);
        } else if (oper.literal.uint8 == TYPE_REAL) {
            genThreeAddr(JSR, RT_POPEAX);   // precision
            genTwo(STA_ZEROPAGE, ZP_TMP1);  // store precision in tmp1
            genThreeAddr(JSR, RT_POPEAX);   // width
            genOne(PHA);                    // store width on CPU stack
			genThreeAddr(JSR, RT_POPTOREAL);// put value in FPACC
            genTwo(LDA_ZEROPAGE, ZP_TMP1);  // load precision back from tmp1
			genThreeAddr(JSR, RT_FPOUT);    // output value to string
            genOne(TAX);                    // put value width in X
            genOne(PLA);                    // pop field width off CPU stack
            genTwo(BEQ, 3);                 // skip if field width is zero
			genThreeAddr(JSR, RT_LEFTPAD);  // right pad value inside field width
			genTwo(LDA_IMMEDIATE, ZP_FPBUF);// load pointer to string in A/X
			genTwo(LDX_IMMEDIATE, 0);
			genThreeAddr(JSR, RT_PRINTZ);   // output string of floating point
        } else if (oper.literal.uint8 == TYPE_STRING_OBJ ||
            oper.literal.uint8 == TYPE_STRING_VAR)
        {
            genThreeAddr(JSR, RT_POPEAX);  // precision - ignore
            genThreeAddr(JSR, RT_POPEAX);  // width
            genOne(TAX);                   // transfer width to X
            genTwo(LDA_IMMEDIATE, oper.literal.uint8);
            genThreeAddr(JSR, RT_WRITEVALUE);
        } else if (oper.literal.uint8 == TYPE_ARRAY) {
            genThreeAddr(JSR, RT_POPEAX);  // precision - ignore
            genThreeAddr(JSR, RT_POPEAX);  // width
            genTwo(STA_ZEROPAGE, ZP_TMP1);
            genThreeAddr(JSR, RT_POPEAX);
            genOne(PHA);
            genOne(TXA);
            genOne(PHA);
            genTwo(LDA_ZEROPAGE, ZP_TMP1);
            genThreeAddr(JSR, RT_PUSHAX);
            genOne(PLA);
            genOne(TAX);
            genOne(PLA);
            genThreeAddr(JSR, RT_WRITECHARARRAY);
        } else {
            genThreeAddr(JSR, RT_POPEAX);  // precision - ignore
            genThreeAddr(JSR, RT_POPEAX);  // width
            if (oper.literal.uint8 == TYPE_STRING_LITERAL) {
                genThreeAddr(JSR, RT_WRITESTRLITERAL);
            } else {
                genOne(TAX);
                genTwo(LDA_IMMEDIATE, oper.literal.uint8);
                genThreeAddr(JSR, RT_WRITEVALUE);
            }
        }
        break;
    
    case IC_INP:
        switch (oper.literal.uint8) {
        case TYPE_SCALAR_BYTES:
        case TYPE_HEAP_BYTES:
            genThreeAddr(JSR, RT_READBYTES);
            break;

		case TYPE_CHARACTER:
		case TYPE_BYTE:
		case TYPE_SHORTINT:
			genThreeAddr(JSR, oper.literal.uint8 == TYPE_CHARACTER ? RT_READCHARFROMINPUT : RT_READINTFROMINPUT);
            genOne(PHA);
            genOne(TXA);
            genOne(PHA);
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(STA_ZEROPAGE, ZP_PTR1L);
            genTwo(STX_ZEROPAGE, ZP_PTR1H);
            genOne(PLA);
            genOne(TAX);
            genOne(PLA);
			genThreeAddr(JSR, RT_PUSHBYTESTACK);
			genThreeAddr(JSR, RT_STOREINTSTACK);
			break;

		case TYPE_INTEGER:
		case TYPE_WORD:
            genThreeAddr(JSR, RT_READINTFROMINPUT);
            genTwo(STA_ZEROPAGE, ZP_INTOP1L);
            genTwo(STX_ZEROPAGE, ZP_INTOP1H);
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(STA_ZEROPAGE, ZP_PTR1L);
            genTwo(STX_ZEROPAGE, ZP_PTR1H);
            genThreeAddr(JSR, RT_PUSHFROMINTOP1);
            genThreeAddr(JSR, RT_STOREINTSTACK);
			break;

		case TYPE_CARDINAL:
		case TYPE_LONGINT:
			genThreeAddr(JSR, RT_READINTFROMINPUT);
            genTwo(STA_ZEROPAGE, ZP_INTOP1L);
            genTwo(STX_ZEROPAGE, ZP_INTOP1H);
            genTwo(LDA_ZEROPAGE, ZP_SREGL);
            genTwo(STA_ZEROPAGE, ZP_INTOP2L);
            genTwo(LDA_ZEROPAGE, ZP_SREGH);
            genTwo(STA_ZEROPAGE, ZP_INTOP2H);
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(STA_ZEROPAGE, ZP_PTR1L);
            genTwo(STX_ZEROPAGE, ZP_PTR1H);
            genThreeAddr(JSR, RT_PUSHFROMINTOP1AND2);
			genThreeAddr(JSR, RT_STOREINT32STACK);
			break;

        case TYPE_REAL:
			genThreeAddr(JSR, RT_READFLOATFROMINPUT);
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(STA_ZEROPAGE, ZP_PTR1L);
            genTwo(STX_ZEROPAGE, ZP_PTR1H);
			genThreeAddr(JSR, RT_PUSHREALSTACK);
			genThreeAddr(JSR, RT_STOREREALSTACK);
            break;

        case TYPE_ARRAY:
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(STA_ZEROPAGE, ZP_PTR1L);
            genTwo(STX_ZEROPAGE, ZP_PTR1H);
            genTwo(LDY_IMMEDIATE, 1);
            genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
            genOne(TAX);
            genOne(DEY);
            genTwo(LDA_ZPINDIRECT, ZP_PTR1L);
			genThreeAddr(JSR, RT_READCHARARRAYFROMINPUT);
            break;

		case TYPE_STRING_VAR:
            genThreeAddr(JSR, RT_POPEAX);
			genThreeAddr(JSR, RT_READSTRINGFROMINPUT);
			break;
        }
        break;

    case IC_SST: {
        char label[15];

        int num = addStringLiteral(oper.literal.strBuf);
        strcpy(label, "strVal");
        strcat(label, formatInt16(num));
        linkAddressLookup(label, codeOffset + 1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(label, codeOffset + 1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genThreeAddr(JSR, RT_STRINGINIT);
        break;
    }

    case IC_LOC:
        linkAddressSet(oper.label, codeOffset);
        break;

    case IC_BRA:
        linkAddressLookup(oper.label, codeOffset+1, LINKADDR_BOTH);
        genThreeAddr(JMP, 0);
        break;
    
    case IC_BIF:
        genThreeAddr(JSR, RT_POPEAX);
        genTwo(CMP_IMMEDIATE, 0);
        genTwo(BNE, 3);
        linkAddressLookup(oper.label, codeOffset+1, LINKADDR_BOTH);
        genThreeAddr(JMP, 0);
        break;

    case IC_BIT:
        genThreeAddr(JSR, RT_POPEAX);
        genTwo(CMP_IMMEDIATE, 0);
        genTwo(BEQ, 3);
        linkAddressLookup(oper.label, codeOffset+1, LINKADDR_BOTH);
        genThreeAddr(JMP, 0);
        break;

    case IC_PRE:
    case IC_SUC:
        genTwo(LDA_IMMEDIATE, oper.literal.sint8);
        genThreeAddr(JSR, mnemonic == IC_PRE ? RT_PRED : RT_SUCC);
        break;

    case IC_NEW:
        genTwo(LDA_IMMEDIATE, WORD_LOW(oper.literal.uint16));
        genTwo(LDX_IMMEDIATE, WORD_HIGH(oper.literal.uint16));
        genThreeAddr(JSR, RT_HEAPALLOC);
        genThreeAddr(JSR, RT_PUSHEAX);
        break;

    case IC_AIX:
        genTwo(LDA_IMMEDIATE, oper.literal.uint8);
        genThreeAddr(JSR, RT_CALCARRAYELEM);
        break;

    case IC_BWC:
		genTwo(LDA_IMMEDIATE, oper.literal.uint8);
		genThreeAddr(JSR, RT_BITWISEINVERT);
        break;

    case IC_ABS:
		genTwo(LDA_IMMEDIATE, oper.literal.uint8);
		genThreeAddr(JSR, RT_ABS);
        break;

    case IC_SQR:
        genTwo(LDA_IMMEDIATE, oper.literal.uint8);
        genThreeAddr(JSR, RT_SQR);
        break;

    case IC_CPY:
        genTwo(LDA_IMMEDIATE, WORD_LOW(oper.literal.uint16));
        genTwo(LDX_IMMEDIATE, WORD_HIGH(oper.literal.uint16));
        genThreeAddr(JSR, RT_HEAPALLOC);
        genTwo(STA_ZEROPAGE, ZP_PTR1L);
        genTwo(STX_ZEROPAGE, ZP_PTR1H);
        genOne(PHA);
        genOne(TXA);
        genOne(PHA);
        genThreeAddr(JSR, RT_POPEAX);
        genTwo(STA_ZEROPAGE, ZP_PTR2L);
        genTwo(STX_ZEROPAGE, ZP_PTR2H);
        genTwo(LDA_IMMEDIATE, WORD_LOW(oper.literal.uint16));
        genTwo(LDX_IMMEDIATE, WORD_HIGH(oper.literal.uint16));
        genThreeAddr(JSR, RT_MEMCOPY);
        genTwo(LDA_IMMEDIATE, 0);
        genTwo(STA_ZEROPAGE, ZP_SREGL);
        genTwo(STA_ZEROPAGE, ZP_SREGH);
        genOne(PLA);
        genOne(TAX);
        genOne(PLA);
        genThreeAddr(JSR, RT_PUSHEAX);
        break;

    case IC_SCV:
        genThreeAddr(JSR, RT_POPEAX);
        genTwo(LDY_IMMEDIATE, oper.literal.uint8);
        genThreeAddr(JSR, RT_CONVERTSTRING);
        genThreeAddr(JSR, RT_PUSHEAX);
        break;

    case IC_ASF:
        genOne(PLA);
        genTwo(STA_ZEROPAGE, ZP_STACKFRAMEH);
        genOne(PLA);
        genTwo(STA_ZEROPAGE, ZP_STACKFRAMEL);
        genTwo(LDA_ZEROPAGE, ZP_NESTINGLEVEL);
        genOne(PHA);
        genTwo(LDA_IMMEDIATE, oper.literal.uint8);
        genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);
        break;

    case IC_SSP:
        linkAddressLookup(oper.label, codeOffset+1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        genTwo(STA_ZEROPAGE, ZP_PTR1L);
        linkAddressLookup(oper.label, codeOffset+1, LINKADDR_HIGH);
        genTwo(LDA_IMMEDIATE, 0);
        genTwo(STA_ZEROPAGE, ZP_PTR1H);
        genTwo(LDY_IMMEDIATE, 0);
        genTwo(LDA_ZEROPAGE, ZP_SPL);
        genTwo(STA_ZPINDIRECT, ZP_PTR1L);
        genOne(INY);
        genTwo(LDA_ZEROPAGE, ZP_SPH);
        genTwo(STA_ZPINDIRECT, ZP_PTR1L);
        break;

    case IC_LIN:
#if 0
		genOne(NOP);
		genOne(PHA);
		genTwo(LDA_IMMEDIATE, oper.literal.uint8);
		genOne(PLA);
		genOne(NOP);
#endif
        break;

    case IC_MEM:
        genTwo(LDA_IMMEDIATE, oper.literal.uint8);
        genThreeAddr(JSR, RT_READVAR);
        break;

    case IC_PPF:
        genThreeAddr(JSR, RT_POPEAX);
        linkAddressLookup(oper.label, codeOffset + 1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(oper.label, codeOffset + 1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genTwo(LDY_ZEROPAGE, ZP_SREGL);
        genThreeAddr(JSR, RT_PUSHSTACKFRAMEHEADER);
        // Push the stack frame pointer onto the CPU stack.
        // This is popped back off by the ASF and JRP instructions.
        genOne(PHA);
        genOne(TXA);
        genOne(PHA);
        break;

    case IC_DIA:
        genArrayInit(oper.literal.uint16);
        break;

    case IC_DIR:
        genRecordInit(oper.literal.uint16);
        break;
    }
}

static int getArrayLimit(CHUNKNUM chunkNum)
{
	struct expr _expr;

    retrieveChunk(chunkNum, &_expr);
	if (_expr.kind == EXPR_BYTE_LITERAL) {
		return _expr.neg ? -_expr.value.shortInt : _expr.value.shortInt;
	}
	else if (_expr.kind == EXPR_WORD_LITERAL) {
		return _expr.neg ? -_expr.value.integer : _expr.value.integer;
	}
	else if (_expr.kind == EXPR_CHARACTER_LITERAL) {
		return _expr.value.character;
	}
	else if (_expr.kind == EXPR_NAME) {
		struct symbol sym;
		struct decl _decl;
		char name[CHUNK_LEN + 1];
		memset(name, 0, sizeof(name));
		retrieveChunk(_expr.name, name);
		scope_lookup(name, &sym);
		retrieveChunk(sym.decl, &_decl);
		return getArrayLimit(_decl.value);
	}
	else {
		Error(errInvalidIndexType);
	}

	return 0;
}

static void icodeArrayInit(char *label, struct type* pType,
	CHUNKNUM exprInitChunk, CHUNKNUM declChunkNum)
{
	int bufSize, index;
	CHUNKNUM declMemBuf;
	struct expr exprInit;
	struct ARRAYDECL arrayDecl;
	struct type indexType, elemType;
	int numElements, lowBound, highBound;

	memset(&arrayDecl, 0, sizeof(struct ARRAYDECL));

	retrieveChunk(pType->indextype, &indexType);
	retrieveChunk(pType->subtype, &elemType);

	lowBound = getArrayLimit(indexType.min);
	highBound = getArrayLimit(indexType.max);
	numElements = abs(highBound - lowBound) + 1;

	if (exprInitChunk) {
		retrieveChunk(exprInitChunk, &exprInit);
	} else {
		memset(&exprInit, 0, sizeof(struct expr));
	}

	// Check if the element is a record
	if (elemType.kind == TYPE_DECLARED) {
        if (elemType.subtype) {
            retrieveChunk(elemType.subtype, &elemType);
        } else {
            Error(errUndefinedIdentifier);
        }
	}

	arrayDecl.elemSize = elemType.size;
	arrayDecl.heapOffset = heapOffset;
	arrayDecl.minIndex = lowBound;
	arrayDecl.maxIndex = highBound;
	if (elemType.kind == TYPE_ARRAY) {
		arrayDecl.elemType = ARRAYDECL_ARRAY;
	} else if (elemType.kind == TYPE_RECORD) {
		arrayDecl.elemType = ARRAYDECL_RECORD;
	} else if (elemType.kind == TYPE_STRING_VAR) {
		arrayDecl.elemType = ARRAYDECL_STRING;
		arrayDecl.literals = addStringArrayLiteral(exprInitChunk, &arrayDecl.numLiterals);
	} else if (elemType.kind == TYPE_FILE || elemType.kind == TYPE_TEXT) {
		arrayDecl.elemType = ARRAYDECL_FILE;
	} else if (elemType.kind != TYPE_ARRAY && elemType.kind != TYPE_RECORD) {
		if (elemType.kind == TYPE_REAL) {
			arrayDecl.literals = addRealArrayLiteral(exprInitChunk, &bufSize);
			arrayDecl.elemType = ARRAYDECL_REAL;
			arrayDecl.numLiterals = bufSize / 3;
		} else {
			arrayDecl.literals = addArrayLiteral(exprInitChunk, &bufSize, elemType.size);
			arrayDecl.numLiterals = bufSize / elemType.size;
		}
	}

	if (!arrayInits) {
		allocMemBuf(&arrayInits);
	}

	writeToMemBuf(arrayInits, label, strlen(label)+1);

	allocMemBuf(&declMemBuf);
	writeToMemBuf(declMemBuf, &arrayDecl, sizeof(struct ARRAYDECL));
	writeToMemBuf(arrayInits, &declMemBuf, sizeof(CHUNKNUM));

    linkAddressLookup(label, codeOffset + 1, LINKADDR_LOW);
    genTwo(LDA_IMMEDIATE, 0);
    linkAddressLookup(label, codeOffset + 1, LINKADDR_HIGH);
    genTwo(LDX_IMMEDIATE, 0);
    genTwo(LDY_IMMEDIATE, LOCALVARS_ARRAY);
    genThreeAddr(JSR, RT_INITDECL);

	heapOffset += 6;  // move past array header

	if (elemType.kind == TYPE_ARRAY || elemType.kind == TYPE_RECORD) {
		int i;
		for (index = lowBound, i = 1; index <= highBound; ++index,++i) {
			char elemLabel[20];
			strcpy(elemLabel, label);
			strcat(elemLabel, ".");
			strcat(elemLabel, formatInt16(i));
			if (elemType.kind == TYPE_ARRAY) {
				icodeArrayInit(elemLabel, &elemType, exprInit.left, declChunkNum);
			} else {
				icodeRecordInit(elemLabel, &elemType, declChunkNum);
			}
			if (exprInit.right) {
				retrieveChunk(exprInit.right, &exprInit);
			} else {
				exprInit.left = exprInit.right = 0;
			}
		}
	} else {
		heapOffset += elemType.size * numElements;
	}
}

static void icodeRecordInit(char *label, struct type* pType, CHUNKNUM declChunkNum)
{
	char memberType;
	struct symbol sym;
	struct decl fieldDecl;
	struct type fieldType;
	short fieldOffset = 0;
	short recordOffset = heapOffset;  // heap offset at start of record
	short saveHeapOffset;  // save the heap offset and revert it for embedded arrays
	CHUNKNUM chunkNum = pType->paramsFields;
	CHUNKNUM declMemBuf = 0;

	while (chunkNum) {
		retrieveChunk(chunkNum, &fieldDecl);
		retrieveChunk(fieldDecl.type, &fieldType);

		memberType = 0;

		if (fieldDecl.node) {
			retrieveChunk(fieldDecl.node, &sym);
		} else {
			memset(&sym, 0, sizeof(struct symbol));
		}

		if (fieldType.kind == TYPE_DECLARED) {
			retrieveChunk(sym.type, &fieldType);
		}

		if (fieldType.kind == TYPE_RECORD) {
			char label[25];
			// Record field is an embedded record
            strcpy(label, "di");
            strcat(label, formatInt16(declChunkNum));
			icodeRecordInit(label, &fieldType, declChunkNum);
		} else if (fieldType.kind == TYPE_STRING_VAR) {
			memberType = LOCALVARS_STRING;
		} else if (fieldType.kind == TYPE_FILE || fieldType.kind == TYPE_TEXT) {
			memberType = LOCALVARS_FILE;
		} else if (fieldType.kind == TYPE_ARRAY) {
			char fieldLabel[25];
			// Record field is an array
			strcpy(fieldLabel, label);
			strcat(fieldLabel, formatInt16(declChunkNum));
			strcat(fieldLabel, ".");
			strcat(fieldLabel, formatInt16(fieldOffset));
			saveHeapOffset = heapOffset;
			icodeArrayInit(fieldLabel, &fieldType, fieldDecl.value, declChunkNum);
			heapOffset = saveHeapOffset;
			memberType = LOCALVARS_ARRAY;
		}
	
		if (!declMemBuf) {
			allocMemBuf(&declMemBuf);
			writeToMemBuf(declMemBuf, &recordOffset, sizeof(short));
			writeToMemBuf(declMemBuf, &pType->size, sizeof(short));
		}

		if (memberType) {
			writeToMemBuf(declMemBuf, &memberType, 1);
			writeToMemBuf(declMemBuf, &declChunkNum, sizeof(CHUNKNUM));
			writeToMemBuf(declMemBuf, &fieldOffset, sizeof(short));
		}
	
		heapOffset += fieldType.size;
		fieldOffset += fieldType.size;
		chunkNum = fieldDecl.next;
	}

	if (declMemBuf) {
		char eob = 0;  // end of buffer character
		writeToMemBuf(declMemBuf, &eob, 1);

		if (!recordInits) {
			allocMemBuf(&recordInits);
		}

		writeToMemBuf(recordInits, label, strlen(label)+1);
		writeToMemBuf(recordInits, &declMemBuf, sizeof(CHUNKNUM));

        linkAddressLookup(label, codeOffset + 1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(label, codeOffset + 1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genTwo(LDY_IMMEDIATE, LOCALVARS_RECORD);
        genThreeAddr(JSR, RT_INITDECL);
	}
}

void icodeGen(void)
{
    unsigned char mnemonic;
    FILE *fh;

    fh = fopen(TMP_ZZICODE, "rb");

    while (!feof(fh)) {
        if (fread(&mnemonic, 1, 1, fh) != 1) {
            break;
        }

        if ((mnemonic & IC_MASK_TRINARY) == IC_MASK_TRINARY) {
            genTrinary(fh, mnemonic);
        }
        else if ((mnemonic & IC_MASK_BINARY) == IC_MASK_BINARY) {
            genBinary(fh, mnemonic);
        }
        else if ((mnemonic & IC_MASK_UNARY) == IC_MASK_UNARY) {
            genUnary(fh, mnemonic);
        } else if (mnemonic == IC_ONL) {
            genTwo(LDA_IMMEDIATE, 13);	// carriage return
            genThreeAddr(JSR, CHROUT);
        } else if (mnemonic == IC_AND || mnemonic == IC_ORA) {
            genThreeAddr(JSR, RT_POPTOINTOP1);
            genThreeAddr(JSR, RT_POPTOINTOP2);
            genTwo(LDA_ZEROPAGE, ZP_INTOP1L);
            genTwo(mnemonic == IC_AND ? AND_ZEROPAGE : ORA_ZEROPAGE, ZP_INTOP2L);
            genThreeAddr(JSR, RT_PUSHBYTESTACK);
        } else if (mnemonic == IC_ROU || mnemonic == IC_TRU) {
            genThreeAddr(JSR, RT_POPTOREAL);
            if (mnemonic == IC_ROU) {
                genTwo(LDA_IMMEDIATE, 0);	// Round to 0 decimal places
                genThreeAddr(JSR, RT_PRECRD);
            }
            genThreeAddr(JSR, RT_FLOATTOINT16);
            genThreeAddr(JSR, RT_PUSHFROMINTOP1);
        } else if (mnemonic == IC_POP) {
            genThreeAddr(JSR, RT_INCSP4);
        } else if (mnemonic == IC_DEL) {
            genThreeAddr(JSR, RT_POPEAX);
            genThreeAddr(JSR, RT_HEAPFREE);
        } else if (mnemonic == IC_DEF) {
            genThreeAddr(JSR, RT_FILEFREE);
        } else if (mnemonic == IC_CNL) {
    		genThreeAddr(JSR, RT_CLEARINPUTBUF);
        } else if (mnemonic == IC_NOT) {
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(AND_IMMEDIATE, 1);
            genTwo(EOR_IMMEDIATE, 1);
            genThreeAddr(JSR, RT_PUSHEAX);
        } else if (mnemonic == IC_SSR) {
            genThreeAddr(JSR, RT_POPEAX);
            genThreeAddr(JSR, RT_STRINGSUBSCRIPTREAD);
            genTwo(LDX_IMMEDIATE, 0);
            genTwo(STX_ZEROPAGE, ZP_SREGL);
            genTwo(STX_ZEROPAGE, ZP_SREGH);
            genThreeAddr(JSR, RT_PUSHEAX);
        } else if (mnemonic == IC_SSW) {
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(STA_ZEROPAGE, ZP_TMP1);
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(LDY_ZEROPAGE, ZP_TMP1);
            genThreeAddr(JSR, RT_STRINGSUBSCRIPTCALC);
            genThreeAddr(JSR, RT_PUSHADDRSTACK);
        } else if (mnemonic == IC_FSO) {
            genThreeAddr(JSR, RT_GETSTRBUFFER);
            genThreeAddr(JSR, RT_PUSHEAX);
        } else if (mnemonic == IC_JRP) {
            // Activate the stack frame
            genOne(PLA);
            genTwo(STA_ZEROPAGE, ZP_STACKFRAMEH);
            genOne(PLA);
            genTwo(STA_ZEROPAGE, ZP_STACKFRAMEL);
            genThreeAddr(JSR, RT_POPEAX);
            genTwo(STA_ZEROPAGE, ZP_TMP1);
            genTwo(STX_ZEROPAGE, ZP_TMP2);
            genTwo(LDA_ZEROPAGE, ZP_NESTINGLEVEL);
            genOne(PHA);
            genTwo(LDA_ZEROPAGE, ZP_SREGL);
            genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);
            genThreeAddr(JMP_INDIRECT, ZP_TMP1);
        } else if (mnemonic == IC_RTS) {
            genThreeAddr(JMP, RT_RETURNFROMROUTINE);
        }
    }

    fclose(fh);
}

static void readOperand(FILE *fh, struct icode_operand *pOper)
{
    int size;

    fread(&pOper->type, 1, 1, fh);

    if (pOper->type == IC_LBL) {
        int i = 0;

        while (1) {
            fread(strBuf+i, 1, 1, fh);
            if (!strBuf[i]) {
                break;
            }
            i++;
        }
        pOper->label = strBuf;
    } else if (pOper->type == IC_VDR || pOper->type == IC_VDW ||
            pOper->type == IC_VVR || pOper->type == IC_VVW) {
        fread(&pOper->var.type, 1, 1, fh);
        fread(&pOper->var.level, 1, 1, fh);
        fread(&pOper->var.offset, 1, 1, fh);
    } else if (pOper->type != IC_RET) {
        switch (pOper->type) {
            case IC_CHR:
            case IC_IBU:
            case IC_IBS:
            case IC_BOO:
                size = 1;
                break;

            case IC_IWU:
            case IC_IWS:
            case IC_FLT:
            case IC_STR:
                size = 2;
                break;
            
            case IC_ILU:
            case IC_ILS:
                size = 4;
                break;
        }
        fread(&pOper->literal, size, 1, fh);
    }
}
