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

.bss

errorTestsFailed: .res 1    ; Non-zero if an error test failed

.segment "ENTRY"

.import initLib, runTests, runErrorTests, runLineTest, runDirTest
.import logError

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.import binaryTest
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.import testInit, testPass, testFail, testMemCheck, testLeakCheck
.ifdef COVERAGE
; With COVERAGE defined it runs an instrumented parser overlay and saves the
; coverage map to the disk once every test passes (make coverage, see
; the Makefile).
.import covInit, covSave
.endif

main:
    poisonBss                   ; Must run before anything writes BSS

    jsr testInit
.ifdef COVERAGE
    jsr covInit
.endif

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
    ; A failed error test doesn't stop the other tests or the leak check
    jsr runErrorTests
    lda #0
    rol a
    sta errorTestsFailed

    ; Check the declarations' line numbers
    jsr runLineTest

    ; Check the directives the parser keeps for the compiler
    jsr runDirTest

    ; Everything the tests allocated must be freed
    jsr testLeakCheck
    bcc :+
    jmp testFail
:   lda errorTestsFailed
    beq :+
    jmp testFail
:

.ifdef COVERAGE
    jsr covSave
.endif
    jsr testPass
    rts

onExit:
    lda #13
    jsr CHROUT
    jmp testFail
