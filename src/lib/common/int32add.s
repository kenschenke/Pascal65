;
; int32add.s
; Ken Schenke (kenschenke@gmail.com)
; 
; 32-bit integer addition
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1, intOp2, intOp32
.endif
.export addInt32

; Add intOpt1/intOp2 to intOp32, storing the result in intOp1/intOp2
;    intOp1 contains the lower 2 bytes of the first operand and
;    intOp2 contains the upper 2 bytes.
;    intOp32 contains the other operand.
.proc addInt32
    clc
    lda intOp1
    adc intOp32
    sta intOp1
    lda intOp1 + 1
    adc intOp32 + 1
    sta intOp1 + 1
    lda intOp2
    adc intOp32 + 2
    sta intOp2
    lda intOp2 + 1
    adc intOp32 + 3
    sta intOp2 + 1
    rts
.endproc

