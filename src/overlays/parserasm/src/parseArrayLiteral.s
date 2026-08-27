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

.import makeExpr, parseExpression, tlExpressionStart, doResync
.import getToken, parserToken, parserError, tlStatementFollow

.proc parseArrayLiteral
    jsr pushQZero           ; lastExpr
    jsr pushQZero           ; arrayExpr

    ; Parse comma-separated list of literals until a right paren
L1: lda parserToken
    cmp #tcRParen
    bne :+
    jmp DN

:   lda #1
    jsr parseExpression
    stq ptr1

    ; If arrayExpr is non-null, add the new expression
    ldz #arrayExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne L3

    ; If the new expression is an array literal itself, set arrayExpr to it.
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ARRAY_LITERAL
    bne L2
    ldz #arrayExprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L5

    ; If this is the first expression (arrayExpr == null) and the parsed
    ; expression is an array literal itself, set arrayExpr to it.
    ; Otherwise, create an EXPR_ARRAY_LITERAL expression and set the new
    ; expression to 

    ; Create an EXPR_ARRAY_LITERAL
L2: ldq ptr1                ; save the new expression on the stack
    jsr pushQ
    lda #EXPR_ARRAY_LITERAL
    jsr makeExpr
    stq ptr3                ; put the array literal expression in ptr3
    jsr popQ
    stq ptr1                ; put the new expression back into ptr1
    ; Copy ptr3 to arrayExpr
    ldz #arrayExprOffset
    ldx #0
:   lda ptr3,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

L3: ldz #lastExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    jsr isQZero
    bne L4
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
    bra L5
L4: ; lastExpr.right = expr (ptr1)
    ldz #expr::right+3
    ldx #3
:   lda ptr1,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
L5: ; lastExpr = expr
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
L6: lda parserToken
    cmp #tcComma
    bne :+
    jsr getToken
    jmp L1
:   cmp #tcRParen
    bne :+
    jmp L1
:   lda #errUnexpectedToken
    jsr parserError
    resync tlExpressionStart, tlStatementFollow
    jsr getToken
    jmp L1

DN: jsr popQ
    stq ptr1
    jsr popQ

    ldq ptr1
    rts
.endproc
