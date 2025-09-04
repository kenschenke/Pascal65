;
; getticks.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; GetTicks for Time Unit

.include "runtime.inc"
.include "c64.inc"
.include "4510macros.inc"

.p4510

.export getTicks

.import returnVal, startTimer

.proc getTicks
    jsr startTimer
    lda #$ff
    tax
    tay
    taz

L1: bit CIA2_TA
    bvs L2
    bpl L1

L2: sbcq CIA2_TA
    sty sreg
    stz sreg+1
    jmp rtLibReturnValue
.endproc
