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

static char strBuf[MAX_LINE_LEN + 1];

static int addStringLiteral(CHUNKNUM chunkNum);
static void genBinary(FILE *fh, ICODE_MNE mnemonic);
static void genComp(char compExpr, char leftType, char rightType);
static void genTrinary(FILE *fh, ICODE_MNE mnemonic);
static void genUnary(FILE *fh, ICODE_MNE mnemonic);
static void readOperand(FILE *fh, struct icode_operand *pOper);

static int addStringLiteral(CHUNKNUM chunkNum)
{
	if (numStringLiterals == 0) {
		allocMemBuf(&stringLiterals);
	}

	writeToMemBuf(stringLiterals, &chunkNum, sizeof(CHUNKNUM));

	return ++numStringLiterals;
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
        genOne(PLA);
        genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);

        // Restore the caller's stack frame base pointer
        genThreeAddr(JSR, RT_POPEAX);
        genTwo(STA_ZEROPAGE, ZP_STACKFRAMEL);
        genTwo(STX_ZEROPAGE, ZP_STACKFRAMEH);

    	genThreeAddr(JSR, RT_INCSP4);	// Pop the static link off the stack

        genThreeAddr(JSR, RT_POPEAX);
        if (oper2.literal.uint8) {
            // Routine is library call - ignore the caller's return address
        } else {
            // Routine is a declared routine - save the caller's return address
            genOne(PHA);
            genOne(TXA);
            genOne(PHA);
        }

        if (!oper1.literal.uint8) {
            // Routine is a procedure - pop the unused return value off the stack
            genThreeAddr(JSR, RT_INCSP4);
        }

        if (!oper2.literal.uint8) {
            // Routine is a declared routine - put the caller's return address back
            genOne(PLA);
            genOne(TAX);
            genOne(PLA);
            genThreeAddr(JSR, RT_PUSHEAX);
            genThreeAddr(JMP, RT_RETURNFROMROUTINE);
        }
        break;

    case IC_PUF:
        linkAddressLookup(oper2.label, codeOffset + 1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(oper2.label, codeOffset + 1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genTwo(LDY_IMMEDIATE, oper1.literal.uint8);
        genThreeAddr(JSR, RT_PUSHSTACKFRAMEHEADER);
        // Push the stack frame pointer onto the CPU stack.
        // This is popped back off by the ASF instruction.
        genOne(PHA);
        genOne(TXA);
        genOne(PHA);
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
        genTwo(LDA_IMMEDIATE, oper2.literal.uint8);
        genTwo(STA_ZEROPAGE, ZP_NESTINGLEVEL);
        linkAddressLookup(oper1.label, codeOffset+1, LINKADDR_BOTH);
        genThreeAddr(oper3.literal.uint8 ? JSR : JMP, 0);
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

            case IC_MEM:
                genThreeAddr(JSR, RT_READVAR);
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
        if (oper.literal.uint8 == TYPE_REAL) {
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

    case IC_ARR:
        linkAddressLookup(oper.label, codeOffset+1, LINKADDR_LOW);
        genTwo(LDA_IMMEDIATE, 0);
        linkAddressLookup(oper.label, codeOffset+1, LINKADDR_HIGH);
        genTwo(LDX_IMMEDIATE, 0);
        genThreeAddr(JSR, RT_INITARRAYS);
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

    case IC_SOF:
        if (!oper.literal.uint8) {
            genOne(PLA);
        } else {
            genTwo(LDA_IMMEDIATE, oper.literal.uint8);
        }
        genThreeAddr(JSR, RT_SETFH);
        if (oper.literal.uint8) {
            genOne(PHA);	// push previous FH to stack
            if (oper.literal.uint8 == FH_STRING) {
                genThreeAddr(JSR, RT_RESETSTRBUFFER);
            }
        }
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
    } else if (pOper->type != IC_MEM && pOper->type != IC_RET) {
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
