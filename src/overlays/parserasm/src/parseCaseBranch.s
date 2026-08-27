.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

lastLabelOffset = 0
firstLabelOffset = 4

.export parseCaseBranch

.import parseCaseLabel, parserToken, getToken, doResync
.import parseStatement, condGetToken, currentLineNumber, tokenIn
.import tlColon, tlCaseLabelStart, tlStatementStart, parserError

.proc parseCaseBranch
    jsr pushQZero           ; firstLabel
    jsr pushQZero           ; lastLabel

    ; <case-label-list>
L1: jsr parseCaseLabel
    stq ptr2

    ldz #firstLabelOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne L2
    ; firstLabel is null
    ldz #firstLabelOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L3
L2: ; append to last label
    ldz #lastLabelOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #expr::right
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-

    ; set last label to the current label
L3: ldz #lastLabelOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inx
    inz
    cpx #4
    bne :-

    lda parserToken
    cmp #tcComma
    bne L4

    ; Saw comma, look for another case label
    jsr getToken
    lda #<tlCaseLabelStart
    ldx #>tlCaseLabelStart
    jsr tokenIn
    beq L1
    lda #errMissingConstant
    jsr parserError

    ; colon
L4: resync tlColon, tlStatementStart
    lda #tcColon
    ldx #errMissingColon
    jsr condGetToken

    jsr parseStatement
    stq ptr2

    jsr popQ            ; lastLabel
    jsr popQ            ; firstLabel
    stq ptr1

    lda #STMT_CASE_LABEL
    jsr pushA           ; kind
    ldq ptr1
    jsr pushQ           ; expr
    ldq ptr2
    jsr pushQ           ; body
    lda currentLineNumber
    ldx currentLineNumber+1
    jsr pushAX
    jmp stmtCreate
.endproc
