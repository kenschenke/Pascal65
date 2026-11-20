;
; runtests.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runTests routine
;
; Tests:
;    1: A unit that uses only System
;    2: A unit that uses a unit and a library, and a unit in its
;       implementation
;    3: TpuCrc, the unit tests 4 and 5 change
;    4: TpuCrc with only its implementation changed
;    5: TpuCrc with its interface changed
;    6: A unit that uses test 1, loaded from its TPU
;    7: A unit that uses a unit loaded from its TPU (test 2's)
;    8: A unit that uses a unit with only a TPU (test 5's)
;    9: A program that uses units loaded from their TPUs
;   10: Routine addresses in a unit loaded from its TPU

.export runTests

.import runTest, clearCrcs

NUM_TESTS = 10

; Only some of the tests can be run:
; make test TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m"
.ifndef FIRST_TEST
FIRST_TEST = 1
.endif
.ifndef LAST_TEST
LAST_TEST = NUM_TESTS
.endif

.bss

testNum: .res 2

.code

.proc runTests
    jsr clearCrcs
.if ::FIRST_TEST <= ::LAST_TEST
    lda #.LOBYTE(FIRST_TEST)
    sta testNum
    lda #.HIBYTE(FIRST_TEST)
    sta testNum+1

L1: lda testNum
    ldx testNum+1
    jsr runTest

    lda testNum
    cmp #.LOBYTE(LAST_TEST)
    bne L2
    lda testNum+1
    cmp #.HIBYTE(LAST_TEST)
    beq L3

L2: inc testNum
    bne L1
    inc testNum+1
    bra L1

L3:
.endif
    rts
.endproc
