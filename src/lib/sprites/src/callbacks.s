.include "runtime.inc"

.export registerCollisionCallback

.import collisionCallback, isIrqSet, installIrqHandler

.proc registerCollisionCallback
    lda #0
    jsr rtLibLoadParam
    sta collisionCallback
    stx collisionCallback+1
    lda sreg
    sta collisionCallback+2
    lda sreg+1
    sta collisionCallback+3

    ; Check if the IRQ handler has been set up
    lda isIrqSet
    bne :+      ; skip the next instruction if it already is
    jsr installIrqHandler

:   rts
.endproc
