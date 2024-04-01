;
; Ullrich von Bassewitz, 25.10.2000
;
; CC65 runtime: Decrement the stackpointer by 4
;

.include "runtime.inc"

.export decsp4

.proc decsp4
    lda sp
    sec
    sbc #4
    sta sp
    bcc @L1
    rts
@L1:
    dec sp + 1
    rts
.endproc
