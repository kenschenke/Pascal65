.include "ast.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

exprOffset = 0
lastExprOffset = 4
rootExprOffset = 8

.export parseField

.import parserString, getToken, parserValue, parserToken

.proc parseField
    jsr pushQ           ; expr
    jsr pushQZero       ; rootExpr
    jsr pushQZero       ; lastExpr

L1: lda parserToken
    cmp #tcPeriod
    beq :+
    jmp L3

:   jsr getToken

    ; Create a new FIELD expression. The left is the name expression
    ; for the record.
    lda #EXPR_NAME
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    jsr pushQ
    jsr pushQZero
    lda #0
    sta parserValue
    sta parserValue+1
    sta parserValue+2
    sta parserValue+3
    jsr exprCreate
    stq ptr1

    ; lastExpr == 0 ? expr : lastExpr
    ldz #lastExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq :+
    stq ptr2
    bra L2
:   ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
L2: lda #EXPR_FIELD
    jsr pushA
    ldq ptr2
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    lda #0
    sta parserValue
    sta parserValue+1
    sta parserValue+2
    sta parserValue+3
    jsr exprCreate
    stq ptr1

    ; rootExpr = ptr1
    ldz #rootExprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; lastExpr = ptr1
    ldz #lastExprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    jsr getToken
    jmp L1

L3: jsr popQ
    jsr popQ
    rts
.endproc
