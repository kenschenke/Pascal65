.include "runtime.inc"

.export registerCollisionCallback

.import collisionCallback

.proc registerCollisionCallback
    lda #0
    jsr rtLibLoadParam
    sta collisionCallback
    stx collisionCallback+1
    lda sreg
    sta collisionCallback+2
    lda sreg+1
    sta collisionCallback+3
    rts
.endproc
