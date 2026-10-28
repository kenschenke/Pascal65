;
; runerrortests.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runErrorTests routine
;
; Tests:
;    1: Assignment type cast warnings
;    2: Procedure call type cast warnings

.include "asmlib.inc"
.include "cbm_kernal.inc"

.export runErrorTests

.import runErrorTest, logExpectedWarning, logExpectedError, printLine

NUM_TESTS = 4

.bss

testNum: .res 2

.data

strRunning: .asciiz "Running type checking error tests"

.code

.proc runErrorTests
    ; Initialize error handling
    lda #<logExpectedError
    ldx #>logExpectedError
    jsr initCompilerErrors

    ; Initialize compiler warnings
    lda #<logExpectedWarning
    ldx #>logExpectedWarning
    jsr initCompilerWarnings

    ; Start with test 1
    lda #1
    sta testNum
    lda #0
    sta testNum+1

    lda #13
    jsr CHROUT
    lda #<strRunning
    ldx #>strRunning
    jsr printLine
    lda #13
    jsr CHROUT
    jsr CHROUT

L1: lda testNum
    ldx testNum+1
    clc
    jsr runErrorTest

    lda testNum
    cmp #.LOBYTE(NUM_TESTS)
    bne L2
    lda testNum+1
    cmp #.HIBYTE(NUM_TESTS)
    beq L3

L2: inc testNum
    bne L1
    inc testNum+1
    bra L1

L3: lda #13
    jsr CHROUT
    rts
.endproc
