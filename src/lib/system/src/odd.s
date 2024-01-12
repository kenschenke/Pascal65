; Odd runtime function

.include "runtime.inc"

.export odd

; This routine returns a non-zero value if the paramater is odd

.proc odd
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
    ; Isolate the 1 bit
    and #1
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
