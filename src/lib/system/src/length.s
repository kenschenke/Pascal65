; Implement the Length function (string length)

.include "runtime.inc"

.export length

.import loadParam, returnVal

.proc length
    lda #0
    jsr loadParam
    sta ptr1
    stx ptr1 + 1
    lda #0
    tax
    tay
    sta sreg
    sta sreg + 1
    lda (ptr1),y
    jmp returnVal
.endproc
