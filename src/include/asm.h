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
#define ZP_INTPTR		(ZP_BASE + 20) // 2 bytes
#define ZP_STACKFRAMEL	(ZP_BASE + 22)
#define ZP_STACKFRAMEH	(ZP_BASE + 23)
#define ZP_SAVEDSTACK	(ZP_BASE + 24) // Saved CPU stack pointer for exit()
#define ZP_NESTINGLEVEL	(ZP_BASE + 25)
#define ZP_EXITHANDLER  (ZP_BASE + 26)

// BSS Locations

#define BSS_HEAPBOTTOM	"HEAPBOTTOM"
#define BSS_INTBUF		"INTBUF"
#define BSS_ZPBACKUP    "ZPBACKUP"

// Data Locations

#define DATA_BOOLFALSE	"BOOLFALSE"
#define DATA_BOOLTRUE	"BOOLTRUE"

// Runtime Jumptable locations

#ifdef __MEGA65__
#define RT_BASE					0x2014		// 0x2001 + 19 (exe header + jmp MAIN)
#elif defined(__C64__)
#define RT_BASE					0x810		// 0x801 + 15 (exe header + jmp MAIN)
#else
#error Platform Jumptable base not defined
#endif

#define RT_ABSINT16				(RT_BASE + 24)
#define RT_ADDINT16				(RT_BASE + 12)
#define RT_CALCRECORD			(RT_BASE + 168)
#define RT_CALCSTACK			(RT_BASE + 150)
#define RT_CLRINPUT				(RT_BASE + 186)
#define RT_COPYFPACC			(RT_BASE + 48)
#define RT_DIVINT16				(RT_BASE + 21)
#define RT_EQINT16				(RT_BASE + 33)
#define RT_ERRORINIT			(RT_BASE + 183)
#define RT_FLOATABS				(RT_BASE + 90)
#define RT_FLOATEQ				(RT_BASE + 69)
#define RT_FLOATGT				(RT_BASE + 72)
#define RT_FLOATGTE				(RT_BASE + 75)
#define RT_FLOATLT				(RT_BASE + 78)
#define RT_FLOATLTE				(RT_BASE + 81)
#define RT_FLOATTOINT16			(RT_BASE + 84)
#define RT_FPADD				(RT_BASE + 51)
#define RT_FPDIV				(RT_BASE + 60)
#define RT_STRTOFLOAT			(RT_BASE + 63)
#define RT_FPMULT				(RT_BASE + 57)
#define RT_FPOUT				(RT_BASE + 66)
#define RT_FPSUB				(RT_BASE + 54)
#define RT_GEINT16				(RT_BASE + 42)
#define RT_GTINT16				(RT_BASE + 45)
#define RT_HEAPFREE				(RT_BASE + 180)
#define RT_HEAPALLOC			(RT_BASE + 177)
#define RT_HEAPINIT				(RT_BASE + 174)
#define RT_INCSP4				(RT_BASE + 93)
#define RT_INITARRAYHEAP		(RT_BASE + 165)
#define RT_INT16SQR				(RT_BASE + 27)
#define RT_INT16TOFLOAT			(RT_BASE + 87)
#define RT_LEFTPAD				(RT_BASE + 6)
#define RT_LEINT16				(RT_BASE + 36)
#define RT_LOADREAL             (RT_BASE + 201)
#define RT_LTINT16				(RT_BASE + 39)
#define RT_MEMCOPY				(RT_BASE + 171)
#define RT_MODINT16				(RT_BASE + 30)
#define RT_MULTINT16			(RT_BASE + 18)
#define RT_POPEAX				(RT_BASE + 96)
#define RT_POPTOREAL			(RT_BASE + 105)
#define RT_POPTOINTOP1			(RT_BASE + 108)
#define RT_POPTOINTOP2			(RT_BASE + 111)
#define RT_PRECRD				(RT_BASE + 114)
#define RT_PRINTZ				(RT_BASE + 0)
#define RT_PRINTLNZ				(RT_BASE + 3)
#define RT_PUSHADDRSTACK		(RT_BASE + 117)
#define RT_PUSHAX				(RT_BASE + 99)
#define RT_PUSHBYTE				(RT_BASE + 120)
#define RT_PUSHEAX				(RT_BASE + 102)
#define RT_PUSHINT				(RT_BASE + 123)
#define RT_PUSHINTOP1			(RT_BASE + 126)
#define RT_PUSHREAL				(RT_BASE + 129)
#define RT_PUSHSTACKFRAMEHEADER	(RT_BASE + 159)
#define RT_READBYTE				(RT_BASE + 132)
#define RT_READFLOATFROMINPUT	(RT_BASE + 189)
#define RT_READINT				(RT_BASE + 135)
#define RT_READINTFROMINPUT		(RT_BASE + 192)
#define RT_READREAL				(RT_BASE + 138)
#define RT_RETURNFROMROUTINE	(RT_BASE + 162)
#define RT_STACKINIT			(RT_BASE + 153)
#define RT_STACKCLEANUP			(RT_BASE + 156)
#define RT_STOREBYTE			(RT_BASE + 141)
#define RT_STOREINT				(RT_BASE + 144)
#define RT_STOREREAL			(RT_BASE + 147)
#define RT_SUBINT16				(RT_BASE + 15)
#define RT_WRITEINT16			(RT_BASE + 9)
#define RT_CALCARRAYOFFSET		(RT_BASE + 195)
#define RT_GETFPBUF				(RT_BASE + 198)
#define RT_WRITECHARARRAY       (RT_BASE + 201)
#define RT_READCHARARRAYFROMINPUT (RT_BASE + 204)
#define RT_FLOATNEG             (RT_BASE + 207)

// CBM Kernal

#define CHROUT					0xffd2

#endif // end of ASM_H
