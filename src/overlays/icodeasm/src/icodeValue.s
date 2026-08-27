;
; icodeValue.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export icodeBoolValue, icodeCharValue, icodeShortValue, icodeWordValue
.export icodeLongValue, icodeRealValue, icodeStringValue

.export heapOffset

.import icodeOper1Bool, icodeWriteInstruction, icodeOper1Char, icodeOper1Short
.import icodeOper1Word, icodeOper1Long, icodeOper1Real, getExprTypeKind
.import icodeOper1String

.bss

heapOffset: .res 2

.code

.proc icodeBoolValue
    jsr isQZero
    bne L1
    jsr icodeOper1Bool
    lda #TYPE_BOOLEAN
    pha
    bra L2

L1: stq ptr1
    jsr pushQ
    ldz #expr::value
    nop
    lda (ptr1),z
    jsr icodeOper1Bool
    jsr popQ
    jsr getExprTypeKind
    pha

L2: lda #IC_PSH
    jsr icodeWriteInstruction
    pla
    rts
.endproc

.proc icodeCharValue
    jsr isQZero
    bne L1
    jsr icodeOper1Char
    lda #TYPE_CHARACTER
    pha
    bra L2

L1: stq ptr1
    jsr pushQ
    ldz #expr::value
    nop
    lda (ptr1),z
    jsr icodeOper1Char
    jsr popQ
    jsr getExprTypeKind
    pha

L2: lda #IC_PSH
    jsr icodeWriteInstruction
    pla
    rts
.endproc

.proc icodeLongValue
    jsr isQZero
    bne L1
    jsr icodeOper1Long
    bra L2

L1: stq ptr1
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr1),z
    stq intOp1
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq :+
    ; Negate the number
    jsr invertInt32
:   ldq intOp1
    jsr icodeOper1Long

L2: lda #IC_PSH
    jsr icodeWriteInstruction
    rts
.endproc

.proc icodeRealValue
    stq ptr1
    jsr isQZero
    beq :+
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr1),z
:   jsr icodeOper1Real
    lda #IC_PSH
    jsr icodeWriteInstruction
    rts
.endproc

.proc icodeShortValue
    jsr isQZero
    bne L1
    jsr icodeOper1Short
    lda #TYPE_BYTE
    bra L2

L1: stq ptr1
    jsr pushQ
    ldz #expr::value
    nop
    lda (ptr1),z
    sta intOp1
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq :+
    ; Negate the number
    lda intOp1
    eor #$ff
    clc
    adc #1
    jsr icodeOper1Short
    jsr popQ
    lda #TYPE_SHORTINT
    bra L2
:   lda intOp1
    jsr icodeOper1Short
    jsr popQ
    jsr getExprTypeKind

L2: pha
    lda #IC_PSH
    jsr icodeWriteInstruction
    pla
    rts
.endproc

.proc icodeStringValue
    jsr icodeOper1String
    lda #IC_PSH
    jsr icodeWriteInstruction
    rts
.endproc

.proc icodeWordValue
    jsr isQZero
    bne L1
    jsr icodeOper1Word
    lda #TYPE_WORD
    sta tmp1
    bra L2

L1: stq ptr1
    ldz #expr::value
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    sta intOp1+1
    lda #TYPE_WORD
    sta tmp1
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq :+
    ; Negate the number
    jsr invertInt16
    lda #TYPE_INTEGER
    sta tmp1
:   lda intOp1
    ldx intOp1+1
    jsr icodeOper1Word

L2: lda tmp1
    pha
    lda #IC_PSH
    jsr icodeWriteInstruction
    pla
    ; lda tmp1
    rts
.endproc
