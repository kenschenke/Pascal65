.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export nameClone

; This routine clones a null-terminated string.
; The string is passed in Q.
.proc nameClone
    stq ptr1

    jsr pushQ

    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    inz
    bne :-
:   inz
    tza
    ldx #0
    jsr heapAlloc
    stq ptr2

    jsr popQ
    stq ptr1
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    beq :+
    inz
    bne :-
:   ldq ptr2
    rts
.endproc
