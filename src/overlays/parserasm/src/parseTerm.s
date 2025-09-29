.include "astlib.inc"
.include "parser.inc"
.include "tokenizer.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

.export parseTerm

.import parseFactor, tokenIn, getToken, doResync, parserToken
.import tlMulOps, tlExpressionFollow, tlStatementFollow, tlStatementStart

.proc parseTerm
    pha
    jsr parseFactor
    jsr pushQ

    lda #<tlMulOps
    ldx #>tlMulOps
    jsr tokenIn             ; if (tokenIn(tlMulOps))
    beq :+
    pla
    bra L2

:   lda parserToken
    cmp #tcStar
    bne :+
    lda #EXPR_MUL
    bra L1
:   cmp #tcSlash
    bne :+
    lda #EXPR_DIV
    bra L1
:   cmp #tcDIV
    bne :+
    lda #EXPR_DIVINT
    bra L1
:   cmp #tcMOD
    bne :+
    lda #EXPR_MOD
    bra L1
:   cmp #tcAND
    bne :+
    lda #EXPR_AND
    bra L1
:   cmp #tcAmpersand
    bne :+
    lda #EXPR_BITWISE_AND
    bra L1
:   lda #EXPR_BITWISE_OR

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
