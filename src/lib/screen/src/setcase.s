
.export setLowerCase, setUpperCase

.proc setLowerCase
.ifdef __MEGA65__
    lda #0
    sta $d068
    lda #$d8
    sta $d069
    lda #2
    sta $d06a
.else
    lda #$17
    sta $d018
.endif
    rts
.endproc

.proc setUpperCase
.ifdef __MEGA65__
    lda #0
    sta $d068
    lda #$d0
    sta $d069
    lda #2
    sta $d06a
.else
    lda #$15
    sta $d018
.endif
    rts
.endproc
