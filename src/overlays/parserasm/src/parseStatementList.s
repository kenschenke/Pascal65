.include "asmlib.inc"
.include "error.inc"
.include "tokenizer.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

.export parseStatementList

.import parseStatement, tlStatementStart, parserError, parserToken, getToken, tokenIn

lastStmtOffset = 0
firstStmtOffset = 4
terminatorOffset = 5

.proc parseStatementList
    jsr pushA               ; terminator
    jsr pushQZero           ; firstStmt
    jsr pushQZero           ; lastStmt

L1:
    jsr parseStatement
    jsr pushQ

    lda #<tlStatementStart
    ldx #>tlStatementStart
    jsr tokenIn
    bne :+
    lda #errUnexpectedToken
    jsr parserError
    bra L2
:   lda parserToken
    cmp #tcSemicolon
    bne L2
    jsr getToken

L2: jsr popQ
    stq ptr1
    ldz #firstStmtOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne L3
    ldz #firstStmtOffset+3
    ldx #3
:   lda ptr1,x
    nop
    sta (stackPointer),z
    dez
    dex
    bpl :-
    bra L4
L3: ldz #lastStmtOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #stmt::next+3
    ldx #3
:   lda ptr1,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
L4: ldz #lastStmtOffset+3
    ldx #3
:   lda ptr1,x
    nop
    sta (stackPointer),z
    dez
    dex
    bpl :-

    ldz #terminatorOffset
    nop
    lda (stackPointer),z
    cmp parserToken
    bne L5
    lda parserToken
    cmp #tcEndOfFile
    bne L5
    jmp L1

L5: ldz #firstStmtOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    jsr popQ
    jsr popQ
    jsr popA
    ldq ptr1
    rts
.endproc

