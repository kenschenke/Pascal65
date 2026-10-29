;
; main.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Pre-compiled header test entry point

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "meminfo.inc"

CH_LOWERCASE = 14

.segment "ENTRY"

.import initLib, runTests, logError, initMemInfo

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

    ; Initialize compiler warnings
    lda #<logError
    ldx #>logError
    jsr initCompilerWarnings

    lda #<onExit
    sta exitHandler
    lda #>onExit
    sta exitHandler+1

    ; Show the heap before the tests. Only the error messages should be on it.
    jsr initMemInfo
    jsr heapSummary

    jsr runTests

    ; Show the heap again, followed by a report of the allocated blocks.
    ; If the summary matches the first one and the report lists only the
    ; error messages, the tests leaked nothing.
    jsr initMemInfo
    jsr heapSummary
    lda #0
    jsr heapReport
    rts

onExit:
    lda #13
    jsr CHROUT
    rts
