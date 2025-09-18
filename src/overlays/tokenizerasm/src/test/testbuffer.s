.include "cbm_kernal.inc"
.include "tokenizer.inc"

.export testBuffer

.import openSourceFile, getChar, closeSourceFile

.data

sourceFn: .asciiz "hello.pas"

.code

.proc testBuffer
    lda #<sourceFn
    ldx #>sourceFn
    jsr openSourceFile

L1: jsr getChar
    cmp #CH_EOF
    bne L2
    bra DN

L2: jsr CHROUT
    bra L1

DN: jsr closeSourceFile
    rts
.endproc
