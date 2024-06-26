;
; int16.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export absInt16, swapInt16, isNegInt16, invertInt16, signExtend16To32

; Z flag is non-zero if number is negative
.proc isNegInt16
    lda intOp1 + 1
    and #$80
    rts
.endproc

; Invert intOp1 by applying the two's complement.
.proc invertInt16
    ; invert the bits
    lda intOp1
    eor #$ff
    sta intOp1
    lda intOp1 + 1
    eor #$ff
    sta intOp1 + 1
    ; add 1
    clc
    lda intOp1
    adc #1
    sta intOp1
    lda intOp1 + 1
    adc #0
    sta intOp1 + 1
    rts
.endproc

; Absolute value of intOp1
.proc absInt16
    jsr isNegInt16
    beq done
    jmp invertInt16
done:
    rts
.endproc

; Swap intOp1 and intOp2
.proc swapInt16
    lda intOp1
    pha
    lda intOp1 + 1
    pha
    lda intOp2
    sta intOp1
    lda intOp2 + 1
    sta intOp1 + 1
    pla
    sta intOp2 + 1
    pla
    sta intOp2
    rts
.endproc

.proc signExtend16To32
    ldx #0
    lda intOp1 + 1
    and #$80
    beq L1
    ldx #$ff
L1:
    stx intOp2
    stx intOp2 + 1
    rts
.endproc
