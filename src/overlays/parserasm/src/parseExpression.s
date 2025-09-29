.include "astlib.inc"
.include "parser.inc"
.include "tokenizer.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

.export parseExpression

.import parseSimpleExpression, tokenIn, getToken, doResync, parserToken
.import tlRelOps, tlExpressionFollow, tlStatementFollow, tlStatementStart

.proc parseExpression
    pha
    jsr parseSimpleExpression
    jsr pushQ

    lda #<tlRelOps
    ldx #>tlRelOps
    jsr tokenIn             ; if (tokenIn(tlRelOps))
    beq :+
    pla
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
    pla
    jsr pushA                       ; expression kind
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    jsr pushQ                       ; expr left
    pla
    jsr parseSimpleExpression
    jsr pushQ                       ; expr right
    jsr pushQZero                   ; name
    jsr pushQZero                   ; value
    jsr exprCreate
    stq ptr1
    ldx #0
    ldz #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

L2: resync tlExpressionFollow, tlStatementFollow, tlStatementStart

    jsr popQ
    rts
.endproc
