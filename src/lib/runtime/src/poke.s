; This routine stores a byte value in a specified memory address.

; The memory address is pushed to the runtime stack and the
; value is passed in A.

.include "runtime.inc"

.import popeax
.export poke

.proc poke
    pha
    jsr popeax
    sta ptr1
    stx ptr1 + 1
    pla
    ldy #0
    sta (ptr1),y
    rts
.endproc
