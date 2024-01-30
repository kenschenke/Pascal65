; Pred routine for runtime

.include "runtime.inc"
.include "types.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp pred

; end of exports
.byte $00, $00, $00

; imports

popToIntOp1: jmp $0000
popToIntOp1And2: jmp $0000
pushFromIntOp1: jmp $0000
pushFromIntOp1And2: jmp $0000
subInt8: jmp $0000
subInt16: jmp $0000
subInt32: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; data type in A
.proc pred
    cmp #TYPE_BYTE
    beq INT8
    cmp #TYPE_SHORTINT
    beq INT8
    cmp #TYPE_CHARACTER
    beq INT8
    cmp #TYPE_WORD
    beq INT16
    cmp #TYPE_INTEGER
    beq INT16
    cmp #TYPE_ENUMERATION
    beq INT16
    cmp #TYPE_CARDINAL
    beq INT32
    cmp #TYPE_LONGINT
    beq INT32
    rts

INT8:
    jsr popToIntOp1
    lda #1
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr subInt8
    jmp pushFromIntOp1

INT16:
    jsr popToIntOp1
    lda #1
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr subInt16
    jmp pushFromIntOp1

INT32:
    jsr popToIntOp1And2
    lda #1
    sta intOp32
    lda #0
    ldx #2
:   sta intOp32+1,x
    dex
    bpl :-
    jsr subInt32
    jmp pushFromIntOp1And2
.endproc
