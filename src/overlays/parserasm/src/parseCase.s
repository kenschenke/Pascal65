.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

exprOffset = 8
firstCaseOffset = 4
lastCaseOffset = 0

.export parseCASE

.import getToken, parseExpression, doResync, condGetToken, tokenIn
.import currentLineNumber, parserToken, parseCaseBranch
.import tlOF, tlCaseLabelStart, tlStatementStart, tlEND

.proc parseCASE
    ; CASE
    jsr getToken

    ; <expr>
    lda #0
    jsr parseExpression
    jsr pushQ

    ; OF
    resync tlOF, tlCaseLabelStart
    lda #tcOF
    ldx #errMissingOF
    jsr condGetToken

    jsr pushQZero           ; first case
    jsr pushQZero           ; last case

    ; Loop to parse CASE branches
L1: lda #<tlCaseLabelStart
    ldx #>tlCaseLabelStart
    jsr tokenIn
    bne L5

    jsr parseCaseBranch
    stq ptr2

    ldz #firstCaseOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne L2
    ; firstCase is null
    ldz #firstCaseOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L3
L2: ; append the new case branch to the last case
    ldz #lastCaseOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #stmt::next
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

L3: ; Set last case to the new case branch
    ldz #lastCaseOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    
    
    
    
    lda parserToken
    cmp #tcSemicolon
    beq L4
    lda #<tlCaseLabelStart
    ldx #>tlCaseLabelStart
    jsr tokenIn
    bne L5
L4: jsr getToken
    bra L1

L5: ; END
    resync tlEND, tlStatementStart
    lda #tcEND
    ldx #errMissingEND
    jsr condGetToken

    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #firstCaseOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2

    jsr popQ                ; lastCase
    jsr popQ                ; firstCase
    jsr popQ                ; expr

    lda #STMT_CASE
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; expr
    ldq ptr2
    jsr pushQ               ; body
    lda currentLineNumber
    ldx currentLineNumber+1
    jsr pushAX              ; lineNumber
    jmp stmtCreate
.endproc
