;
; int32sqr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Calculate square of two 32-bit integers
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1, intOp32
.endif

.import multInt32
.export int32Sqr

; Square the 32-bit integer in intOp1/intOp2, leaving the result in intOp1/intOp2
.proc int32Sqr
    ldx #3
:   lda intOp1,x
    sta intOp32,x
    dex
    bpl :-
    jmp multInt32
.endproc
