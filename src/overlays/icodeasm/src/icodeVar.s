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

.import operand1, icodeWriteInstruction

.proc icodeVar
    jsr popA            ; offset
    sta operand1+3

    jsr popA            ; level
    sta operand1+2

    jsr popA            ; type
    sta operand1+1

    jsr popA            ; operation
    sta operand1

    lda #IC_PSH
    jsr icodeWriteInstruction
    
    rts
.endproc
