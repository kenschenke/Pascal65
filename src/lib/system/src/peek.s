; Peek runtime function

.include "runtime.inc"

.import loadParam, returnVal

.export peek

; This routine returns the value in the address in the first parameter

.proc peek
    jsr loadParam
    sta ptr1
    stx ptr1 + 1
    lda #0
    sta sreg
    sta sreg + 1
    tax
    ldy #0
    lda (ptr1),y
    jmp returnVal
.endproc
