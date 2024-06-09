/**
 * asm.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for assembly
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef ASM_H
#define ASM_H

// Assembly Instructions

// Addressing Modes
//    Name                          Example  Define
//    ----------------------------  -------  --------------
//    Immediate #$nn                $nnnn    IMMEDIATE
//    Absolute                      $nn      ABSOLUTE
//    X-Indexed Absolute            $nnnn,X  X_INDEXED_ABS
//    Y-Indexed Absolute            $nnnn,Y  Y_INDEXED_ABS
//    Zero Page                     $nn      ZEROPAGE
//    X-Indexed Zero Page           $nn,X    X_INDEXED_ZP
//    Zero Page Indirect Y-Indexed  ($nn),Y  ZPINDIRECT

#define AND_IMMEDIATE	0x29	// and #$nn			2 bytes
#define AND_ABSOLUTE	0x2d	// and $nnnn		3 bytes
#define AND_ZEROPAGE	0x25	// and $nn			2 bytes
#define EOR_IMMEDIATE	0x49	// eor #$nn			2 bytes
#define ORA_IMMEDIATE	0x09	// ora #$nn			2 bytes
#define ORA_ABSOLUTE	0x0d	// ora $nnnn		3 bytes
#define ORA_ZEROPAGE	0x05	// ora $nn			2 bytes

#define BEQ             0xf0	// beq $nn			2 bytes
#define BNE				0xd0	// bne $nn			2 bytes
#define BPL				0x10	// bpl $nn			2 bytes

#define CLC				0x18
#define SEC				0x38

#define ADC_IMMEDIATE	0x69	// adc #$nn			2 bytes
#define ADC_ZEROPAGE	0x65	// adc $nn			2 bytes
#define CMP_IMMEDIATE	0xc9	// cmp #$nn			2 bytes
#define CMP_ABSOLUTE	0xcd	// cmp $nnnn		3 bytes
#define CPX_IMMEDIATE   0xe0    // cpx #$00         2 bytes
#define SBC_IMMEDIATE	0xe9	// sbc #$nn			2 bytes

#define DEC_ABSOLUTE	0xce	// dec $nnnn		3 bytes
#define DEC_ZEROPAGE	0xc6	// dec $nn			2 bytes
#define DEX				0xca
#define DEY				0x88
#define INC_ZEROPAGE	0xe6	// inc $nn			2 bytes
#define INX				0xe8
#define INY				0xc8

#define JMP             0x4c	// jmp $nnnn		3 bytes
#define JSR             0x20	// jsr $nnnn		3 bytes
#define RTS				0x60
#define NOP				0xea

#define LDA_IMMEDIATE	0xa9	// lda #$nn			2 bytes
#define LDA_ABSOLUTE	0xad	// lda $nnnn		3 bytes
#define LDA_ABSOLUTEX   0xbd    // lda $nnnn,x      3 bytes
#define LDA_ZEROPAGE	0xa5	// lda $nn			2 bytes
#define LDA_X_INDEXED_ZP 0xb5   // lda $nn,x        2 bytes
#define LDA_ZPINDIRECT	0xb1	// lda ($nn),y		2 bytes
#define LDX_IMMEDIATE	0xa2	// ldx #$nn			2 bytes
#define LDX_ABSOLUTE    0xae    // ldx $nnnn        3 bytes
#define LDX_ZEROPAGE	0xa6	// ldx $nn			2 bytes
#define LDY_IMMEDIATE	0xa0	// ldy #$nn			2 bytes
#define STA_ABSOLUTE	0x8d	// sta $nnnn		3 bytes
#define STA_ABSOLUTEX   0x9d    // sta $nnnn,x      3 bytes
#define STA_ZEROPAGE	0x85	// sta $nn			2 bytes
#define STA_ZPINDIRECT	0x91	// sta ($nn),y		2 bytes
#define STA_X_INDEXED_ZP 0x95	// sta $nn,x		2 bytes
#define STX_ABSOLUTE	0x8e	// stx $nnnn		3 bytes
#define STX_ZEROPAGE	0x86	// stx $nn			2 bytes

#define PLA             0x68
#define PHA             0x48

#define TAX             0xaa
#define TAY             0xa8
#define TSX             0xba
#define TXA             0x8a
#define TXS             0x9a
#define TYA             0x98

// Zero page addresses

#define ZP_BASE         0x04

#define ZP_SPL			(ZP_BASE + 0)
#define ZP_SPH			(ZP_BASE + 1)
#define ZP_SREGL		(ZP_BASE + 2)
#define ZP_SREGH		(ZP_BASE + 3)
#define ZP_PTR1L		(ZP_BASE + 4)
#define ZP_PTR1H		(ZP_BASE + 5)
#define ZP_PTR2L		(ZP_BASE + 6)
#define ZP_PTR2H		(ZP_BASE + 7)
#define ZP_PTR3L		(ZP_BASE + 8)
#define ZP_PTR3H		(ZP_BASE + 9)
#define ZP_PTR4L		(ZP_BASE + 10)
#define ZP_PTR4H		(ZP_BASE + 11)
#define ZP_TMP1			(ZP_BASE + 12)
#define ZP_TMP2			(ZP_BASE + 13)
#define ZP_TMP3			(ZP_BASE + 14)
#define ZP_TMP4			(ZP_BASE + 15)
#define ZP_INTOP1L		(ZP_BASE + 16)
#define ZP_INTOP1H		(ZP_BASE + 17)
#define ZP_INTOP2L		(ZP_BASE + 18)
#define ZP_INTOP2H		(ZP_BASE + 19)
#define ZP_INTOP32      (ZP_BASE + 20) // 4 bytes
#define ZP_INTPTR		(ZP_BASE + 24) // 2 bytes
#define ZP_STACKFRAMEL	(ZP_BASE + 26)
#define ZP_STACKFRAMEH	(ZP_BASE + 27)
#define ZP_SAVEDSTACK	(ZP_BASE + 28) // Saved CPU stack pointer for exit()
#define ZP_NESTINGLEVEL	(ZP_BASE + 30)
#define ZP_EXITHANDLER  (ZP_BASE + 31)
#define ZP_FPBASE       (ZP_BASE + 33)
#define ZP_FPBUF        (ZP_BASE + 77)
#define ZP_TENSTABLE32  (ZP_BASE + 92)
#define ZP_INPUTBUFPTRL (ZP_BASE + 94)
#define ZP_INPUTBUFPTRH (ZP_BASE + 95)

// BSS Locations

#define BSS_HEAPBOTTOM	"HEAPBOTTOM"
#define BSS_INTBUF		"INTBUF"
#define BSS_ZPBACKUP    "ZPBACKUP"
#define BSS_TENSTABLE   "TENSTABLE"
#define BSS_INPUTBUF    "INPUTBUF"

// Magic File Handles
// Used by read/write routines that are called by read/readln/write/writeln
#define FH_STDIO        0x80    // Use screen/keyboard for IO
#define FH_STRING       0x81    // Use string for IO

// Runtime Jumptable locations

#ifdef __MEGA65__
#define RT_BASE					0x2028		// 0x2001 + 19 (exe header + jmp MAIN)
#elif defined(__C64__)
#define RT_BASE					0x810		// 0x801 + 15 (exe header + jmp MAIN)
#else
#error Platform Jumptable base not defined
#endif

#define RT_STACKCLEANUP         (RT_BASE + 0)
#define RT_STACKINIT            (RT_BASE + 3)
#define RT_PUSHINTSTACK         (RT_BASE + 6)
#define RT_CALCSTACKOFFSET      (RT_BASE + 9)
#define RT_STOREINTSTACK        (RT_BASE + 12)
#define RT_PUSHADDRSTACK        (RT_BASE + 15)
#define RT_READINTSTACK         (RT_BASE + 18)
#define RT_POPTOINTOP1          (RT_BASE + 21)
#define RT_POPTOINTOP2          (RT_BASE + 24)
#define RT_PUSHFROMINTOP1       (RT_BASE + 27)
#define RT_PUSHREALSTACK        (RT_BASE + 30)
#define RT_STOREREALSTACK       (RT_BASE + 33)
#define RT_POPTOREAL            (RT_BASE + 36)
#define RT_READREALSTACK        (RT_BASE + 39)
#define RT_READBYTESTACK        (RT_BASE + 42)
#define RT_PUSHBYTESTACK        (RT_BASE + 45)
#define RT_STOREBYTESTACK       (RT_BASE + 48)
#define RT_PUSHSTACKFRAMEHEADER (RT_BASE + 51)
#define RT_RETURNFROMROUTINE    (RT_BASE + 54)
#define RT_POPTOINTOP1AND2      (RT_BASE + 57)
#define RT_POPTOINTOP32         (RT_BASE + 60)
#define RT_READINT32STACK       (RT_BASE + 63)
#define RT_STOREINT32STACK      (RT_BASE + 66)
#define RT_PUSHFROMINTOP1AND2   (RT_BASE + 69)
#define RT_RUNTIMEERROR         (RT_BASE + 72)
#define RT_RUNTIMEERRORINIT     (RT_BASE + 75)
#define RT_POPA                 (RT_BASE + 78)
#define RT_POPAX                (RT_BASE + 81)
#define RT_HEAPINIT             (RT_BASE + 84)
#define RT_HEAPALLOC            (RT_BASE + 87)
#define RT_HEAPFREE             (RT_BASE + 90)
#define RT_INITTENSTABLE32      (RT_BASE + 93)
#define RT_CLEARINPUTBUF        (RT_BASE + 96)
#define RT_POPEAX               (RT_BASE + 99)
#define RT_INCSP4               (RT_BASE + 102)
#define RT_WRITEVALUE           (RT_BASE + 105)
#define RT_LEFTPAD              (RT_BASE + 108)
#define RT_PRINTZ               (RT_BASE + 111)
#define RT_STRCASE              (RT_BASE + 114)
#define RT_TRIM                 (RT_BASE + 117)
#define RT_INITFILEIO           (RT_BASE + 120)
#define RT_SETFH                (RT_BASE + 123)
#define RT_RESETSTRBUFFER       (RT_BASE + 126)
#define RT_GETSTRBUFFER         (RT_BASE + 129)
#define RT_WRITESTRLITERAL      (RT_BASE + 132)
#define RT_CLEARKEYBUF          (RT_BASE + 135)
#define RT_GETKEY               (RT_BASE + 138)
#define RT_STRCOMPARE           (RT_BASE + 141)
#define RT_PUSHAX               (RT_BASE + 144)
#define RT_ABS                  (RT_BASE + 147)
#define RT_ADD                  (RT_BASE + 150)
#define RT_ASSIGN               (RT_BASE + 153)
#define RT_MULTIPLY             (RT_BASE + 156)
#define RT_DIVIDE               (RT_BASE + 159)
#define RT_DIVINT               (RT_BASE + 162)
#define RT_COMP                 (RT_BASE + 165)
#define RT_SUBTRACT             (RT_BASE + 168)
#define RT_MOD                  (RT_BASE + 171)
#define RT_SQR                  (RT_BASE + 174)
#define RT_FLOATNEG             (RT_BASE + 177)
#define RT_NEGATE               (RT_BASE + 180)
#define RT_PRED                 (RT_BASE + 183)
#define RT_SUCC                 (RT_BASE + 186)
#define RT_PRECRD               (RT_BASE + 189)
#define RT_CALCARRAYOFFSET      (RT_BASE + 192)
#define RT_CALCRECORD           (RT_BASE + 195)
#define RT_PUSHEAX              (RT_BASE + 198)
#define RT_INITARRAYS           (RT_BASE + 201)
#define RT_WRITECHARARRAY       (RT_BASE + 204)
#define RT_READCHARARRAYFROMINPUT (RT_BASE + 207)
#define RT_FLOATTOINT16         (RT_BASE + 210)
#define RT_FPOUT                (RT_BASE + 213)
#define RT_MEMCOPY              (RT_BASE + 216)
#define RT_READFLOATFROMINPUT   (RT_BASE + 219)
#define RT_READINTFROMINPUT     (RT_BASE + 222)
#define RT_STRTOFLOAT           (RT_BASE + 225)
#define RT_CONCATSTRING         (RT_BASE + 228)
#define RT_ASSIGNSTRING         (RT_BASE + 231)
#define RT_CONVERTSTRING        (RT_BASE + 234)
#define RT_READSTRINGFROMINPUT  (RT_BASE + 237)
#define RT_STRINGSUBSCRIPTREAD  (RT_BASE + 240)
#define RT_STRINGSUBSCRIPTCALC  (RT_BASE + 243)
#define RT_LIBLOADPARAM         (RT_BASE + 246)
#define RT_LIBRETURNVALUE       (RT_BASE + 249)
#define RT_LIBSTOREVARPARAM     (RT_BASE + 252)
#define RT_STRPOS               (RT_BASE + 255)
#define RT_BEGINSWITH           (RT_BASE + 258)
#define RT_ENDSWITH             (RT_BASE + 261)
#define RT_CONTAINS             (RT_BASE + 264)
#define RT_READCHARFROMINPUT    (RT_BASE + 267)
#define RT_BITWISEAND           (RT_BASE + 270)
#define RT_BITWISEOR            (RT_BASE + 273)
#define RT_BITWISELSHIFT        (RT_BASE + 276)
#define RT_BITWISERSHIFT        (RT_BASE + 279)
#define RT_BITWISEINVERT        (RT_BASE + 282)
#define RT_SINE                 (RT_BASE + 285)
#define RT_COSINE               (RT_BASE + 288)

// DO NOT REMOVE OR REORDER THESE!!!
// These routine numbers are used in runtime.def and all hell will break loose.
enum RuntimeRoutines {
    // These are used by the code generator for the executable
    rtDummy0, rtDummy1, rtDummy2, rtDummy3, rtDummy4, rtDummy5,
    rtDummy6, rtDummy7, rtDummy8, rtDummy9, rtDummy10, rtDummy11,
    rtDummy12, rtDummy13, rtDummy14, rtDummy15, rtDummy16, rtDummy17,
    rtDummy18, rtDummy19, rtDummy20, rtDummy21, rtDummy22, rtDummy23,
    rtDummy24, rtDummy25, rtDummy26, rtDummy27, rtDummy28, rtDummy29,
    rtDummy30, rtDummy31, rtDummy32, rtDummy33, rtDummy34, rtDummy35,
    rtDummy36, rtDummy37, rtDummy38, rtDummy39, rtDummy40,
    rtDummy41, rtDummy42, rtDummy43, rtDummy44,
    rtDummy45, rtDummy46, rtDummy47, rtDummy48,
    rtDummy49, rtDummy50, rtDummy51, rtDummy52, rtDummy53, rtDummy54,
    rtDummy55, rtDummy56, rtDummy57, rtDummy58, rtDummy59,

    // These routines are used internally by the runtime routines
    rtDummy60, ROTATL, ROTL, ROTR, ROTATR, ADDER, COMPLM,
    CLRMEM, MOVIND, MOVIN, CALCPTR, FPNORM, FPADD, FPMULT, EXMLDV,
    CKSIGN, FPSUB, rtFloatAbs, FPDIV, FPINP, DECBIN, FPD10, FPX10,
    floatSqr, rtFloatEq, rtFloatGt, rtFloatGte, rtFloatLt, rtFloatLte, rtDummy89,
    decsp4, rtDummy91, rtDummy92, rtDummy93, rtDummy94,
    writeBool, writeChar, absInt8, invertInt8, isNegInt8, signExtend8To16,
    signExtend8To32, swapInt8, addInt8, ltInt8, divInt8, rtExit, multInt8, subInt8,
    absInt16, swapInt16, isNegInt16, invertInt16, signExtend16To32, addInt16,
    eqInt16, leInt16, ltInt16, geInt16, gtInt16, divInt16, ltUint16, multUint16,
    multInt16, subInt16, rtDummy125, absInt32, invertInt32, isNegInt32,
    swapInt32, addInt32, eqInt32, leInt32, ltInt32, geInt32, gtInt32, divInt32,
    multInt32, multUint32, geUint32, gtUint32, leUint32, ltUint32, writeInt8,
    writeUint8, writeInt16, writeUint16, writeInt32, writeUint32, rtPopAx,
    subInt32, int32Sqr, prepOperands8, prepOperands16, prepOperands32,
    prepOperandsReal, readInt16, copyFPACCtoFPOP, swapFPACCandFPOP,
    convertType, getline, getlineNoEnter, rtDummy162, rtIsInputEndOfLine,
    rtReadCharFromInput, skipSpaces, readInt32, rtDummy167, writeString,
    rtHeapReAlloc, rtPopA, rtDummy171, rtPushA, rtDummy173,
    rtStringSubscriptRead, rtDuplicateString, rtStringSubscriptWrite,
    rtConvertString,  
};

// CBM Kernal

#define CHROUT					0xffd2

#endif // end of ASM_H
