; This routine performs an assignment

.include "types.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp assign

; end of exports
.byte $00, $00, $00

; imports

convertType: jmp $0000
storeIntStack: jmp $0000
storeInt32Stack: jmp $0000
storeByteStack: jmp $0000
popeax: jmp $0000
pusheax: jmp $0000
storeRealStack: jmp $0000
pushFromIntOp1: jmp $0000
pushFromIntOp1And2: jmp $0000
pushRealStack: jmp $0000
signExtend8To16: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

rightType: .res 1

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

