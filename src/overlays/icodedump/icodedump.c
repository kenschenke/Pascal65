/**
 * icodedump.c
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
#include <membuf.h>

static struct {
    unsigned char code;
    const char *text;
} MneCodes[] = {
    {IC_ABS, "ABS"},
    {IC_ADD, "ADD"},
    {IC_AIX, "AIX"},
    {IC_AND, "AND"},
    {IC_ARR, "ARR"},
    {IC_ASF, "ASF"},
    {IC_BIF, "BIF"},
    {IC_BIT, "BIT"},
    {IC_BOO, "BOO"},
    {IC_BRA, "BRA"},
    {IC_BSL, "BSL"},
    {IC_BSR, "BSR"},
    {IC_BWA, "BWA"},
    {IC_BWC, "BWC"},
    {IC_BWO, "BWO"},
    {IC_CCT, "CCT"},
    {IC_CHR, "CHR"},
    {IC_CNL, "CNL"},
    {IC_CPY, "CPY"},
    {IC_CVI, "CVI"},
    {IC_DEC, "DEC"},
    {IC_DEF, "DEF"},
    {IC_DEL, "DEL"},
    {IC_DIV, "DIV"},
    {IC_DVI, "DVI"},
    {IC_EQU, "EQU"},
    {IC_FLT, "FLT"},
    {IC_FSO, "FSO"},
    {IC_GRT, "GRT"},
    {IC_GTE, "GTE"},
    {IC_IBS, "IBS"},
    {IC_IBU, "IBU"},
    {IC_ILS, "ILS"},
    {IC_ILU, "ILU"},
    {IC_INC, "INC"},
    {IC_INP, "INP"},
    {IC_IWS, "IWS"},
    {IC_IWU, "IWU"},
    {IC_JSR, "JSR"},
    {IC_LBL, "LBL"},
    {IC_LIN, "LIN"},
    {IC_LOC, "LOC"},
    {IC_LST, "LST"},
    {IC_LSE, "LSE"},
    {IC_MEM, "MEM"},
    {IC_MOD, "MOD"},
    {IC_MUL, "MUL"},
    {IC_NEG, "NEG"},
    {IC_NEQ, "NEQ"},
    {IC_NEW, "NEW"},
    {IC_NOT, "NOT"},
    {IC_ONL, "ONL"},
    {IC_ORA, "ORA"},
    {IC_OUT, "OUT"},
    {IC_POF, "POF"},
    {IC_POP, "POP"},
    {IC_PRE, "PRE"},
    {IC_PSH, "PSH"},
    {IC_PUF, "PUF"},
    {IC_RET, "RET"},
    {IC_ROU, "ROU"},
    {IC_SCV, "SCV"},
    {IC_SET, "SET"},
    {IC_SFH, "SFH"},
    {IC_SQR, "SQR"},
    {IC_SSP, "SSP"},
    {IC_SSR, "SSR"},
    {IC_SST, "SST"},
    {IC_SSW, "SSW"},
    {IC_STR, "STR"},
    {IC_SUB, "SUB"},
    {IC_SUC, "SUC"},
    {IC_TRU, "TRU"},
    {IC_VDR, "VDR"},
    {IC_VDW, "VDW"},
    {IC_VVR, "VVR"},
    {IC_VVW, "VVW"},
    {0, ""},
};

static void icodeCodeDump(unsigned char mnemonic);
static void icodeDumpOperand(FILE *fh);

static void icodeCodeDump(unsigned char mnemonic)
{
    int i = 0;

    while (MneCodes[i].code) {
        if (MneCodes[i].code == mnemonic) {
            printf("%s", MneCodes[i].text);
            return;
        }
        i++;
    }

    printf("???");
}

void icodeDump(void)
{
    unsigned char mnemonic;
    FILE *fh;

    fh = fopen(TMP_ZZICODE, "rb");

    while (!feof(fh)) {
        if (fread(&mnemonic, 1, 1, fh) != 1) {
            break;
        }

        icodeCodeDump(mnemonic);
        if ((mnemonic & IC_MASK_TRINARY) == IC_MASK_TRINARY) {
            printf(" ");
            icodeDumpOperand(fh);
            printf(" ");
            icodeDumpOperand(fh);
            printf(" ");
            icodeDumpOperand(fh);
        }
        else if ((mnemonic & IC_MASK_BINARY) == IC_MASK_BINARY) {
            printf(" ");
            icodeDumpOperand(fh);
            printf(" ");
            icodeDumpOperand(fh);
        }
        else if ((mnemonic & IC_MASK_UNARY) == IC_MASK_UNARY) {
            printf(" ");
            icodeDumpOperand(fh);
        }

        printf("\n");
    }

    fclose(fh);
}

static void icodeDumpOperand(FILE *fh)
{
    int size;
    struct icode_operand oper;

    fread(&oper.type, 1, 1, fh);

    icodeCodeDump(oper.type);
    printf(" ");

    if (oper.type == IC_VDR || oper.type == IC_VDW ||
        oper.type == IC_VVR || oper.type == IC_VVW) {
        for (int i = 0; i < 3; i++) {
            char ch;

            fread(&ch, 1, 1, fh);
            printf(" %d", ch);
        }
    } else if (oper.type == IC_LBL) {
        char ch;

        while (1) {
            fread(&ch, 1, 1, fh);
            if (!ch) {
                break;
            }
            printf("%c", ch);
        }
    } else if (oper.type == IC_STR || oper.type == IC_FLT) {
        char ch;
        CHUNKNUM chunkNum;

        fread(&chunkNum, 2, 1, fh);
        setMemBufPos(chunkNum, 0);
        while (!isMemBufAtEnd(chunkNum)) {
            readFromMemBuf(chunkNum, &ch, 1);
            printf("%c", ch);
        }
    } else if (oper.type != IC_RET) {
        switch (oper.type) {
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
        fread(&oper.literal, size, 1, fh);

        switch (oper.type) {
            case IC_BOO: printf("%s", oper.literal.boolean ? "true" : "false"); break;
            case IC_CHR: printf("%c", oper.literal.ch); break;
            case IC_IBU: printf("%u", oper.literal.uint8); break;
            case IC_IBS: printf("%d", oper.literal.sint8); break;
            case IC_IWU: printf("%u", oper.literal.uint16); break;
            case IC_IWS: printf("%d", oper.literal.sint16); break;
            case IC_ILU: printf("%lu", oper.literal.uint32); break;
            case IC_ILS: printf("%ld", oper.literal.sint32); break;
            default: printf("OPER ???:%02x", oper.type);
        }
    }
}
