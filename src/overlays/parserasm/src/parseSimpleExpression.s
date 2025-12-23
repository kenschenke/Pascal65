.include "parser.inc"
.include "tokenizer.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

isVarInitOffset = 4
exprOffset = 0

.export parseSimpleExpression

.import parseTerm, tokenIn, getToken, doResync, parserToken
.import tlAddOps, tlExpressionFollow, tlStatementFollow, tlStatementStart

.proc parseSimpleExpression
    pha
    jsr pushA
    pla
    jsr parseTerm
    jsr pushQ

L1: lda #<tlAddOps
    ldx #>tlAddOps
    jsr tokenIn             ; if (tokenIn(tlAddOps))
    beq :+
    bra L3

:   lda parserToken
    cmp #tcPlus
    bne :+
    lda #EXPR_ADD
    bra L2
:   cmp #tcMinus
    bne :+
    lda #EXPR_SUB
    bra L2
:   cmp #tcOR
    bne :+
    lda #EXPR_OR
    bra L2
:   cmp #tcXOR
    bne :+
    lda #EXPR_BITWISE_XOR
    bra L2
:   cmp #tcLShift
    bne :+
    lda #EXPR_BITWISE_LSHIFT
    bra L2
:   lda #EXPR_BITWISE_RSHIFT

L2: pha
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
    jmp L1

L3: jsr popQ
    stq ptr1
    jsr popA
    ldq ptr1
    rts
.endproc
