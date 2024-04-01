;
; succ.s
; Ken Schenke (kenschenke@gmail.com)
;
; Succ routine for runtime
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"
.include "types.inc"

.export succ

.import addInt8, addInt16, addInt32

; data type in A
.proc succ
    cmp #TYPE_BYTE
    beq INT8
    cmp #TYPE_SHORTINT
    beq INT8
    cmp #TYPE_CHARACTER
    beq INT8
    cmp #TYPE_WORD
    beq INT16
    cmp #TYPE_INTEGER
    beq INT16
    cmp #TYPE_ENUMERATION
    beq INT16
    cmp #TYPE_CARDINAL
    beq INT32
    cmp #TYPE_LONGINT
    beq INT32
    rts

INT8:
    jsr rtPopToIntOp1
    lda #1
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr addInt8
    jmp rtPushFromIntOp1

INT16:
    jsr rtPopToIntOp1
    lda #1
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr addInt16
    jmp rtPushFromIntOp1

INT32:
    jsr rtPopToIntOp1And2
    lda #1
    sta intOp32
    lda #0
    ldx #2
:   sta intOp32+1,x
    dex
    bpl :-
    jsr addInt32
    jmp rtPushFromIntOp1And2
.endproc
