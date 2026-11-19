;
; main.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; TPU tests entry point

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

CH_LOWERCASE = 14

.include "poisonbss.inc"

.segment "ENTRY"

.import initLib, runTests, logError, printMilliseconds, printLine

.export totalTicks

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

    jsr initLib
    jsr stackInit
    jsr initMemHeap

    ; Make sure asmlib catches double frees
    jsr testMemCheck

    lda #<logError
    ldx #>logError
    jsr initCompilerErrors

    lda #<logError
    ldx #>logError
    jsr initCompilerWarnings

    lda #<onExit
    sta exitHandler
    lda #>onExit
    sta exitHandler+1

    lda #0
    tax
    tay
    taz
    stq totalTicks

    jsr runTests

    ; Everything the tests allocated must be freed
    jsr testLeakCheck
    bcc :+
    jmp testFail
:

    lda #<strTotal
    ldx #>strTotal
    jsr printLine

    ldq totalTicks
    stq intOp1
    jsr printMilliseconds
    lda #13
    jsr CHROUT

    jsr testPass
    rts

onExit:
    lda #13
    jsr CHROUT
    jmp testFail

.bss

totalTicks: .res 4

.data

strTotal: .asciiz "total:"
