; Compare two strings

.include "runtime.inc"

.export compareStr

.proc compareStr
    lda #0
    jsr rtLibLoadParam
    sta ptr3
    stx ptr3 + 1
    lda #1
    jsr rtLibLoadParam
    sta ptr4
    stx ptr4 + 1
    jsr rtStrCompare
    ldx #0
    stx sreg
    stx sreg + 1
    jmp rtLibReturnValue
.endproc
