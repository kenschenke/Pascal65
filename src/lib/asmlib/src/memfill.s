;
; memfill.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; memFill routine

.include "zeropage.inc"
.include "4510macros.inc"

.export memFill

; Pointer to memory in ptr1
; Byte to fill in A
; LB of count in X
; HB of count in Y
.proc memFill
    sta tmp1
L1: ; See if the high byte of the count is zero
    cpy #0
    bne L2
    txa
    taz
    dez
    bra L3
L2: ldz #$ff
L3: lda tmp1
L4: nop
    sta (ptr1),z
    dez
    bne L4
    nop
    sta (ptr1),z

    ; If the high byte of the count is zero, done!
    cpy #0
    beq DN

    ; increment ptr1
    inc ptr1+1
    dey
    bra L1
DN: rts
.endproc
