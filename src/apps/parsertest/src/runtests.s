;
; runtests.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runtests routine
; Tests:
;    1: Scalar variable declarations
;    2: Uses statement
;    3: Type definitions
;    4: Constants
;    5: Initial values
;    6: If-then statements
;    7: Loops
;    8: Case statement
;    9: Arrays
;   10: Records
;   11: Functions and procedures
;   12: Pointers
;   13: Operators and expressions
;   14: Unit
;   15: Array literals

.export runTests

.import runTest
.import heapWalk

NUM_TESTS = 15

.bss

testNum: .res 2

.code

.proc runTests
    ; jsr heapWalk

    ; Start with test 1
    lda #1
    sta testNum
    lda #0
    sta testNum+1

L1: lda testNum
    ldx testNum+1
    jsr runTest
    ; jsr heapWalk

    lda testNum
    cmp #.LOBYTE(NUM_TESTS)
    bne L2
    lda testNum+1
    cmp #.HIBYTE(NUM_TESTS)
    beq L3

L2: inc testNum
    bne :+
    inc testNum+1
:   bra L1

L3: ; jsr heapWalk
    rts
.endproc
