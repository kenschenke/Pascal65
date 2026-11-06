;
; main.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parser tests entry point

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "error.inc"
.include "zeropage.inc"

CH_LOWERCASE = 14

.include "poisonbss.inc"

.segment "ENTRY"

.import initLib, runTests, runErrorTests, runLineTest
.import logError

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.import binaryTest
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.import testInit, testPass, testFail, testMemCheck, testLeakCheck

main:
    poisonBss                   ; Must run before anything writes BSS

    jsr testInit

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

    ; Make sure asmlib catches double frees
    jsr testMemCheck

    ; Initialize error handling
    lda #<logError
    ldx #>logError
    jsr initCompilerErrors

    ; Initialize compiler warnings
    lda #<logError
    ldx #>logError
    jsr initCompilerWarnings

    lda #<onExit
    sta exitHandler
    lda #>onExit
    sta exitHandler+1

    ; Run parser tests
    jsr runTests

    ; Run parser error handling tests
    jsr runErrorTests

    ; Check the declarations' line numbers
    jsr runLineTest

    ; Everything the tests allocated must be freed
    jsr testLeakCheck
    bcc :+
    jmp testFail
:

    jsr testPass
    rts

onExit:
    lda #13
    jsr CHROUT
    jmp testFail
