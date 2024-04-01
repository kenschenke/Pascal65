;
; int8add.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Add 8-bit integers
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1, intOp2
.endif
.export addInt8

; Add intOp1 and intOp2, storing the result in intOp1
.proc addInt8
    clc
    lda intOp1
    adc intOp2
    sta intOp1
    rts
.endproc

