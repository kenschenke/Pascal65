.include "float.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp _strToFloat

; end of exports
.byte $00, $00, $00

; imports

FPINP: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc _strToFloat
    sta ptr1
    stx ptr1 + 1
    ldx #0
    ldy #0
L1:
    lda (ptr1),y
    sta FPBUF,x
    beq L2
    inx
    iny
    bne L1
L2:
    jsr FPINP
    lda FPBASE + FPMSW
    sta sreg
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPLSW
    ldx FPBASE + FPNSW
    rts
.endproc
