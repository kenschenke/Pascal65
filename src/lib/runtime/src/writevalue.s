;
; writevalue.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

; This routine is used by write, writeln, and writestr to write a value.
; It expects the value to be at the top of the runtime stack
;
; Inputs:
;    A - data type
;    X - value width (for left padding)

.include "runtime.inc"
.include "types.inc"

.export writeValue

.import writeBool, writeChar, writeUint8, writeInt8, writeUint16, writeInt16
.import writeUint32, writeInt32, printz, writeString, heapFree, pusheax

width: .res 1

.proc writeValue
    stx width           ; save width

    cmp #TYPE_BOOLEAN
    beq BOOL
    cmp #TYPE_CHARACTER
    beq CHAR
    cmp #TYPE_BYTE
    beq UINT8
    cmp #TYPE_SHORTINT
    beq SINT8
    cmp #TYPE_WORD
    beq UINT16
    cmp #TYPE_INTEGER
    beq SINT16
    cmp #TYPE_CARDINAL
    beq UINT32
    cmp #TYPE_LONGINT
    beq SINT32
    cmp #TYPE_STRING_VAR
    beq STRVAR
    cmp #TYPE_STRING_OBJ
    beq STROBJ

BOOL:
    jsr rtPopEax
    ldx width
    jmp writeBool

CHAR:
    jsr rtPopEax
    ldx width
    jmp writeChar

STRVAR:
    jsr rtPopEax
    ldy width
    jmp writeString

STROBJ:
    jsr rtPopEax
    sta sreg
    stx sreg + 1
    pha
    txa
    pha
    lda sreg
    ldx sreg + 1
    jsr pusheax
    jsr STRVAR
    pla
    tax
    pla
    jmp heapFree

UINT8:
    jsr rtPopToIntOp1
    lda width
    jsr writeUint8
    clc
    bcc writeIntBuf

SINT8:
    jsr rtPopToIntOp1
    lda width
    jsr writeInt8
    clc
    bcc writeIntBuf

UINT16:
    jsr rtPopToIntOp1
    lda width
    jsr writeUint16
    clc
    bcc writeIntBuf

SINT16:
    jsr rtPopToIntOp1
    lda width
    jsr writeInt16
    clc
    bcc writeIntBuf

UINT32:
    jsr rtPopToIntOp1And2
    lda width
    jsr writeUint32
    clc
    bcc writeIntBuf

SINT32:
    jsr rtPopToIntOp1And2
    lda width
    jsr writeInt32
    clc
    bcc writeIntBuf

writeIntBuf:
    lda intPtr
    ldx intPtr + 1
    jmp printz
.endproc

