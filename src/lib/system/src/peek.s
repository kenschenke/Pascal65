; Peek runtime function

.include "runtime.inc"

.export peek

; This routine returns the value in the address in the first parameter

.proc peek
    ; Copy stackP to ptr1, subtracting 20 in the process.
    ; -20 is the location of the parameter on the runtime stack.
    lda stackP
    sec
    sbc #20
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    ; Load the address in the first parameter into ptr2
    ldy #0
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2 + 1
    ; Load the byte from the address
    ldy #0
    lda (ptr2),y
    ; Store it in the least significant byte of the return value
    ldy #16
    sta (ptr1),y
    ; Zero out the rest of the bytes in the return value
    lda #0
    ldx #2
:   iny
    sta (ptr1),y
    dex
    bpl :-
    rts
.endproc
