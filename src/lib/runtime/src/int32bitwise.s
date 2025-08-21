;
; int32bitwise.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Bitwise operations for 32-bit integers

.include "runtime.inc"

.export andInt32, orInt32, xorInt32, onesComplementInt32, lshiftInt32, rshiftInt32

; Perform AND operation on two 32-bit numbers in intOp1/intOp2 and intOp32
; Result is left in intOp1/intOp2
.proc andInt32
    ldx #3
:   lda intOp1,x
    and intOp32,x
    sta intOp1,x
    dex
    bpl :-
    rts
.endproc

; Perform OR operation on two 32-bit numbers in intOp1/intOp2 and intOp32
; Result is left in intOp1/intOp2
.proc orInt32
    ldx #3
:   lda intOp1,x
    ora intOp32,x
    sta intOp1,x
    dex
    bpl :-
    rts
.endproc

; Peform 1's complement (invert bits) on the 32-bit number in intOp1/intOp2
; Result is left in intOp1/intOp2
.proc onesComplementInt32
    ldx #3
:   lda intOp1,x
    eor #$ff
    sta intOp1,x
    dex
    bpl :-
    rts
.endproc

; Performs left shift on the 32-bit number in intOp1/intOp2
; Number of shifts is passed in A
; Result is left in intOp1/intOp2
.proc lshiftInt32
    cmp #0          ; Is A 0?
    beq DN          ; Nothing to do
    cmp #32         ; is A >= 32?
    bcs DN          ; branch if so
    tax
:   asl intOp1
    rol intOp1 + 1
    rol intOp2
    rol intOp2 + 1
    dex
    bne :-
DN: rts
.endproc

; Performs right shift on the 32-bit integer in intOp1/intOp2
; Number of shifts is passed in A
; Result is left in intOp1/intOp2
.proc rshiftInt32
    cmp #0          ; Is A 0?
    beq DN          ; Nothing to do
    cmp #32         ; is A >= 32
    bcs DN          ; branch if so
    tax
:   lsr intOp2 + 1
    ror intOp2
    ror intOp1 + 1
    ror intOp1
    dex
    bne :-
DN: rts
.endproc

; Perform XOR operation on two 32-bit numbers in intOp1/intOp2 and intOp32
; Result is left in intOp1/intOp2
.proc xorInt32
    ldx #3
:   lda intOp1,x
    eor intOp32,x
    sta intOp1,x
    dex
    bpl :-
    rts
.endproc

