;
; main.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Type checker tests entry point

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "error.inc"
.include "meminfo.inc"
.include "zeropage.inc"

CH_LOWERCASE = 14

.segment "ENTRY"

.import initLib, runTest, runTests, runErrorTests
.import logError, initMemInfo

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

    ; Run a test of the system unit
    ; lda #0
    ; tax
    ; sec
    ; jsr runTest

    ; Run type checker tests
    jsr runTests

    ; Run the unit test
    ; lda #8
    ; ldx #0
    ; sec
    ; jsr runTest

    jsr initMemInfo
    jsr heapSummary
    jsr heapReport

    rts

onExit:
    lda #13
    jsr CHROUT
    rts
