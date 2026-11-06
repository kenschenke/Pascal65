;
; parseStatementList.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parse a list of statements

.include "asmlib.inc"
.include "error.inc"
.include "tokenizer.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

.export parseStatementList

.import parseStatement, tlStatementStart, parserError, parserToken, getToken, tokenIn
.import tlStatementListNotAllowed

lastStmtOffset = 0
firstStmtOffset = 4
terminatorOffset = 8

.bss

; Non-zero when the token after a statement ends the list. Only the code
; between setting and testing it uses it, so nested lists don't clash.
stopList: .res 1

.code

.proc parseStatementList
    jsr pushA               ; terminator
    jsr pushQZero           ; firstStmt
    jsr pushQZero           ; lastStmt

    ; Each pass must consume a token or start a statement. Otherwise a
    ; token that no statement consumes, such as a stray ")" or the period
    ; after a nested END, would loop forever. The list ends at any token
    ; other than these and the caller reports what it expected.
L1: jsr parseStatement
    jsr pushQ

    lda #0
    sta stopList
    lda #<tlStatementStart
    ldx #>tlStatementStart
    jsr tokenIn
    bne :+
    lda #errMissingSemicolon
    jsr parserError
    bra L2
:   lda #<tlStatementListNotAllowed
    ldx #>tlStatementListNotAllowed
    jsr tokenIn
    bne :+
    lda #errUnexpectedToken
    jsr parserError
    jsr getToken                ; Skip it
    bra L2
:   lda parserToken
    cmp #tcSemicolon
    bne :+
    jsr getToken
    bra L2
    ; parseStatement handles the $Expect directives
:   cmp #tcEXPECTWARN
    beq L2
    cmp #tcEXPECTERROR
    beq L2
    lda #1
    sta stopList

L2: jsr popQ
    stq ptr1
    jsr isQZero                 ; An empty statement isn't linked. It would
    beq L6                      ; become lastStmt and lose the next one.
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

L6: lda stopList
    bne L5
    ldz #terminatorOffset
    nop
    lda (stackPointer),z
    cmp parserToken
    beq L5
    lda parserToken
    cmp #tcEndOfFile
    beq L5
    lda parserToken
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

