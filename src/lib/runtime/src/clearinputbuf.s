.include "runtime.inc"

.export clearInputBuf

.proc clearInputBuf
    lda #0
    sta inputBufUsed
    sta inputPos
    rts
.endproc

