.include "asmlib.inc"
.include "astlib.inc"
.include "parser.inc"
.include "tokenizer.inc"
.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "error.inc"

targetOffset = 0

.export parseAssignment

.import parseVariable, doResync, condGetToken, tlColonEqual, tlExpressionStart
.import parseExpression

.proc parseAssignment
    jsr parseVariable
    jsr pushQ               ; target

    ; :=
    resync tlColonEqual, tlExpressionStart
    lda #tcColonEqual
    ldx #errMissingColonEqual
    jsr condGetToken

    ldz #targetOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1

    lda #EXPR_ASSIGN
    jsr pushA

    ldq ptr1
    jsr pushQ

    ; <expr>
    lda #0
    jsr parseExpression
    jsr pushQ
    jsr pushQZero
    jsr pushQZero
    jsr exprCreate
    stq ptr1
    jsr popQ
    ldq ptr1
    rts
.endproc
