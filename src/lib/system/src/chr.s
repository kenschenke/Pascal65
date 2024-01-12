; Chr runtime function

.include "runtime.inc"

.export chr

; This routine returns the low byte of the parameter.

.proc chr
    ; Copy stackP to ptr1, subtracting 20 in the process.
    ; -20 is the location of the parameter on the runtime stack.
    lda stackP
    sec
    sbc #20
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    ; Load the least significant byte of the parameter
    ldy #0
    lda (ptr1),y
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
