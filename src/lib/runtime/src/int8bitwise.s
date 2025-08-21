;
; int8bitwise.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Bitwise operations for 8-bit integers

.include "runtime.inc"

.export andInt8, orInt8, xorInt8, onesComplementInt8, lshiftInt8, rshiftInt8

; Perform AND operation on two 8-bit numbers in intOp1 and intOp2
; Result is left in intOp1
.proc andInt8
    lda intOp1
    and intOp2
    sta intOp1
    rts
.endproc

; Perform OR operation on two 8-bit numbers in intOp1 and intOp2
; Result is left in intOp1
.proc orInt8
    lda intOp1
    ora intOp2
    sta intOp1
    rts
.endproc

; Peform 1's complement (invert bits) on the 8-bit number in intOp1
; Result is left in intOp1
.proc onesComplementInt8
    lda intOp1
    eor #$ff
    sta intOp1
    rts
.endproc

; Performs left shift on the 8-bit number in intOp1
; Number of shifts is passed in A
; Result is left in intOp1
.proc lshiftInt8
    cmp #0          ; Is A 0?
    beq DN          ; Nothing to do
    cmp #8          ; is A >= 8?
    bcs DN          ; branch if so
    tax
:   asl intOp1
    dex
    bne :-
DN: rts
.endproc

; Performs right shift on the 8-bit integer in intOp1
; Number of shifts is passed in A
; Result is left in intOp1
.proc rshiftInt8
    cmp #0          ; Is A 0?
    beq DN          ; Nothing to do
    cmp #8          ; is A >= 8
    bcs DN          ; branch if so
    tax
:   lsr intOp1
    dex
    bne :-
DN: rts
.endproc

; Perform XOR operation on two 8-bit numbers in intOp1 and intOp2
; Result is left in intOp1
.proc xorInt8
    lda intOp1
    eor intOp2
    sta intOp1
    rts
.endproc
