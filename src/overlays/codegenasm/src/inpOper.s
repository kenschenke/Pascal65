;
; inpOper.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; inpOper routine

.include "asm.inc"
.include "ast.inc"
.include "icode.inc"
.include "codegen.inc"

.export inpOper

.import operand1, genOneInstruction, genTwoInstruction, genThreeAddr

.proc inpOper
    lda operand1+1
    cmp #TYPE_SCALAR_BYTES
    bne :+
    genThree OC_JSR, RT_READBYTES
    rts
:   cmp #TYPE_HEAP_BYTES
    bne :+
    genThree OC_JSR, RT_READBYTES
    rts

:   cmp #TYPE_CHARACTER
    bne :+
    jsr readByte
    rts
:   cmp #TYPE_BYTE
    bne :+
    jsr readByte
    rts
:   cmp #TYPE_SHORTINT
    bne :+
    jsr readByte
    rts

:   cmp #TYPE_INTEGER
    bne :+
    jsr readWord
    rts
:   cmp #TYPE_WORD
    bne :+
    jsr readWord
    rts

:   cmp #TYPE_CARDINAL
    bne :+
    jsr readDword
    rts
:   cmp #TYPE_LONGINT
    bne :+
    jsr readDword
    rts

:   cmp #TYPE_REAL
    bne :+
    jsr readReal
    rts

:   cmp #TYPE_ARRAY
    bne :+
    jsr readArray
    rts

:   cmp #TYPE_STRING_VAR
    bne :+
    jsr readString

:   rts
.endproc

.proc readArray
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genTwoImmediate OC_LDY_IMMEDIATE, 1
    genTwoImmediate OC_LDA_ZPINDIRECT, ZP_PTR1L
    genOne OC_TAX
    genOne OC_DEY
    genTwoImmediate OC_LDA_ZPINDIRECT, ZP_PTR1L
    genThree OC_JSR, RT_READCHARARRAYFROMINPUT
    rts
.endproc

.proc readByte
    cmp #TYPE_CHARACTER
    bne :+
    genThree OC_JSR, RT_READCHARFROMINPUT
    bra L1
:   genThree OC_JSR, RT_READINTFROMINPUT

L1: genOne OC_PHA
    genOne OC_TXA
    genOne OC_PHA
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genOne OC_PLA
    genOne OC_TAX
    genOne OC_PLA
    genThree OC_JSR, RT_PUSHBYTESTACK
    genThree OC_JSR, RT_STOREINTSTACK
    rts
.endproc

.proc readDword
    genThree OC_JSR, RT_READINTFROMINPUT
    genTwoImmediate OC_STA_ZEROPAGE, ZP_INTOP1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_INTOP1H
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_SREGL
    genTwoImmediate OC_STA_ZEROPAGE, ZP_INTOP2L
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_SREGH
    genTwoImmediate OC_STA_ZEROPAGE, ZP_INTOP2H
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genThree OC_JSR, RT_PUSHFROMINTOP1AND2
    genThree OC_JSR, RT_STOREINT32STACK
    rts
.endproc

.proc readReal
    genThree OC_JSR, RT_READFLOATFROMINPUT
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genThree OC_JSR, RT_PUSHREALSTACK
    genThree OC_JSR, RT_STOREREALSTACK
    rts
.endproc

.proc readString
    genThree OC_JSR, RT_POPEAX
    genThree OC_JSR, RT_READSTRINGFROMINPUT
    rts
.endproc

.proc readWord
    genThree OC_JSR, RT_READINTFROMINPUT
    genTwoImmediate OC_STA_ZEROPAGE, ZP_INTOP1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_INTOP1H
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genThree OC_JSR, RT_PUSHFROMINTOP1
    genThree OC_JSR, RT_STOREINTSTACK
    rts
.endproc
