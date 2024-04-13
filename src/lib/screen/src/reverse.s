.include "runtime.inc"

.export setReverse, reverse

reverse: .byte 0

.proc setReverse
    lda #0
    jsr rtLibLoadParam
    beq :+
    lda #$80
:   sta reverse
    rts
.endproc
