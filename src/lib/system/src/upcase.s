; UpCase

.include "runtime.inc"

.export upCase

.proc upCase
    lda #0
    jsr rtLibLoadParam
    ldy #1
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
