; UpCase

.include "runtime.inc"

.export upCase

.import loadParam, returnVal

.proc upCase
    lda #0
    jsr loadParam
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
    jmp returnVal
.endproc
