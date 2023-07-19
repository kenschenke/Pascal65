.export _main
.import pushax

pvwrite = $fff7

_main:
    lda #1
    ldx #0
    jsr pushax
    lda #<buf
    ldx #>buf
    jsr pushax
    lda #13
    ldx #0
    jsr pvwrite
    lda #0
    rts

buf:
    .byt "hello, world", 10