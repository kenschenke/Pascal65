
.export isQZero

.proc isQZero
    cmp #0
    bne :+
    cpx #0
    bne :+
    cpy #0
    bne :+
    cpz #0
:   rts
.endproc
