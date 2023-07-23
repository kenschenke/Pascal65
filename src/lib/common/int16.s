; Placeholder for 16-bit integer operations

.export tensTable, spcl32768, intBuf, intOp1, intOp2, swapInt16
.export absInt16, swapInt16
.export isNegInt16, invertInt16

.data

tensTable:
    .word 10000
    .word 1000
    .word 100
    .word 10
    .word 1

spcl32768:
    .asciiz "-32768"

.bss

; Operands for 16-bit integer operations
intOp1: .res 2
intOp2: .res 2
intBuf: .res 7

.code

; Z flag is non-zero if number is negative
.proc isNegInt16
    lda intOp1 + 1
    and #$80
    rts
.endproc

; Invert intOp1 by applying the two's complement.
.proc invertInt16
    ; invert the bits
    lda intOp1
    eor #$ff
    sta intOp1
    lda intOp1 + 1
    eor #$ff
    sta intOp1 + 1
    ; add 1
    clc
    lda intOp1
    adc #1
    sta intOp1
    lda intOp1 + 1
    adc #0
    sta intOp1 + 1
    rts
.endproc

; Absolute value of intOp1
.proc absInt16
    jsr isNegInt16
    beq done
    jmp invertInt16
done:
    rts
.endproc

; Swap intOp1 and intOp2
.proc swapInt16
    lda intOp1
    pha
    lda intOp1 + 1
    pha
    lda intOp2
    sta intOp1
    lda intOp2 + 1
    sta intOp1 + 1
    pla
    sta intOp2 + 1
    pla
    sta intOp2
    rts
.endproc

