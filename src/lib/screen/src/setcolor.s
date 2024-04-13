.include "runtime.inc"

.export setBackgroundColor, setBorderColor, setTextColor, textColor

textColor: .byte 1

.proc setBackgroundColor
    lda #0
    jsr rtLibLoadParam
    sta $d021
    rts
.endproc

.proc setBorderColor
    lda #0
    jsr rtLibLoadParam
    sta $d020
    rts
.endproc

.proc setTextColor
    lda #0
    jsr rtLibLoadParam
    sta textColor
    rts
.endproc
