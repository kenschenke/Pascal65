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
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    lda #EXPR_SUBSCRIPT
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; left
    lda #0
    jsr parseExpression
    jsr pushQ               ; right
    jsr pushQZero           ; name
    jsr pushQZero           ; value
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
    beq L1

    ; ] (right bracket)
    lda #tcRBracket
    ldx #errMissingRightBracket
    jsr condGetToken

    jsr popQ
    rts
.endproc
