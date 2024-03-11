
.export setBackgroundColor, setBorderColor, setTextColor, textColor

.import loadParam

textColor: .byte 1

.proc setBackgroundColor
    lda #0
    jsr loadParam
    sta $d021
    rts
.endproc

.proc setBorderColor
    lda #0
    jsr loadParam
    sta $d020
    rts
.endproc

.proc setTextColor
    lda #0
    jsr loadParam
    sta textColor
    rts
.endproc
