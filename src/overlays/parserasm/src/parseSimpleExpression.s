.include "astlib.inc"
.include "parser.inc"
.include "tokenizer.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

.export parseSimpleExpression

.import parseTerm, tokenIn, getToken, doResync, parserToken
.import tlAddOps, tlExpressionFollow, tlStatementFollow, tlStatementStart

.proc parseSimpleExpression
    pha
    jsr parseTerm
    jsr pushQ

    lda #<tlAddOps
    ldx #>tlAddOps
    jsr tokenIn             ; if (tokenIn(tlAddOps))
    beq :+
    pla
    bra L2

:   lda parserToken
    cmp #tcPlus
    bne :+
    lda #EXPR_ADD
    bra L1
:   cmp #tcMinus
    bne :+
    lda #EXPR_SUB
    bra L1
:   cmp #tcOR
    bne :+
    lda #EXPR_OR
    bra L1
:   cmp #tcXOR
    bne :+
    lda #EXPR_BITWISE_XOR
    bra L1
:   cmp #tcLShift
    bne :+
    lda #EXPR_BITWISE_LSHIFT
    bra L1
:   lda #EXPR_BITWISE_RSHIFT

L1: pha
    jsr getToken
    pla
    jsr pushA
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    jsr pushQ
    pla
    jsr parseTerm
    jsr pushQ
    jsr pushQZero
    jsr pushQZero
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

L2: jsr popQ
    rts
.endproc
