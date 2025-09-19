;
; main.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tokenizer tests entry point

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "error.inc"

CH_LOWERCASE = 14

.segment "ENTRY"

.import initLib, initTokenizer, runTest1, runTest2, runTest3
.import runTest4, runTest5, logError

main:
    ; Set alphabet to upper and lower case
    lda #CH_LOWERCASE
    jsr CHROUT

    ; Disable BASIC ROM
    lda $01
    and #$f8
    ora #$06
    sta $01

    ; Load the library
    jsr initLib

    ; Initialize the runtime stack
    jsr stackInit

    ; Initialize the memory heap
    jsr initMemHeap

    ; Initialize error handling
    lda #<logError
    ldx #>logError
    jsr initCompilerErrors

    ; Load the tokenizer
    jsr initTokenizer

    ; Run the first test
    jsr runTest1

    ; Run the second test
    jsr runTest2

    ; Run the third test
    jsr runTest3

    ; Run the fourth test
    jsr runTest4

    ; Run the fifth test
    jsr runTest5

    rts
