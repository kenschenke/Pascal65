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

.include "zeropage.inc"
.include "4510macros.inc"

.export subInt32

; Subtract intOp32 from intOp1/intOp2, storing the result in intOp1/intOp2
.proc subInt32
    sec
    ldq intOp1
    sbcq intOp32
    stq intOp1
    rts
.endproc

