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
;
; Only the low 16 bits of ptr1 advance, so the memory must not cross a 64k
; boundary. ptr1+1 is changed and Z is clobbered. A count of zero fills
; nothing.
.proc memFill
    ldz #0
    cpy #0
    beq L2

    ; Whole pages
L1: nop
    sta (ptr1),z
    inz
    bne L1
    inc ptr1+1
    dey
    bne L1

    ; The rest
L2: cpx #0
    beq DN
L3: nop
    sta (ptr1),z
    inz
    dex
    bne L3
DN: rts
.endproc
