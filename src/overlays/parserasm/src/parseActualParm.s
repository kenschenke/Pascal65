.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

exprOffset = 0
isWriteWritelnOffset = 4

.export parseActualParm

.import parseExpression, parserToken, getToken

; Create a new expr node. The left is an expression tree and
; the right is zero. The type is EXPR_ARG.
.proc parseActualParm
    jsr pushA               ; isWriteWriteln

    lda #0
    jsr parseExpression
    stq ptr1

    lda #EXPR_ARG
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; left
    jsr pushQZero           ; right
    jsr pushQZero           ; name
    jsr pushQZero           ; value
    jsr exprCreate
    jsr pushQ

    ldz #isWriteWritelnOffset
    nop
    lda (stackPointer),z
    beq L9
    lda parserToken
    cmp #tcColon
    bne L9

    jsr getToken
    lda #0
    jsr parseExpression     ; parse width expression
    stq ptr1
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #expr::width
    ldx #0
:   lda ptr1,x
    nop
    sta (ptr2),z
    inx
    inz
    cpx #4
    bne :-

    lda parserToken
    cmp #tcColon
    bne L9
    jsr getToken
    lda #0
    jsr parseExpression
    stq ptr1
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #expr::precision
    ldx #0
:   lda ptr1,x
    nop
    sta (ptr2),z
    inx
    inz
    cpx #4
    bne :-

L9: jsr popQ
    stq ptr1
    jsr popA
    ldq ptr1
    rts
.endproc
