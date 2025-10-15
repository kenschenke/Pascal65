.include "tokenizer.inc"
.include "4510macros.inc"
.include "asmlib.inc"
.include "error.inc"

.export parseCompound

.import getToken, parseStatementList, condGetToken, parserToken

.proc parseCompound
    lda parserToken
    cmp #tcEND
    beq :+
    jsr getToken
:   lda #tcEND
    jsr parseStatementList
    jsr pushQ

    lda #tcEND
    ldx #errMissingEND
    jsr condGetToken

    jsr popQ
    rts
.endproc
