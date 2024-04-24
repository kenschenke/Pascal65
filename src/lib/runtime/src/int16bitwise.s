;
; int16bitwise.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Bitwise operations for 16-bit integers

.include "runtime.inc"

.export andInt16, orInt16, onesComplementInt16, lshiftInt16, rshiftInt16

; Perform AND operation on two 16-bit numbers in intOp1 and intOp2
; Result is left in intOp1
.proc andInt16
    ldx #1
:   lda intOp1,x
    and intOp2,x
    sta intOp1,x
    dex
    bpl :-
    rts
.endproc

; Perform OR operation on two 16-bit numbers in intOp1 and intOp2
; Result is left in intOp1
.proc orInt16
    ldx #1
:   lda intOp1,x
    ora intOp2,x
    sta intOp1,x
    dex
    bpl :-
    rts
.endproc

; Peform 1's complement (invert bits) on the 16-bit number in intOp1
; Result is left in intOp1
.proc onesComplementInt16
    ldx #1
:   lda intOp1,x
    eor #$ff
    sta intOp1,x
    dex
    bpl :-
    rts
.endproc

; Performs left shift on the 16-bit number in intOp1
; Number of shifts is passed in A
; Result is left in intOp1
.proc lshiftInt16
    cmp #0          ; Is A 0?
    beq DN          ; Nothing to do
    cmp #16         ; is A >= 16?
    bcs DN          ; branch if so
    tax
:   asl intOp1
    rol intOp1 + 1
    dex
    bne :-
DN: rts
.endproc

; Performs right shift on the 16-bit integer in intOp1
; Number of shifts is passed in A
; Result is left in intOp1
.proc rshiftInt16
    cmp #0          ; Is A 0?
    beq DN          ; Nothing to do
    cmp #16         ; is A >= 16
    bcs DN          ; branch if so
    tax
:   lsr intOp1 + 1
    ror intOp1
    dex
    bne :-
DN: rts
.endproc
