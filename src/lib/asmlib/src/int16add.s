;
; int16add.s
; Ken Schenke (kenschenke@gmail.com)
; 
; 16-bit integer addition
; 
; Copyright (c) 2024-2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "zeropage.inc"

.export addInt16

; Add intOp1 and intOp2, storing the result in intOp1
.proc addInt16
    clc
    lda intOp1
    adc intOp2
    sta intOp1
    lda intOp1 + 1
    adc intOp2 + 1
    sta intOp1 + 1
    rts
.endproc
