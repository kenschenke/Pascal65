; Assembly instructions

; Addressing Modes
; Name                          Example  Define
; ----------------------------  -------  --------------
; Immediate #$nn                $nnnn    IMMEDIATE
; Absolute                      $nn      ABSOLUTE
; X-Indexed Absolute            $nnnn,x  X_INDEXED_ABS
; Y-Indexed Absolute            $nnnn,y  Y_INDEXED_ABS
; Zero Page                     $nn      ZEROPAGE
; X-Indexed Zero Page           $nn,x    X_INDEXED_ZP
; Zero Page Indirect Y-Indexed  ($nn,y)  ZPINDIRECT

OC_AND_IMMEDIATE    = $29  ; and #$nn    2 bytes
OC_AND_ABSOLUTE     = $2d  ; and #nnnn   3 bytes
OC_AND_ZEROPAGE     = $25  ; and $nn     2 bytes
OC_EOR_IMMEDIATE    = $49  ; eor #$nn    2 bytes
OC_ORA_IMMEDIATE    = $09  ; ora #$99    2 bytes
OC_ORA_ABSOLUTE     = $0d  ; ora $nnnn   3 bytes
OC_ORA_ZEROPAGE     = $05  ; ora $nn     2 bytes

OC_BEQ              = $f0  ; beq $nn     2 bytes
OC_BNE              = $d0  ; bne $nn     2 bytes
OC_BPL              = $10  ; bpl $nn     2 bytes

OC_CLC              = $18
OC_SEC              = $38

OC_ADC_IMMEDIATE    = $69  ; adc #$nn    2 bytes
OC_ADC_ZEROPAGE     = $65  ; adc $nn     2 bytes
OC_CMP_IMMEDIATE    = $c9  ; cmp #$nn    2 bytes
OC_CMP_ABSOLUTE     = $cd  ; cmp $nnnn   3 bytes
OC_CPX_IMMEDIATE    = $e0  ; cpx #$nn    2 bytes
OC_SBC_IMMEDIATE    = $e9  ; sbc #$nn    2 bytes

OC_DEC_ABSOLUTE     = $ce  ; dec $nnnn   3 bytes
OC_DEC_ZEROPAGE     = $c6  ; dec $nn     2 bytes
OC_DEX              = $ca
OC_DEY              = $88
OC_INC_ZEROPAGE     = $e6  ; inc $nn     2 bytes
OC_INX              = $e8
OC_INY              = $c8

OC_JMP              = $4c  ; jmp $nnnn   3 bytes
OC_JMP_INDIRECT     = $6c  ; jmp ($nnnn) 3 bytes
OC_JSR              = $20  ; jsr $nnnn   3 bytes
OC_RTS              = $60
OC_NOP              = $ea

OC_LDA_IMMEDIATE    = $a9  ; lda #$nn    2 bytes
OC_LDA_ABSOLUTE     = $ad  ; lda $nnnn   3 bytes
OC_LDA_ABSOLUTEX    = $bd  ; lda $nnnn,x 3 bytes
OC_LDA_ZEROPAGE     = $a5  ; lda $nn     2 bytes
OC_LDA_X_INDEXED_ZP = $b5  ; lda $nn,x   2 bytes
OC_LDA_ZPINDIRECT   = $b1  ; lda ($nn,y) 2 bytes
OC_LDX_IMMEDIATE    = $a2  ; ldx #$nn    2 bytes
OC_LDX_ABSOLUTE     = $ae  ; ldx $nnnn   3 bytes
OC_LDX_ZEROPAGE     = $a6  ; ldx $nn     2 bytes
OC_LDY_IMMEDIATE    = $a0  ; ldy #$nn    2 bytes
OC_LDY_ZEROPAGE     = $a4  ; ldy $nn     2 bytes
OC_STA_ABSOLUTE     = $8d  ; sta $nnnn   3 bytes
OC_STA_ABSOLUTEX    = $9d  ; sta $nnnn,x 3 bytes
OC_STA_ZEROPAGE     = $85  ; sta $nn     2 bytes
OC_STA_ZPINDIRECT   = $91  ; sta ($nn,y) 2 bytes
OC_STA_X_INDEXED_ZP = $95  ; sta $nn,x   2 bytes
OC_STX_ABSOLUTE     = $8e  ; stx $nnnn   3 bytes
OC_STX_ZEROPAGE     = $86  ; stx $nn     2 bytes

