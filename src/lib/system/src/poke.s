; Poke runtime function

.include "runtime.inc"

.export poke

; This routine stores the value from the second parameter
; into the address in the first parameter.

.proc poke
    lda #0
    jsr rtLibLoadParam
    sta ptr2
    stx ptr2 + 1
    lda #1
    jsr rtLibLoadParam
    ldy #0
    sta (ptr2),y
    rts
.endproc
