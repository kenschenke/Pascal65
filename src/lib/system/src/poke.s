; Poke runtime function

.include "runtime.inc"

.export poke

; This routine stores the value from the second parameter
; into the address in the first parameter.

.proc poke
    ; Copy stackP to ptr1, subtracting 24 in the process.
    ; -24 is the location of the second parameter on the runtime stack.
    lda stackP
    sec
    sbc #24
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    ; Load the address in the first parameter into ptr2
    ldy #4
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2 + 1
    ; Load the byte from the second parameter
    ldy #0
    lda (ptr1),y
    ; Store it in the address
    sta (ptr2),y
    rts
.endproc
