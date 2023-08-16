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
