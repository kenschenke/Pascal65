; LowerCase

.include "runtime.inc"

.export lowerCase

.proc lowerCase
    lda #0
    jsr rtLibLoadParam
    ldy #0
    jsr rtStrCase
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
