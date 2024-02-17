; LowerCase

.include "runtime.inc"

.export lowerCase

.import loadParam, returnVal

.proc lowerCase
    lda #0
    jsr loadParam
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
    jmp returnVal
.endproc
