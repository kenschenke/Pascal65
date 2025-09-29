.include "tokenizer.inc"
.include "parser.inc"
.include "error.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export runTest1

.import errorNum, errorCount, errorLine, initTokenizer, initParser

.bss

tokenHeap: .res 4
astRoot: .res 4

.data

sourceFn: .asciiz "test1.pas"
test1Msg: .asciiz "Running Test 1 "
tokenMsg: .asciiz "Expected token error"
countMsg: .asciiz "Expected one error"
lineNumMsg: .asciiz "Unexpected line number"
passMsg: .asciiz "Passed"

.code

.proc runTest1
    lda #0
    sta errorNum
    sta errorCount

    ldx #0
:   lda test1Msg,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   jsr initTokenizer
    lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    stq tokenHeap

    jsr initParser
    ldq tokenHeap
    jsr parse
    stq astRoot

    ldq tokenHeap
    jsr heapFree

    rts

;     lda errorNum
;     cmp #errUnexpectedToken
;     beq L1
;     ; Error is not what was expected
;     ldx #0
; :   lda tokenMsg,x
;     beq :+
;     jsr CHROUT
;     inx
;     bne :-
; :   lda #13
;     jmp CHROUT

; L1: lda errorCount
;     cmp #1
;     beq L2
;     ; Error count is not what was expected
;     ldx #0
; :   lda countMsg,x
;     beq :+
;     jsr CHROUT
;     inx
;     bne :-
; :   lda #13
;     jmp CHROUT

; L2: lda errorLine
;     cmp #3
;     beq :+
;     bra L3
; :   lda errorLine+1
;     cmp #0
;     beq L4

;     ; Line number is wrong
; L3: ldx #0
; :   lda lineNumMsg,x
;     beq :+
;     jsr CHROUT
;     inx
;     bne :-
; :   lda #13
;     jmp CHROUT

;     ; It passed
; L4: ldx #0
; :   lda passMsg,x
;     beq :+
;     jsr CHROUT
;     inx
;     bne :-
; :   lda #13
;     jmp CHROUT
.endproc