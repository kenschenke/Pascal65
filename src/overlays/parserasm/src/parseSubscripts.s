.include "ast.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "error.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseSubscripts

.import getToken, condGetToken, parserToken, parserValue, parseExpression

.proc parseSubscripts
    jsr pushQ

    ; Loop to parse a list of subscripts separated by commas

L1: jsr getToken
    lda #EXPR_SUBSCRIPT
    jsr pushA
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    jsr pushQ
    lda #0
    jsr parseExpression
    jsr pushQ
    jsr pushQZero
    lda #0
    sta parserValue
    sta parserValue+1
    sta parserValue+2
    sta parserValue+3
    jsr exprCreate
    stq ptr1
    ldz #0
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    lda parserToken
    cmp #tcComma
    bne L1

    ; ] (right bracket)
    lda #tcRBracket
    ldx #errMissingRightBracket
    jsr condGetToken

    jsr popQ
    rts
.endproc
