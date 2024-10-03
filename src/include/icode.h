/**
 * icode.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Intermediate Code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef ICODE_H
#define ICODE_H

#include <chunks.h>

/*
    Intermediate Code

    Pascal65 uses intermediate code to bridge between the AST and code
    generation. The icode overlay traverses the AST and produces intermediate
    code that loosely resembles the assembly language that will
    eventually be generated.

    Each intruction in intermediate code (icode) consists of a instruction
    byte followed by zero, one, or two operands. An icode instruction uses
    a three-letter mnemonic. The mnemonic becomes a one-byte number.
*/

#define TMP_ZZICODE "zzicode"

/*****************************************************************************
 * Mnemonics
 * 
 * The mnemonics are divided into groups that can be easily identified by
 * applying a mask.
 *****************************************************************************/

typedef unsigned char ICODE_MNE;

// Literal operand types
#define IC_CHR              0x11  // 0001 0001
#define IC_IBU              0x12  // 0001 0010
#define IC_IBS              0x13  // 0001 0011
#define IC_BOO              0x14  // 0001 0100
#define IC_IWU              0x15  // 0001 0101
#define IC_IWS              0x16  // 0001 0110
#define IC_ILU              0x17  // 0001 0111
#define IC_ILS              0x18  // 0001 1000
#define IC_FLT              0x19  // 0001 1001
#define IC_STR              0x1a  // 0001 1010

// Variable operand types
#define IC_VDR              0xf1  // 1111 0001  direct read
#define IC_VDW              0xf2  // 1111 0010  direct write
#define IC_VVR              0xf3  // 1111 0011  var (by ref) read
#define IC_VVW              0xf4  // 1111 0100  var (by ref) write

// Non-literal operand types
#define IC_LBL              0x1b  // 0001 1011
#define IC_RET              0x1d  // 0001 1101  memory address of return value

// These instructions take no operands
#define IC_AND              0x01  // 0000 0001
#define IC_ORA              0x02  // 0000 0010
#define IC_ONL              0x03  // 0000 0011
#define IC_ROU              0x04  // 0000 0100  round
#define IC_TRU              0x05  // 0000 0101  trunc
#define IC_POP              0x06  // 0000 0110  pop (discard) value from runtime stack
#define IC_DEL              0x07  // 0000 0111  pop and free memory address off rt stack
#define IC_CNL              0x08  // 0000 1000  clear input to new line character
#define IC_NOT              0x09  // 0000 1001  replace top of runtime stack with logical not
#define IC_SSR              0x0a  // 0000 1010  string subscript read
#define IC_SSW              0x0b  // 0000 1011  string subscript write
#define IC_FSO              0x0c  // 0000 1100  flush string output
#define IC_DEF              0x0d  // 0000 1101  pop and free a file handle and close file
#define IC_JRP              0x0e  // 0000 1110  call a routine from a pointer on the stack

// These instructions take one operand
#define IC_MASK_UNARY       0x20  // 0010 0000
#define IC_NEG              0x22  // 0010 0010  1:type
#define IC_ABS              0x23  // 0010 0011  1:type
#define IC_PPF              0x24  // 0010 0100  1:label
#define IC_INP              0x26  // 0010 0110  1:type
#define IC_PSH              0x27  // 0010 0111  1:type
#define IC_PRE              0x28  // 0010 1000  1:type
#define IC_SUC              0x29  // 0010 1001  1:type
#define IC_OUT              0x2a  // 0010 1010  1:type
#define IC_NEW              0x2b  // 0010 1011  1:size  allocate heap for recs/arrays
#define IC_ARR              0x2c  // 0010 1100  1:label for array init structures
#define IC_SST              0x2d  // 0010 1101  1:pointer to string literal (or 0 for empty)
#define IC_LOC              0x2e  // 0010 1110  1:label (define location)
#define IC_BRA              0x2f  // 0010 1111  1:label
#define IC_BIT              0x30  // 0011 0000  1:label
#define IC_BIF              0x31  // 0011 0001  1:label
#define IC_LIN              0x32  // 0011 0010  1:line number
#define IC_AIX              0x33  // 0011 0011  1:indexType
                                  // address of array on stack (under index), address of elem left on stack
#define IC_BWC              0x34  // 0011 0100  1:type (bitwise complement)
#define IC_SQR              0x35  // 0011 0101  1:type
#define IC_CPY              0x36  // 0011 0110  1:size -- clone memory at top of stack and replace
#define IC_SCV              0x37  // 0011 0111  1:type -- string convert for routine parameters
#define IC_ASF              0x38  // 0011 1000  1:routineLevel - activate stack frame
#define IC_SSP              0x39  // 0011 1001  1:label - store stack pointer at label
#define IC_MEM              0x3a  // 0011 1010  1:type

