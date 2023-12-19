; This routine performs an assignment

.include "types.inc"
.include "runtime.inc"

.export assign

.import convertType, storeIntStack, storeInt32Stack, storeByteStack, popeax, pusheax
.import storeRealStack, pushFromIntOp1, pushFromIntOp1And2, pushRealStack
.import signExtend8To16

.bss

rightType: .res 1

.code

; A - data type of right side of assignment
; X - data type of left variable
; ptr1 - address of left variable
; value to assign on top of runtime stack
.proc assign
    pha
    txa
    pha
    jsr popeax
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

@Int8:
    jsr signExtend8To16
@Int16:
    jsr pushFromIntOp1
    jmp storeIntStack
@Int32:
    jsr pushFromIntOp1And2
    jmp storeInt32Stack
@Bool:
    jsr pushFromIntOp1
    jmp storeByteStack
@Real:
    jsr pushRealStack
    jmp storeRealStack
.endproc

