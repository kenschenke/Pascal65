; Placeholder for 8-bit integer operations

.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp absInt8
jmp invertInt8
jmp isNegInt8
jmp signExtend8To16
jmp signExtend8To32
jmp swapInt8

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Absolute value of intOp1
.proc absInt8
    jsr isNegInt8
    bne invertInt8
    rts
.endproc

; Z flag is non-zero if number is negative
.proc isNegInt8
    lda intOp1
    and #$80
    rts
.endproc

; Invert intOp1 by applying the two's complement.
.proc invertInt8
    ; invert the bits
    lda intOp1
    eor #$ff
    clc
    adc #1
    sta intOp1
    rts
.endproc

.proc signExtend8To16
    ldx #0
    lda intOp1
    and #$80
    beq :+
    ldx #$ff
:   stx intOp1 + 1
    rts
.endproc

.proc signExtend8To32
    ldx #0
    lda intOp1
    and #$80
    beq L1
    ldx #$ff
L1:
    txa
    ldx #2
L2:
    sta intOp1+1,x
    dex
    bpl L2
    rts
.endproc

; Swap intOp1 and intOp2
.proc swapInt8
    lda intOp1
    pha
    lda intOp2
    sta intOp1
    pla
    sta intOp2
    rts
.endproc
