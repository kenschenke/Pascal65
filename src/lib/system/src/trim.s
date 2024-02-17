.include "runtime.inc"

.export trim

.import loadParam, returnVal

.proc trim
    lda #0
    jsr loadParam
    jsr rtTrim
    pha
    txa
    pha
    lda #0
    sta sreg
    sta sreg + 1
    pla
    tax
    pla
    jmp returnVal
.endproc
