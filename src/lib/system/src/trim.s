.include "runtime.inc"

.export trim

.proc trim
    lda #0
    jsr rtLibLoadParam
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
    jmp rtLibReturnValue
.endproc
