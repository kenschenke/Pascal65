.include "tokenizer.inc"
.include "cbm_kernal.inc"

.export testSkipWhiteSpace

.import skipWhiteSpace, getCurrentChar, openSourceFile, closeSourceFile, getChar

.data

sourceFn: .asciiz "hello.pas"

.code

.proc testSkipWhiteSpace
    lda #<sourceFn
    ldx #>sourceFn
    jsr openSourceFile

L1: jsr getChar
    cmp #CH_EOF
    bne L2
    bra DN

L2: jsr skipWhiteSpace
    jsr getCurrentChar
    cmp #CH_EOF
    beq DN
    jsr CHROUT
    bra L1

DN: jsr closeSourceFile
    rts
.endproc
