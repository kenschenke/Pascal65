;
; Ullrich von Bassewitz, 25.10.2000
;
; CC65 runtime: Increment the stackpointer by 4
;

.include "runtime.inc"

.export pushax

.proc pushax
    pha
    lda sp
    sec
    sbc #2
    sta sp
    bcs L1
    dec sp + 1
L1:
    ldy #1
    txa
    sta (sp),y
    pla
    dey
    sta (sp),y
    rts
.endproc
