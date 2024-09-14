.include "runtime.inc"

.export spriteData

.proc spriteData
    lda #0
    jsr rtLibLoadParam              ; Get the first parameter
    sta tmp1
    lda #1
    jsr rtLibLoadParam              ; Get the second parameter
    sta ptr1
    stx ptr1+1
    lda $d06c
    sta ptr3
    lda $d06d
    sta ptr3+1
    ldy tmp1
    lda (ptr3),y
    sta ptr2
    lda #0
    sta ptr2+1
    ldx #5
:   asl ptr2
    rol ptr2+1
    dex
    bpl :-
    ldy #62
:   lda (ptr1),y
    sta (ptr2),y
    dey
    bpl :-
    rts
.endproc
