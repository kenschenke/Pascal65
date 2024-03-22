; Compare two strings

.include "runtime.inc"

.export compareStr

.import loadParam, returnVal

.proc compareStr
    lda #0
    jsr loadParam
    sta ptr3
    stx ptr3 + 1
    lda #1
    jsr loadParam
    sta ptr4
    stx ptr4 + 1
    jsr rtStrCompare
    ldx #0
    stx sreg
    stx sreg + 1
    jmp returnVal
.endproc
