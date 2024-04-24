;
; invertbitwise.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine performs a bitwise left shift.
; The operand is expected on the runtime stack.
; The result is left at the top of the stack.

; Inputs:
;    A - data type of operand

.include "runtime.inc"
.include "types.inc"

.export invertBitwise

.import onesComplementInt8, onesComplementInt16, onesComplementInt32, popToIntOp1

.proc invertBitwise
    cmp #TYPE_BYTE
    beq int8
    cmp #TYPE_SHORTINT
    beq int8
    cmp #TYPE_WORD
    beq int16
    cmp #TYPE_INTEGER
    beq int16
    cmp #TYPE_CARDINAL
    beq int32
    cmp #TYPE_LONGINT
    beq int32
    rts
.endproc

.proc int8
    jsr rtPopToIntOp1
    jsr onesComplementInt8
    jmp rtPushFromIntOp1
.endproc

.proc int16
    jsr rtPopToIntOp1
    jsr onesComplementInt16
    jmp rtPushFromIntOp1
.endproc

.proc int32
    jsr rtPopToIntOp1And2
    jsr onesComplementInt32
    jmp rtPushFromIntOp1And2
.endproc
