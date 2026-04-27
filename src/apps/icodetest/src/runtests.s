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
;    4: While loops
;    5: Repeat..Until loop
;    6: For loops
;    7: Case statement
;    8: Arrays
;    9: Strings
;   10: Records
;   11. Pointers
;   12. Standard routines
;   13. Routines
;   14. Files
;   15. Array literals
;   16. Read, Readln, Readstr
;   17. Write, Writeln, Writestr
;   18. If, Then, Else

.export runTests

.import runTest

NUM_TESTS = 18

.bss

testNum: .res 2

.code

.proc runTests
    ; Start with test 1
    lda #1
    sta testNum
    lda #0
    sta testNum+1

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

L3: rts
.endproc
