;
; runtests.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runTests routine
;
; Tests:
;    1: Scalar variable assignments
;    2: Expressions
;    3: Scalar variable initial values
;    4: Array literals
;    5: Routines
;    6: Arrays
;    7: Records
;    8: Pointers
;    9. Strings
;   10. Standard routines
;   11. Files
;   12. Read, Readln, Readstr
;   13. Write, Writeln, Writestr
;   14. Pass by reference
;   15. Case statement
;   16. Enumerations
;   17. Forward declarations
;   18. Type Casts

.include "asmlib.inc"
.include "cbm_kernal.inc"

.export runTests

.import runTest, logError, printLine

NUM_TESTS = 18

.bss

testNum: .res 2

.data

strRunning: .asciiz "Running type checking tests"

.code

.proc runTests
    ; Initialize error handling
    lda #<logError
    ldx #>logError
    jsr initCompilerErrors

    ; Initialize compiler warnings
    lda #<logError
    ldx #>logError
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
    jsr runTest

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
