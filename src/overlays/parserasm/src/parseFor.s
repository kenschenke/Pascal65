.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

isDownToOffset = 0
exitExprOffset = 1
initExprOffset = 5
controlExprOffset = 9

.export parseFOR

.import getToken, parserToken, parserError, condGetToken, doResync, parserString
.import parseExpression, currentLineNumber, parseStatement
.import tlColonEqual, tlExpressionStart, tlTODOWNTO, tlDO, tlStatementStart

.proc parseFOR
    jsr pushQZero           ; controlExpr
    jsr pushQZero           ; initExpr
    jsr pushQZero           ; exitExpr
    lda #0
    jsr pushA               ; isDownTo

    ; FOR
    jsr getToken

    ; <id>
    lda parserToken
    cmp #tcIdentifier
    bne L1
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq ptr1
    lda #EXPR_NAME
    jsr pushA               ; kind
    jsr pushQZero           ; left
    jsr pushQZero           ; right
    ldq ptr1
    jsr pushQ               ; name
    jsr pushQZero           ; value
    jsr exprCreate
    stq ptr1
    ldz #controlExprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jsr getToken
    bra L2
L1: lda #errMissingIdentifier
    jsr parserError

    ; :=
L2: resync tlColonEqual, tlExpressionStart
    lda #tcColonEqual
    ldx #errMissingColonEqual
    jsr condGetToken

    ; <init-expr>
    lda #0
    jsr parseExpression
    stq ptr2
    ldz #controlExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    lda #EXPR_ASSIGN
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; left
    ldq ptr2
    jsr pushQ               ; right
    jsr pushQZero           ; name
    jsr pushQZero           ; value
    jsr exprCreate
    stq ptr1
    ldz #initExprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; TO or DOWNTO
    resync tlTODOWNTO, tlExpressionStart
    lda parserToken
    cmp #tcTO
    beq L3
    cmp #tcDOWNTO
    bne :+
    lda #1
    ldz #isDownToOffset
    nop
    sta (stackPointer),z
    bra L3
:   lda #errMissingTOorDOWNTO
    jsr parserError

L3: jsr getToken

    ; <exit-expr>
    lda #0
    jsr parseExpression
    stq ptr1
    ldz #exitExprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; DO
    resync tlDO, tlStatementStart
    lda #tcDO
    ldx #errMissingDO
    jsr condGetToken

    ; <stmt>
    jsr parseStatement
    stq ptr1
    lda #STMT_FOR
    jsr pushA               ; kind
    jsr pushQZero           ; expr
    ldq ptr1
    jsr pushQ               ; body
    lda currentLineNumber
    ldx currentLineNumber+1
    jsr pushAX
    jsr stmtCreate
    stq ptr1

    ; <init-expr>
    ldz #initExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #stmt::init_expr
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; <exit-expr>
    ldz #exitExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #stmt::to_expr
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; isDownTo
    ldz #isDownToOffset
    nop
    lda (stackPointer),z
    beq :+
    ldz #stmt::isDownTo
    nop
    sta (ptr1),z

    ; Clean up
:   jsr popA
    jsr popQ
    jsr popQ
    jsr popQ
    ldq ptr1
    rts
.endproc
