;
; assign.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine performs an assignment

.include "types.inc"
.include "runtime.inc"

.export assign

.import convertType, pusheax, signExtend8To16
.import pushRealStack, storeRealStack, storeByteStack

.bss

rightType: .res 1
leftPtr: .res 2                 ; Preserve pointer to variable

.code

; A - data type of right side of assignment
; X - data type of left variable
; ptr1 - address of left variable
; value to assign on top of runtime stack
.proc assign
    pha
    txa
    pha
    jsr saveLeftPtr
    jsr rtPopEax
    sta intOp1
    stx intOp1 + 1
    lda sreg
    sta intOp2
    lda sreg + 1
    sta intOp2 + 1
    pla
    tax
    pla
    cpx #TYPE_BOOLEAN
    beq @Int8
    cpx #TYPE_ENUMERATION
    beq @Int16
    stx rightType
    jsr convertType
    ldx rightType
    cpx #TYPE_BYTE
    beq @Int8
    cpx #TYPE_CHARACTER
    beq @Int8
    cpx #TYPE_SHORTINT
    beq @Int8
    cpx #TYPE_WORD
    beq @Int16
    cpx #TYPE_INTEGER
    beq @Int16
    cpx #TYPE_CARDINAL
    beq @Int32
    cpx #TYPE_LONGINT
    beq @Int32
    cpx #TYPE_REAL
    beq @Real

@Int16:
    jsr rtPushFromIntOp1
    jmp rtStoreInt
@Int32:
    jsr rtPushFromIntOp1And2
    jmp rtStoreInt32
@Int8:
@Bool:
    jsr rtPushFromIntOp1
    jmp storeByteStack
@Real:
    jsr pushRealStack
    jsr restoreLeftPtr
    jmp storeRealStack
.endproc

.proc saveLeftPtr
    lda ptr1
    sta leftPtr
    lda ptr1 + 1
    sta leftPtr + 1
    rts
.endproc

.proc restoreLeftPtr
    lda leftPtr
    sta ptr1
    lda leftPtr + 1
    sta ptr1 + 1
    rts
.endproc
