.include "parser.inc"
.include "tokenizer.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

exprOffset = 0
isVarInitOffset = 4

.export parseExpression

.import parseSimpleExpression, tokenIn, getToken, doResync, parserToken
.import tlRelOps, tlExpressionFollow, tlStatementFollow, tlStatementStart

.proc parseExpression
    pha
    jsr pushA
    pla
    jsr parseSimpleExpression
    jsr pushQ

    lda #<tlRelOps
    ldx #>tlRelOps
    jsr tokenIn             ; if (tokenIn(tlRelOps))
    beq :+
    bra L2

:   lda parserToken
    cmp #tcLt
    bne :+
    lda #EXPR_LT
    bra L1
:   cmp #tcLe
    bne :+
    lda #EXPR_LTE
    bra L1
:   cmp #tcGt
    bne :+
    lda #EXPR_GT
    bra L1
:   cmp #tcGe
    bne :+
    lda #EXPR_GTE
    bra L1
:   cmp #tcNe
    bne :+
    lda #EXPR_NE
    bra L1
:   lda #EXPR_EQ

L1: pha
    jsr getToken
    ldz #isVarInitOffset
    nop
    lda (stackPointer),z
    jsr parseSimpleExpression
    stq ptr2
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    pla
    jsr pushA                       ; expression kind
    ldq ptr1
    jsr pushQ                       ; expr left
    ldq ptr2
    jsr pushQ                       ; expr right
    jsr pushQZero                   ; name
    jsr pushQZero                   ; value
    jsr exprCreate
    stq ptr1
    ldx #0
    ldz #exprOffset
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

L2: resync tlExpressionFollow, tlStatementFollow, tlStatementStart

    jsr popQ
    stq ptr1
    jsr popA
    ldq ptr1
    rts
.endproc
