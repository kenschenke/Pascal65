;
; int8sub.s
; Ken Schenke (kenschenke@gmail.com)
; 
; 8-bit integer subtraction
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
.export subInt8

; Subtract intOp2 from intOp1, storing the result in intOp1
.proc subInt8
    sec
    lda intOp1
    sbc intOp2
    sta intOp1
    rts
.endproc

