;
; icodeVar.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "icode.inc"
.include "asmlib.inc"

.export icodeVar

.import operand1, icodeWriteInstruction, frameOf

; This routine writes PSH with a variable operand. On the runtime stack,
; bottom to top: the operand's kind (IC_VDR, IC_VDW, IC_VVR or IC_VVW),
; the variable's type, its level and its offset. A level 1 offset counts
; from the program's first slot. It is written relative to the first slot
; of the frame it is in, with the frame's number (icodeFrames.s).
.proc icodeVar
    jsr popA            ; offset
    sta operand1+3

    jsr popA            ; level
    sta operand1+2

    jsr popA            ; type
    sta operand1+1

    jsr popA            ; operation
    sta operand1

    lda #0
    sta operand1+4      ; the frame
    lda operand1+2
    cmp #1
    bne :+
    lda operand1+3
    jsr frameOf
    sta operand1+3
    stx operand1+4

:   lda #IC_PSH
    jsr icodeWriteInstruction
    
    rts
.endproc
