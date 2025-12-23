.include "parser.inc"
.include "tokenizer.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

isVarInitOffset = 4
exprOffset = 0

.export parseTerm

.import parseFactor, tokenIn, getToken, doResync, parserToken
.import tlMulOps, tlExpressionFollow, tlStatementFollow, tlStatementStart

.proc parseTerm
    pha
    jsr pushA
    pla
    jsr parseFactor
    jsr pushQ

    lda #<tlMulOps
    ldx #>tlMulOps
    jsr tokenIn             ; if (tokenIn(tlMulOps))
    beq :+
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
    ldz #isVarInitOffset
    nop
    lda (stackPointer),z
    jsr parseTerm
    stq ptr2
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    pla
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; left
    ldq ptr2
    jsr pushQ               ; right
    jsr pushQZero           ; name
    jsr pushQZero           ; value
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

L2: jsr popQ
    stq ptr1
    jsr popA
    ldq ptr1
    rts
.endproc
