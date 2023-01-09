.include "float.inc"

.import ROTATL, ROTATR, COMPLM, FPNORM, MOVIND, MOVIN
.import popa

.export _complm, _rotAtl, _rotAtr, _num, _fpnorm, _callNorm
.export _lsb, _nsb, _msb, _exp, _getAcc
.import FPBASE

.bss

_num: .res 8
_lsb: .res 1
_nsb: .res 1
_msb: .res 1
_exp: .res 1

.code

.proc _rotAtl
    ldx #0
    ldy #4
L1:
    lda _num,x
    sta FPBASE + WORK0,x
    inx
    dey
    bne L1
    ldx #WORK0
    ldy #4
    jsr ROTATL
    ldx #0
    ldy #4
L2:
    lda FPBASE + WORK0,x
    sta _num,x
    inx
    dey
    bne L2
    rts
.endproc

.proc _rotAtr
    ldx #0
    ldy #4
L1:
    lda _num,x
    sta FPBASE + WORK0,x
    inx
    dey
    bne L1
    ldx #WORK3
    ldy #4
    jsr ROTATR
    ldx #0
    ldy #4
L2:
    lda FPBASE + WORK0,x
    sta _num,x
    inx
    dey
    bne L2
    rts
.endproc

.proc _complm
    ldx #0
    ldy #4
L1:
    lda _num,x
    sta FPBASE + WORK0,x
    inx
    dey
    bne L1
    ldx #WORK0
    ldy #4
    jsr COMPLM
    ldx #0
    ldy #4
L2:
    lda FPBASE + WORK0,x
    sta _num,x
    inx
    dey
    bne L2
    rts
.endproc

.proc _callNorm
    jmp FPNORM
.endproc

; fpnorm(unsigned char lsw, nsw, msw, exp)
.proc _fpnorm
    sta FPBASE + FPACCE
    jsr popa
    sta FPBASE + FPMSW
    jsr popa
    sta FPBASE + FPNSW
    jsr popa
    sta FPBASE + FPLSW
    lda #0
    sta FPBASE + FPLSWE

    jsr FPNORM

    lda FPBASE + FPLSW
    sta _lsb
    lda FPBASE + FPNSW
    sta _nsb
    lda FPBASE + FPMSW
    sta _msb
    lda FPBASE + FPACCE
    sta _exp
    rts
.endproc

.proc _getAcc
    lda FPBASE + FPLSW
    sta _lsb
    lda FPBASE + FPNSW
    sta _nsb
    lda FPBASE + FPMSW
    sta _msb
    lda FPBASE + FPACCE
    sta _exp
    rts
.endproc
