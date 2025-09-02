;
; int16.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; invertInt16 routine

.include "zeropage.inc"

.export invertInt16

; Invert intOp1 by applying the two's complement
.proc invertInt16
    ; invert the bits
    lda intOp1
    eor #$ff
    sta intOp1
    lda intOp1+1
    eor #$ff
    sta intOp1+1
    ; add 1
    clc
    lda intOp1
    adc #0
    sta intOp1
    lda intOp1+1
    adc #0
    sta intOp1+1
    rts
.endproc
