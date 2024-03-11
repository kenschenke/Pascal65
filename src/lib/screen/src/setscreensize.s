
.export setScreenSize

.import loadParam

.proc setScreenSize
    lda #0
    jsr loadParam
    cmp #80                 ; Set to 80 columns?
    bne C4                  ; Branch if A != 80
    lda $d031
    ora #$80
    sta $d031
    lda #$50
    sta $d04c
    bne DY
C4: cmp #40                 ; Set to 40 columns?
    bne DY                  ; Branch if A != 40
    lda $d031
    and #$7f
    sta $d031
    lda #$4e
    sta $d04c
DY: lda #1
    jsr loadParam
    cmp #50                 ; Set to 50 rows?
    bne C2                  ; Branch if A != 50
    lda $d031
    ora #8
    sta $d031
    bne DN
C2: cmp #25                 ; Set to 25 rows?
    bne DN                  ; Branch if A != 25
    lda $d031
    and #$f7
    sta $d031
DN: rts
.endproc
