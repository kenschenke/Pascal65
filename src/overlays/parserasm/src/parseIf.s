.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

falseOffset = 0
trueOffset = 4
exprOffset = 8

.export parseIF

.import getToken, parseExpression, doResync, condGetToken, parseStatement
.import parserToken, currentLineNumber
.import tlTHEN, tlStatementStart

.proc parseIF
    ; IF
    jsr getToken

    ; <expr>
    lda #0
    jsr parseExpression
    jsr pushQ

    ; THEN
    resync tlTHEN, tlStatementStart
    lda #tcTHEN
    ldx #errMissingTHEN
    jsr condGetToken

    ; <stmt-if-true>
    jsr parseStatement
    jsr pushQ

    lda parserToken
    cmp #tcELSE
    bne :+
    ; ELSE
    jsr getToken
    ; <stmt-if-false>
    jsr parseStatement
    jsr pushQ
    bra L1
:   jsr pushQZero

L1: ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #trueOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    lda #STMT_IF_ELSE
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; expr
    ldq ptr2
    jsr pushQ               ; body
    lda currentLineNumber
    ldx currentLineNumber+1
    jsr pushAX              ; lineNumber
    jsr stmtCreate
    stq ptr1
    ldz #falseOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    jsr isQZero
    beq L2
    ldz #stmt::else_body
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
L2: jsr popQ
    jsr popQ
    jsr popQ
    ldq ptr1
    rts
.endproc
