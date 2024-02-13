; Poke runtime function

.include "runtime.inc"

.import loadParam

.export poke

; This routine stores the value from the second parameter
; into the address in the first parameter.

.proc poke
    lda #0
    jsr loadParam
    sta ptr2
    stx ptr2 + 1
    lda #1
    jsr loadParam
    ldy #0
    sta (ptr2),y
    rts
.endproc
