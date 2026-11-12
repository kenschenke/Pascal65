;
; parseArrayLiteral.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parse an array literal

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

.import parseExpression, tlExpressionStart, doResync
.import getToken, parserToken, parserError, tlStatementFollow
.import tlExpressionFollow, tokenIn

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

    ; This is the first expression. Create an EXPR_ARRAY_LITERAL to hold it
    ; and the expressions that follow, even if the first one is itself an
    ; array literal. Each level of a nested literal has its own wrapper.
L2: ldq ptr1                ; save the new expression on the stack
    jsr pushQ
    ; Not makeExpr: it would put the last token's value in the new expression.
    lda #EXPR_ARRAY_LITERAL
    jsr pushA               ; kind
    jsr pushQZero           ; left
    jsr pushQZero           ; right
    jsr pushQZero           ; name
    jsr pushQZero           ; value
    jsr exprCreate
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
    beq DN
    ; An element without a comma before it is parsed as the next one
    lda #<tlExpressionStart
    ldx #>tlExpressionStart
    jsr tokenIn
    bne :+
    lda #errUnexpectedToken
    jsr parserError
    jmp L1

    ; Anything else is skipped, up to a token that can go on with the
    ; literal. Any other token ends it, and the caller reports the
    ; missing ")". Going on past one could run off the end of the file.
:   resync tlExpressionFollow, tlExpressionStart, tlStatementFollow
    lda parserToken
    cmp #tcComma
    bne :+
    jsr getToken
    jmp L1
:   cmp #tcRParen
    beq DN
    lda #<tlExpressionStart
    ldx #>tlExpressionStart
    jsr tokenIn
    bne DN
    jmp L1

DN: jsr popQ
    stq ptr1
    jsr popQ

    ldq ptr1
    rts
.endproc