OC_PLA              = $68
OC_PHA              = $48

OC_TAX              = $aa
OC_TAY              = $a8
OC_TSX              = $ba
OC_TXA              = $8a
OC_TXS              = $9a
OC_TYA              = $98

; Zero page addresses

ZP_BASE             = $04

ZP_SPL              = ZP_BASE + 0
ZP_SPH              = ZP_BASE + 1
ZP_SREGL            = ZP_BASE + 2
ZP_SREGH            = ZP_BASE + 3
ZP_PTR1L            = ZP_BASE + 4
ZP_PTR1H            = ZP_BASE + 5
ZP_PTR2L            = ZP_BASE + 6
ZP_PTR2H            = ZP_BASE + 7
ZP_PTR3L            = ZP_BASE + 8
ZP_PTR3H            = ZP_BASE + 9
ZP_PTR4L            = ZP_BASE + 10
ZP_PTR4H            = ZP_BASE + 11
ZP_TMP1             = ZP_BASE + 12
ZP_TMP2             = ZP_BASE + 13
ZP_TMP3             = ZP_BASE + 14
ZP_TMP4             = ZP_BASE + 15
ZP_INTOP1L          = ZP_BASE + 16
ZP_INTOP1H          = ZP_BASE + 17
ZP_INTOP2L          = ZP_BASE + 18
ZP_INTOP2H          = ZP_BASE + 19
ZP_INTOP32          = ZP_BASE + 20  ; 4 bytes
ZP_INTPTR           = ZP_BASE + 24  ; 2 bytes
ZP_STACKFRAMEL      = ZP_BASE + 26
ZP_STACKFRAMEH      = ZP_BASE + 27
ZP_SAVEDSTACK       = ZP_BASE + 28  ; Saved CPU stack pointer for exit()
ZP_NESTINGLEVEL     = ZP_BASE + 30
ZP_EXITHANDLER      = ZP_BASE + 31
ZP_FPBASE           = ZP_BASE + 33
ZP_FPBUF            = ZP_BASE + 77
ZP_TENSTABLE32      = ZP_BASE + 92
ZP_INPUTBUFPTRL     = ZP_BASE + 94
ZP_INPUTBUFPTRH     = ZP_BASE + 95

; Runtime jumptable locations

RT_BASE = $2028

