.include "tokenizer.inc"
.include "error.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export runTest3

.import errorNum, errorCount, errorLine

.data

sourceFn: .asciiz "test3.pas"
test3Msg: .asciiz "Running Test 3 "
tokenMsg: .asciiz "Expected string error"
countMsg: .asciiz "Expected one error"
lineNumMsg: .asciiz "Unexpected line number"
passMsg: .asciiz "Passed"

.code

.proc runTest3
    lda #0
    sta errorNum
    sta errorCount

    ldx #0
:   lda test3Msg,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    jsr freeMemBuf

    lda errorNum
    cmp #errMissingQuote
    beq L1
    ; Error is not what was expected
    ldx #0
:   lda tokenMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT

L1: lda errorCount
    cmp #1
    beq L2
    ; Error count is not what was expected
    ldx #0
:   lda countMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT

L2: lda errorLine
    cmp #4
    beq :+
    bra L3
:   lda errorLine+1
    cmp #0
    beq L4

    ; Line number is wrong
L3: ldx #0
:   lda lineNumMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT

    ; It passed
L4: ldx #0
:   lda passMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT
.endproc