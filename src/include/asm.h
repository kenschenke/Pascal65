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

#define ZP_BASE         0x02

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

// Runtime Jumptable locations

#ifdef __MEGA65__
#define RT_BASE					0x2014		// 0x2001 + 19 (exe header + jmp MAIN)
#elif defined(__C64__)
#define RT_BASE					0x810		// 0x801 + 15 (exe header + jmp MAIN)
#else
#error Platform Jumptable base not defined
#endif

// DO NOT REMOVE OR REORDER THESE!!!
// These routine numbers are used in runtime.def and all hell will break loose.
enum RuntimeRoutines {
    // These are used by the code generator for the executable
    rtAbs, rtAdd, rtAssign, rtCalcArrayOffset, rtCalcRecord, rtCalcStack,
    rtClrInput, rtComp, rtDivide, rtDivInt, rtErrorInit, rtFloatNeg,
    rtFloatToInt16, rtFpOut, rtGetFpBuf, rtHeapAlloc, rtHeapFree, rtHeapInit,
    rtIncSp4, rtInitArrayHeap, rtLeftPad, rtMemCopy, rtMod, rtMultiply,
    rtNegate, rtPopEax, rtPopToIntOp1, rtPopToIntOp2, rtPopToReal, rtPrecRd,
    rtPred, rtPrintz, rtPrintlnz, rtPushAddrStack, rtPushAx, rtPushByte,
    rtPushEax, rtPushInt, rtPushIntOp1, rtPushReal, rtPushStackFrameHeader,
    rtReadByte, rtReadCharArrayFromInput, rtReadFloatFromInput, rtReadInt,
    rtReadInt32Stack, rtReadIntFromInput, rtReadReal, rtReturnFromRoutine,
    rtSqr, rtStackCleanup, rtStackInit, rtStoreInt, rtStoreInt32, rtStoreReal,
    rtStrToFloat, rtSubtract, rtSucc, rtWriteCharArray, rtWriteValue,

    // These routines are used internally by the runtime routines
    rtRuntimeError, ROTATL, ROTL, ROTR, ROTATR, ADDER, COMPLM,
    CLRMEM, MOVIND, MOVIN, CALCPTR, FPNORM, FPADD, FPMULT, EXMLDV,
    CKSIGN, FPSUB, rtFloatAbs, FPDIV, FPINP, DECBIN, FPD10, FPX10,
    floatSqr, rtFloatEq, rtFloatGt, rtFloatGte, rtFloatLt, rtFloatLte, addysp,
    decsp4, storeByteStack, popToIntOp1And2, popToIntOp32, pushIntOp1And2,
    writeBool, writeChar, absInt8, invertInt8, isNegInt8, signExtend8To16,
    signExtend8To32, swapInt8, addInt8, ltInt8, divInt8, exit, multInt8, subInt8,
    absInt16, swapInt16, isNegInt16, invertInt16, signExtend16To32, addInt16,
    eqInt16, leInt16, ltInt16, geInt16, gtInt16, divInt16, ltUint16, multUint16,
    multInt16, subInt16, rtInitTensTable32, absInt32, invertInt32, isNegInt32,
    swapInt32, addInt32, eqInt32, leInt32, ltInt32, geInt32, gtInt32, divInt32,
    multInt32, multUint32, geUint32, gtUint32, leUint32, ltUint32, writeInt8,
    writeUint8, writeInt16, writeUint16, writeInt32, writeUint32, rtPopAx,
    subInt32, int32Sqr, prepOperands8, prepOperands16, prepOperands32,
    prepOperandsReal, readInt16, copyFPACCtoFPOP, swapFPACCandFPOP,
    convertType, getline, getlineNoEnter, rtClearInputBuf, rtIsInputEndOfLine,
    rtReadCharFromInput, skipSpaces, readInt32, 
};

// CBM Kernal

#define CHROUT					0xffd2

#endif // end of ASM_H
