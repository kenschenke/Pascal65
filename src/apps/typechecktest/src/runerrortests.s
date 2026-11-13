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
;    3: Procedure call precision loss warnings
;    4: Comparison warnings and errors
;    5: Write, Writeln and WriteStr field width and precision
;    6: For loop control variables
;    7: SetLength, Length, Low, and High
;    8: Array assignment, parameters, return types and literals
;    9: Forward declarations that don't match
;   10: ReadStr and files of dynamic arrays
;   11: Errors and warnings are reported in their own file
;   12: Unary minus of non-literals
;   13: Subrange operands
;   14: If, While, Repeat and Case statements
;   15: Standard routines
;   16: Expressions
;   17: Routine calls and parameters
;   18: Read, Readln, Write, Writeln and WriteStr
;   19: Declarations, initial values, casts and forwards

.include "asmlib.inc"
.include "cbm_kernal.inc"

.export runErrorTests

.import runErrorTest, logExpectedWarning, logExpectedError, printLine

NUM_TESTS = 19

; Only some of the tests can be run:
; make test TESTSEL="-D FIRST_ERROR_TEST=n -D LAST_ERROR_TEST=m"
.ifndef FIRST_ERROR_TEST
FIRST_ERROR_TEST = 1
.endif
.ifndef LAST_ERROR_TEST
LAST_ERROR_TEST = NUM_TESTS
.endif

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

    lda #13
    jsr CHROUT
    lda #<strRunning
    ldx #>strRunning
    jsr printLine
    lda #13
    jsr CHROUT
    jsr CHROUT

.if ::FIRST_ERROR_TEST <= ::LAST_ERROR_TEST
    lda #.LOBYTE(FIRST_ERROR_TEST)
    sta testNum
    lda #.HIBYTE(FIRST_ERROR_TEST)
    sta testNum+1

L1: lda testNum
    ldx testNum+1
    clc
    jsr runErrorTest

    lda testNum
    cmp #.LOBYTE(LAST_ERROR_TEST)
    bne L2
    lda testNum+1
    cmp #.HIBYTE(LAST_ERROR_TEST)
    beq L3

L2: inc testNum
    bne L1
    inc testNum+1
    bra L1
.endif

L3: lda #13
    jsr CHROUT
    rts
.endproc
