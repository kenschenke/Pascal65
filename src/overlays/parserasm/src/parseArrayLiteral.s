.include "ast.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "tokenizer.inc"
.include "4510macros.inc"
.include "error.inc"
.include "zeropage.inc"

lastExprOffset = 4
arrayExprOffset = 0

.export parseArrayLiteral

.import makeExpr, parserValue, parseExpression, tlExpressionStart, doResync
.import getToken, parserToken, parserError

.proc parseArrayLiteral
    lda #0
    tax
    tay
    taz
    stq parserValue
    jsr pushQ

    lda #EXPR_ARRAY_LITERAL
    jsr makeExpr
    jsr pushQ

    ; Parse comma-separated list of literals until a right paren
L1: lda parserToken
    cmp #tcRParen
    bne L4

    lda #1
    jsr parseExpression
    stq ptr1
    ldz #lastExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    jsr isQZero
    bne L2
    ; lastExpr is null
    ldz #arrayExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr3
    ldz #expr::left+3
    ldx #3
:   lda ptr1,x
    nop
    sta (ptr3),z
    dez
    dex
    bpl :-
    bra L3
L2: ; lastExpr.right = expr (ptr1)
    ldz #expr::right+3
    ldx #3
:   lda ptr1,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
L3: ; lastExpr = expr
    ldx #0
    ldz #lastExprOffset
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; if (parserToken == tcComma)
    lda parserToken
    cmp #tcComma
    bne :+
    jsr getToken
    bra L1
:   cmp #tcRParen
    bne L1
    lda #errUnexpectedToken
    jsr parserError
    resync tlExpressionStart
    jmp L1

L4: jsr popQ
    jsr popQ

    rts
.endproc
