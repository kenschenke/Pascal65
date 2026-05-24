;
; readInstruction.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; readInstruction routine

.include "icode.inc"

.export readInstruction, instruction

.import readOperand1, readOperand2, readOperand3

.bss

instruction: .res 1

.code

; Read the instruction and its operand(s) if any.
.proc readInstruction
    bit #IC_MASK_TRINARY
    beq :+
    jsr readOperand1
    jsr readOperand2
    jsr readOperand3
    rts

:   bit #IC_MASK_BINARY
    beq :+
    jsr readOperand1
    jsr readOperand2
    rts

:   bit #IC_MASK_UNARY
    beq :+
    jsr readOperand1

:   rts
.endproc
