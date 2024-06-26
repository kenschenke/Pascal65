;
; int32sub.s
; Ken Schenke (kenschenke@gmail.com)
; 
; 32-bit integer subtraction
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
.export subInt32

; Subtract intOp32 from intOp1/intOp2, storing the result in intOp1/intOp2
.proc subInt32
    sec
    lda intOp1
    sbc intOp32
    sta intOp1
    lda intOp1 + 1
    sbc intOp32 + 1
    sta intOp1 + 1
    lda intOp2
    sbc intOp32 + 2
    sta intOp2
    lda intOp2 + 1
    sbc intOp32 + 3
    sta intOp2 + 1
    rts
.endproc

