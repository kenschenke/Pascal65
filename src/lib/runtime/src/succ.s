; Succ routine for runtime

.include "runtime.inc"
.include "types.inc"

.import popToIntOp1, popToIntOp1And2, pushFromIntOp1, pushFromIntOp1And2
.import addInt8, addInt16, addInt32
.export succ

; data type in A
.proc succ
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
    jsr addInt8
    jmp pushFromIntOp1

INT16:
    jsr popToIntOp1
    lda #1
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr addInt16
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
    jsr addInt32
    jmp pushFromIntOp1And2
.endproc
