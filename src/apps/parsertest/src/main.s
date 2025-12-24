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
.include "meminfo.inc"
.include "zeropage.inc"

CH_LOWERCASE = 14

.segment "ENTRY"

.import initLib, runTests, runErrorTests
.import logError, initMemInfo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.import binaryTest
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

    lda #<onExit
    sta exitHandler
    lda #>onExit
    sta exitHandler+1

    jsr initMemInfo
    jsr heapSummary

    ; Run parser tests
    jsr runTests

    jsr initMemInfo
    jsr heapSummary
    jsr heapReport

    ; Run parser error handling tests
    ; jsr runErrorTests

    rts

onExit:
    lda #13
    jsr CHROUT
    rts
