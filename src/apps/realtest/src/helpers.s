.include "float.inc"

.import ROTATL, ROTATR, COMPLM, FPNORM, FPINP, FPOUT, FPADD, FPMULT, FPDIV, MOVIND, MOVIN, pushax, CALCPTR, FPSUB
.import popa
.importzp ptr1, ptr2

.export _complm, _rotAtl, _rotAtr, _num, _fpnorm
.export _lsb, _nsb, _msb, _exp, _fpinp, _fpout, _addNumbers, _getFirstNumber, _multNumbers, _divNumbers, _subtractNumbers
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

.proc _fpinp
    jmp FPINP
.endproc

.proc _fpout
    jmp FPOUT
.endproc

.proc _getFirstNumber
    pha
    txa
    pha
    jsr FPINP
    ; Copy FPACC to caller's buffer
    pla
    tax
    pla
    sta ptr2
    stx ptr2 + 1
    ldy #FPLSW
    jsr CALCPTR
    sta ptr1
    stx ptr1 + 1
    ldx #$04
    jmp MOVIN
.endproc

.proc _addNumbers
    pha
    txa
    pha
    ; Copy caller's buffer to FOP
    ldy #FOPLSW
    jsr CALCPTR
    sta ptr2
    stx ptr2 + 1
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    ldx #$04
    jsr MOVIN
    jmp FPADD
.endproc

.proc _subtractNumbers
    pha
    txa
    pha
    ; Copy caller's buffer to FOP
    ldy #FOPLSW
    jsr CALCPTR
    sta ptr2
    stx ptr2 + 1
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    ldx #$04
    jsr MOVIN
    jmp FPSUB
.endproc

.proc _multNumbers
    pha
    txa
    pha
    ; Copy caller's buffer to FOP
    ldy #FOPLSW
    jsr CALCPTR
    sta ptr2
    stx ptr2 + 1
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    ldx #$04
    jsr MOVIN
    jmp FPMULT
.endproc

.proc _divNumbers
    pha
    txa
    pha
    ; Copy caller's buffer to FOP
    ldy #FOPLSW
    jsr CALCPTR
    sta ptr2
    stx ptr2 + 1
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    ldx #$04
    jsr MOVIN
    jmp FPDIV
.endproc