// These instructions take two operands
#define IC_MASK_BINARY      0x40  // 0100 0000
#define IC_SET              0x41  // 0100 0001  1:varType, 2:rightType (value on stack, then variable)
#define IC_MOD              0x42  // 0100 0010  1:leftType, 2:rightType (values on stack)
#define IC_DIV              0x43  // 0100 0011  1:leftType, 2:rightType
#define IC_GRT              0x44  // 0100 0100  1:leftType, 2:rightType
#define IC_GTE              0x45  // 0100 0101  1:leftType, 2:rightType
#define IC_LST              0x46  // 0100 0110  1:leftType, 2:rightType
#define IC_LSE              0x47  // 0100 0111  1:leftType, 2:rightType
#define IC_EQU              0x48  // 0100 1000  1:leftType, 2:rightType
#define IC_NEQ              0x49  // 0100 1001  1:leftType, 2:rightType
#define IC_CCT              0x4a  // 0100 1010  1:leftType, 2:rightType concatenate
#define IC_PUF              0x4b  // 0100 1011  1:routineLevel, 2:returnLabel -- push stack frame
#define IC_POF              0x4c  // 0100 1100  1:isFunc, 2:isLibrary -- pop stack frame and return to caller
#define IC_DEC              0x4d  // 0100 1101  1:variable type, 2:increment value type
#define IC_INC              0x4e  // 0100 1110  1:variable type, 2:increment value type
#define IC_SFH              0x4f  // 0100 1111  Set file handle 1:file handle 2:0/output 1/input
#define IC_CVI              0x50  // 0101 0000  1:from type, 2:to type

// These instructions take three operands
#define IC_MASK_TRINARY     0x80
#define IC_ADD              0x81  // 1000 0001  1:leftType, 2:rightType, 3:resultType
#define IC_SUB              0x82  // 1000 0010  1:leftType, 2:rightType, 3:resultType
#define IC_MUL              0x83  // 1000 0011  1:leftType, 2:rightType, 3:resultType
#define IC_DVI              0x84  // 1000 0100  1:leftType, 2:rightType, 3:resultType
#define IC_BWA              0x85  // 1000 0101  1:leftType, 2:rightType, 3:resultType (bitwise and)
#define IC_BWO              0x86  // 1000 0110  1:leftType, 2:rightType, 3:resultType (bitwise or)
#define IC_BSL              0x87  // 1000 0111  1:leftType, 2:rightType, 3:resultType (bitwise left-shift)
#define IC_BSR              0x88  // 1000 1000  1:leftType, 2:rightType, 3:resultType (bitwise right-shift)
#define IC_JSR              0x89  // 1000 1001  1:routineLabel, 2:routineLevel, 3:isLibraryRtn
#define IC_PRP              0x8a  // 1001 1010  1:routineLabel, 2:routineLevel, 3:isLibraryRtn

struct icode_operand
{
    unsigned char type;  // IC_MASK_LITERAL, IC_VAR, IC_LBL
    union {
        union {
            char ch;
            char boolean;
            char sint8;
            unsigned char uint8;
            short sint16;
            unsigned short uint16;
            long sint32;
            unsigned long uint32;
            CHUNKNUM realBuf;  // membuf containing the string
            CHUNKNUM strBuf;  // membuf containing the string
        } literal;
        struct {
            unsigned char type;
            char level;
            char offset;
        } var;
        char *label;
    };
};

void icodeGen(void);

void icodeWrite(CHUNKNUM astRoot);
void icodeWriteMnemonic(ICODE_MNE instruction);
void icodeWriteUnary(ICODE_MNE instruction, struct icode_operand *operand);
void icodeWriteUnaryLabel(ICODE_MNE instruction, char *operand);
void icodeWriteUnaryShort(ICODE_MNE instruction, char operand);
void icodeWriteUnaryWord(ICODE_MNE instruction, unsigned short operand);
void icodeWriteBinary(ICODE_MNE instruction, struct icode_operand *oper1,
    struct icode_operand *oper2);
void icodeWriteBinaryShort(ICODE_MNE instruction, char oper1, char oper2);
void icodeWriteTrinary(ICODE_MNE instruction, struct icode_operand *oper1,
    struct icode_operand *oper2, struct icode_operand *oper3);
void icodeWriteTrinaryShort(ICODE_MNE instruction, char oper1, char oper2, char oper3);

struct icode_operand* icodeOperChar(char num, char value);
struct icode_operand* icodeOperBool(char num, char value);
struct icode_operand* icodeOperByte(char num, unsigned char value);
struct icode_operand* icodeOperShort(char num, char value);
struct icode_operand* icodeOperWord(char num, unsigned short value);
struct icode_operand* icodeOperInt(char num, short value);
struct icode_operand* icodeOperLong(char num, long value);
struct icode_operand* icodeOperCardinal(char num, unsigned long value);
struct icode_operand* icodeOperReal(char num, CHUNKNUM realBuf);
struct icode_operand* icodeOperLabel(char num, char *label);
struct icode_operand* icodeOperStr(char num, CHUNKNUM strBuf);
struct icode_operand* icodeOperVar(char num, char oper, char type, char level, char offset);

char icodeBoolValue(CHUNKNUM chunkNum);
char icodeCharValue(CHUNKNUM chunkNum);
char icodeDWordValue(CHUNKNUM chunkNum);
char icodeExpr(CHUNKNUM chunkNum, char isRead);  // return TYPE_* of expression
void icodeRealValue(CHUNKNUM chunkNum);
void icodeRoutineDeclarations(CHUNKNUM chunkNum);
char icodeSubroutineCall(CHUNKNUM chunkNum);
void icodeStmts(CHUNKNUM chunkNum);
char icodeShortValue(CHUNKNUM chunkNum);
void icodeStringValue(CHUNKNUM stringChunkNum);
void icodeVar(char oper, char type, unsigned char level, unsigned char offset);
char icodeWordValue(CHUNKNUM chunkNum);
int icodeVariableDeclarations(CHUNKNUM chunkNum, char *localVars);

#ifdef __GNUC__
void icodeDump(void);
#endif

#endif // end of ICODE_H
