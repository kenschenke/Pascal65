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
pusheax: jmp $0000
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
    jmp rtStoreByte
@Real:
    jsr rtPushReal
    jmp rtStoreReal
.endproc

