;
; decinc.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; These routines are part of the Pascal runtime and decrement
; or increment a variable.
;
; Inputs:
;    ptr1: address of variable's storage
;    A: data type of variable to increment (from types.inc)
;    X: (for pointers) the size of the data type
;    Y: data type of increment amount
;    The amount to increment is at the top of the runtime stack
;    and is pushed as 4 bytes.

.include "runtime.inc"
.include "types.inc"

.export decrement, increment

.import popeax, popToIntOp1And2, invertInt32, signExtend8To32
.import signExtend16To32, pushFromIntOp1And2, addInt8, addInt16, addInt32

; Decrement
; This routine just negates the increment amount and passes off to increment
.proc decrement
    pha                     ; Save A, X, and Y to CPU stack
    txa
    pha
    tya
    pha
    jsr popToIntOp1And2     ; Pop increment amount off runtime stack
    pla                     ; Pop increment data type
    pha                     ; Then put it back
    cmp #TYPE_BYTE
    beq INT8                ; Branch if increment amount is 8-bit
    cmp #TYPE_SHORTINT
    beq INT8
    cmp #TYPE_WORD
    beq INT16               ; Branch if increment amount is 16-bit
    cmp #TYPE_INTEGER
    beq INT16
    ; fall through for 32-bit
    jmp DI                  ; Skip ahead to invert
INT8:
    jsr signExtend8To32     ; Sign extend to 32-bit
    jmp DI
INT16:
    jsr signExtend16To32    ; Sign extend to 32-bit
DI:
    jsr invertInt32         ; Negate the increment amount
    jsr pushFromIntOp1And2  ; Put the increment amount back on the runtime stack
    pla                     ; Restore A, X, and Y for increment
    tay
    pla
    tax
    pla
    ; Fall through to increment
.endproc

.proc increment
    cpy #TYPE_BYTE
    beq INT8                ; Branch if increment amount is 8-bit
    cpy #TYPE_SHORTINT
    beq INT8
    cpy #TYPE_WORD
    beq INT16               ; Branch if increment amount is 16-bit
    cpy #TYPE_INTEGER
    beq INT16
    ; fall through for 32-bit
    jsr popToIntOp1And2
    ldy #3
    ldx #3
:   lda (ptr1),y
    sta intOp32,x
    dex
    dey
    bpl :-
    jsr addInt32
    ldy #3
    ldx #3
:   lda intOp1,x
    sta (ptr1),y
    dex
    dey
    bpl :-
    rts
INT8:
    jsr popeax
    sta intOp2
    ldy #0
    lda (ptr1),y
    sta intOp1
    sty intOp1 + 1
    sty intOp2 + 2
    jsr addInt8
    ldy #0
    lda intOp1
    sta (ptr1),y
    rts
INT16:
    jsr popeax
    sta intOp1
    stx intOp1 + 1
    ldy #0
    lda (ptr1),y
    sta intOp2
    iny
    lda (ptr1),y
    sta intOp2 + 1
    jsr addInt16
    ldy #0
    lda intOp1
    sta (ptr1),y
    iny
    lda intOp1 + 1
    sta (ptr1),y
    rts
.endproc
