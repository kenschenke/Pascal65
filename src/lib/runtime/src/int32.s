;
; int32.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Placeholder for 32-bit integer operations

.include "runtime.inc"

.export absInt32, invertInt32, isNegInt32, swapInt32

.data

tensTable32:
    .dword 1000000000
    .dword 100000000
    .dword 10000000
    .dword 1000000
    .dword 100000
    .dword 10000
    .dword 1000
    .dword 100
    .dword 10
    .dword 1

.code

; Absolute value of intOp1/intOp2
.proc absInt32
    jsr isNegInt32
    beq done
    jmp invertInt32
done:
    rts
.endproc

; Z flag is non-zero if number is negative
.proc isNegInt32
    lda intOp2 + 1
    and #$80
    rts
.endproc

; Invert intOp1/intOp2 by applying the two's complement.
.proc invertInt32
    ; invert the bits
    lda intOp1
    eor #$ff
    sta intOp1
    lda intOp1 + 1
    eor #$ff
    sta intOp1 + 1
    lda intOp2
    eor #$ff
    sta intOp2
    lda intOp2 + 1
    eor #$ff
    sta intOp2 + 1
    ; add 1
    ldx #0
:   inc intOp1,x
    bne L1
    inx
    cpx #4
    bne :-
L1:
    rts
.endproc

; Swap intOp1/intOp2 and intOp32
.proc swapInt32
    ldx #0
L1:
    lda intOp1,x
    pha
    inx
    cpx #4
    bne L1
    ldx #0
L2:
    lda intOp32,x
    sta intOp1,x
    inx
    cpx #4
    bne L2
    ldx #3
L3:
    pla
    sta intOp32,x
    dex
    bpl L3
    rts
.endproc
