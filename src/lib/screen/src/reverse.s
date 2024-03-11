
.export setReverse, reverse

.import loadParam

reverse: .byte 0

.proc setReverse
    lda #0
    jsr loadParam
    beq :+
    lda #$80
:   sta reverse
    rts
.endproc
