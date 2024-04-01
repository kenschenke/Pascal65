;
; int8.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Common assembly routines for 8-bit integers
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Placeholder for 8-bit integer operations

.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1, intOp2
.endif

.export absInt8, invertInt8, isNegInt8, signExtend8To16, signExtend8To32, swapInt8

; Absolute value of intOp1
.proc absInt8
    jsr isNegInt8
    bne invertInt8
    rts
.endproc

; Z flag is non-zero if number is negative
.proc isNegInt8
    lda intOp1
    and #$80
    rts
.endproc

; Invert intOp1 by applying the two's complement.
.proc invertInt8
    ; invert the bits
    lda intOp1
    eor #$ff
    clc
    adc #1
    sta intOp1
    rts
.endproc

.proc signExtend8To16
    ldx #0
    lda intOp1
    and #$80
    beq :+
    ldx #$ff
:   stx intOp1 + 1
    rts
.endproc

.proc signExtend8To32
    ldx #0
    lda intOp1
    and #$80
    beq L1
    ldx #$ff
L1:
    txa
    ldx #2
L2:
    sta intOp1+1,x
    dex
    bpl L2
    rts
.endproc

; Swap intOp1 and intOp2
.proc swapInt8
    lda intOp1
    pha
    lda intOp2
    sta intOp1
    pla
    sta intOp2
    rts
.endproc
