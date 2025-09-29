.include "zeropage.inc"
.include "4510macros.inc"

.export storeFromStack

; This routine loads 4 bytes from the runtime stack and stores them in
; an offset in ptr1
;
; Inputs: A - offset of the 4 bytes on the runtime stack
;         X - offset of the 4 bytes in the structure in ptr1
.proc storeFromStack
    phx
    taz
    neg
    neg
    nop
    lda (stackPointer),z
    stq tmp1
    plz
    ldx #0
:   lda tmp1,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
