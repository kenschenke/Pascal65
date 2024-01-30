.include "float.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp floatNeg

; end of exports
.byte $00, $00, $00

; imports

COMPLM: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc floatNeg
    jsr storeFPACC
    ldx #FPLSW
    ldy #3
    jsr COMPLM
    jmp loadFPACC
.endproc

.proc loadFPACC
    lda FPBASE + FPMSW
    sta sreg
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPLSW
    ldx FPBASE + FPNSW
    rts
.endproc

.proc storeFPACC
    sta FPBASE + FPLSW
    stx FPBASE + FPNSW
    lda sreg
    sta FPBASE + FPMSW
    lda sreg + 1
    sta FPBASE + FPACCE
    lda #0
    sta FPBASE + FPLSWE
    rts
.endproc
