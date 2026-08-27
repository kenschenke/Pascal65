;
; outOper.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; outOper routine

.include "asm.inc"
.include "ast.inc"
.include "icode.inc"
.include "codegen.inc"

.export outOper

.import operand1, genOneInstruction, genTwoInstruction, genThreeAddr

.proc outOper
    lda operand1+1
    cmp #TYPE_SCALAR_BYTES
    bne :+
    jsr scalarBytes
    rts

:   cmp #TYPE_HEAP_BYTES
    bne :+
    genThree OC_JSR, RT_WRITEBYTES
    rts

:   cmp #TYPE_REAL
    bne :+
    jsr outReal
    rts

:   cmp #TYPE_STRING_OBJ
    bne :+
    jsr outString
    rts
:   cmp #TYPE_STRING_VAR
    bne :+
    jsr outString
    rts

:   cmp #TYPE_ARRAY
    bne :+
    jsr outArray
    rts

:   genThree OC_JSR, RT_POPEAX                  ; precision - ignore
    genThree OC_JSR, RT_POPEAX                  ; width
    lda operand1+1
    cmp #TYPE_STRING_LITERAL
    bne :+
    genThree OC_JSR, RT_WRITESTRLITERAL
    rts
:   genOne OC_TAX
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_WRITEVALUE
    rts
.endproc

.proc outArray
    genThree OC_JSR, RT_POPEAX                  ; precision - ignore
    genThree OC_JSR, RT_POPEAX                  ; width
    genTwoImmediate OC_STA_ZEROPAGE, ZP_TMP1
    genThree OC_JSR, RT_POPEAX
    genOne OC_PHA
    genOne OC_TXA
    genOne OC_PHA
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_TMP1
    genThree OC_JSR, RT_PUSHAX
    genOne OC_PLA
    genOne OC_TAX
    genOne OC_PLA
    genThree OC_JSR, RT_WRITECHARARRAY
    rts
.endproc

.proc outReal
    genThree OC_JSR, RT_POPEAX                  ; precision
    genTwoImmediate OC_STA_ZEROPAGE, ZP_TMP1    ; store precision in tmp1
    genThree OC_JSR, RT_POPEAX                  ; width
    genOne OC_PHA                               ; store width on CPU stack
    genThree OC_JSR, RT_POPTOREAL               ; put value in FPACC
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_TMP1    ; load precision from tmp1
    genThree OC_JSR, RT_FPOUT                   ; output value to string
    genOne OC_TAX                               ; put value width in X
    genOne OC_PLA                               ; pop field width off CPU stack
    genTwoImmediate OC_BEQ, 3                   ; skip if field width is zero
    genThree OC_JSR, RT_LEFTPAD                 ; right pad value inside field width
    genTwoImmediate OC_LDA_IMMEDIATE, ZP_FPBUF  ; load pointer to string in A/X
    genTwoImmediate OC_LDX_IMMEDIATE, 0
    genThree OC_JSR, RT_PRINTZ                  ; output string of floating point
    rts
.endproc

.proc outString
    genThree OC_JSR, RT_POPEAX                  ; precision - ignore
    genThree OC_JSR, RT_POPEAX                  ; width
    genOne OC_TAX                               ; transfer width to X
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_WRITEVALUE
    rts
.endproc

.proc scalarBytes
    genThree OC_JSR, RT_POPEAX
    genOne OC_PHA
    genOne OC_TXA
    genOne OC_PHA
    genThree OC_JSR, RT_POPTOINTOP1AND2
    genTwoImmediate OC_LDA_IMMEDIATE, ZP_INTOP1L
    genTwoImmediate OC_LDX_IMMEDIATE, 0
    genThree OC_JSR, RT_PUSHEAX
    genOne OC_PLA
    genOne OC_TAX
    genOne OC_PLA
    genThree OC_JSR, RT_PUSHEAX
    genThree OC_JSR, RT_WRITEBYTES
    rts
.endproc