RT_STACKCLEANUP         = RT_BASE + 0
RT_STACKINIT            = RT_BASE + 3
RT_PUSHINTSTACK         = RT_BASE + 6
RT_CALCSTACKOFFSET      = RT_BASE + 9
RT_STOREINTSTACK        = RT_BASE + 12
RT_PUSHADDRSTACK        = RT_BASE + 15
RT_FILEOPEN             = RT_BASE + 18
RT_POPTOINTOP1          = RT_BASE + 21
RT_POPTOINTOP2          = RT_BASE + 24
RT_PUSHFROMINTOP1       = RT_BASE + 27
RT_PUSHREALSTACK        = RT_BASE + 30
RT_STOREREALSTACK       = RT_BASE + 33
RT_POPTOREAL            = RT_BASE + 36
RT_FILECLOSE            = RT_BASE + 39
RT_EOF                  = RT_BASE + 42
RT_PUSHBYTESTACK        = RT_BASE + 45
RT_SETIORESULT          = RT_BASE + 48
RT_PUSHSTACKFRAMEHEADER = RT_BASE + 51
RT_RETURNFROMROUTINE    = RT_BASE + 54
RT_POPTOINTOP1AND2      = RT_BASE + 57
RT_GETIORESULT          = RT_BASE + 60
RT_FILEERASE            = RT_BASE + 63
RT_STOREINT32STACK      = RT_BASE + 66
RT_PUSHFROMINTOP1AND2   = RT_BASE + 69
RT_FILEASSIGN           = RT_BASE + 72
RT_RUNTIMEERRORINIT     = RT_BASE + 75
RT_FILERENAME           = RT_BASE + 78
RT_FILEFREE             = RT_BASE + 81
RT_HEAPINIT             = RT_BASE + 84
RT_HEAPALLOC            = RT_BASE + 87
RT_HEAPFREE             = RT_BASE + 90
RT_INITTENSTABLE32      = RT_BASE + 93
RT_CLEARINPUTBUF        = RT_BASE + 96
RT_POPEAX               = RT_BASE + 99
RT_INCSP4               = RT_BASE + 102
RT_WRITEVALUE           = RT_BASE + 105
RT_LEFTPAD              = RT_BASE + 108
RT_PRINTZ               = RT_BASE + 111
RT_STRCASE              = RT_BASE + 114
RT_TRIM                 = RT_BASE + 117
RT_INITFILEIO           = RT_BASE + 120
RT_SETFH                = RT_BASE + 123
RT_RESETSTRBUFFER       = RT_BASE + 126
RT_GETSTRBUFFER         = RT_BASE + 129
RT_WRITESTRLITERAL      = RT_BASE + 132
RT_CLEARKEYBUF          = RT_BASE + 135
RT_GETKEY               = RT_BASE + 138
RT_STRCOMPARE           = RT_BASE + 141
RT_PUSHAX               = RT_BASE + 144
RT_ABS                  = RT_BASE + 147
RT_ADD                  = RT_BASE + 150
RT_ASSIGN               = RT_BASE + 153
RT_MULTIPLY             = RT_BASE + 156
RT_DIVIDE               = RT_BASE + 159
RT_DIVINT               = RT_BASE + 162
RT_COMP                 = RT_BASE + 165
RT_SUBTRACT             = RT_BASE + 168
RT_MOD                  = RT_BASE + 171
RT_SQR                  = RT_BASE + 174
RT_FLOATNEG             = RT_BASE + 177
RT_NEGATE               = RT_BASE + 180
RT_PRED                 = RT_BASE + 183
RT_SUCC                 = RT_BASE + 186
RT_PRECRD               = RT_BASE + 189
RT_CALCARRAYELEM        = RT_BASE + 192
RT_CALCRECORD           = RT_BASE + 195
RT_PUSHEAX              = RT_BASE + 198
RT_CLONEDECL            = RT_BASE + 201
RT_WRITECHARARRAY       = RT_BASE + 204
RT_READCHARARRAYFROMINPUT = RT_BASE + 207
RT_FLOATTOINT16         = RT_BASE + 210
RT_FPOUT                = RT_BASE + 213
RT_MEMCOPY              = RT_BASE + 216
RT_READFLOATFROMINPUT   = RT_BASE + 219
RT_READINTFROMINPUT     = RT_BASE + 222
RT_STRTOFLOAT           = RT_BASE + 225
RT_CONCATSTRING         = RT_BASE + 228
RT_ASSIGNSTRING         = RT_BASE + 231
RT_CONVERTSTRING        = RT_BASE + 234
RT_READSTRINGFROMINPUT  = RT_BASE + 237
RT_STRINGSUBSCRIPTREAD  = RT_BASE + 240
RT_STRINGSUBSCRIPTCALC  = RT_BASE + 243
RT_LIBLOADPARAM         = RT_BASE + 246
RT_LIBRETURNVALUE       = RT_BASE + 249
RT_LIBSTOREVARPARAM     = RT_BASE + 252
RT_STRPOS               = RT_BASE + 255
RT_BEGINSWITH           = RT_BASE + 258
RT_ENDSWITH             = RT_BASE + 261
RT_CONTAINS             = RT_BASE + 264
RT_READCHARFROMINPUT    = RT_BASE + 267
RT_BITWISEAND           = RT_BASE + 270
RT_BITWISEOR            = RT_BASE + 273
RT_BITWISELSHIFT        = RT_BASE + 276
RT_BITWISERSHIFT        = RT_BASE + 279
RT_BITWISEINVERT        = RT_BASE + 282
RT_SINE                 = RT_BASE + 285
RT_COSINE               = RT_BASE + 288
RT_TANGENT              = RT_BASE + 291
RT_INITDECL             = RT_BASE + 294
RT_FREEDECL             = RT_BASE + 297
RT_STRINGINIT           = RT_BASE + 300
RT_PUSHVAR              = RT_BASE + 303
RT_READVAR              = RT_BASE + 306
RT_WRITEBYTES           = RT_BASE + 309
RT_READBYTES            = RT_BASE + 312
RT_CONVERTINT           = RT_BASE + 315
RT_LIBSTACKFRAME        = RT_BASE + 318
RT_LIBCALLROUTINE       = RT_BASE + 321
RT_ADDIRQHANDLER        = RT_BASE + 324
RT_IRQCLEANUP           = RT_BASE + 327
RT_LIBSTACKCLEANUP      = RT_BASE + 330
RT_BITWISEXOR           = RT_BASE + 333
