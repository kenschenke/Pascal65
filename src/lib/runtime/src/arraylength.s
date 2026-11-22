;
; arraylength.s
; Ken Schenke (kenschenke@gmail.com)
;
; The length of an array of Char as a string
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"
.include "error.inc"

.export arrayLength

.import subInt16, runtimeError

; This routine returns the number of elements in an array of Char, which
; concatenation (strconcat.s) and comparison (comp.s) treat as a string of
; that length. The array's heap block is in A/X. It starts with the 6-byte
; header (array.s): the low bound, the high bound and the element size, a
; word each. The length (upper - lower + 1) is returned in A, with Z set
; if it is 0. An empty dynamic array (0..-1) is 0, and one over 255 is
; rteStringOverflow, as in convertString (strconvert.s). ptr1 is left
; pointing at the block.
.proc arrayLength
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta intOp2
    iny
    lda (ptr1),y
    sta intOp2 + 1
    iny
    lda (ptr1),y
    sta intOp1
    iny
    lda (ptr1),y
    sta intOp1 + 1
    jsr subInt16            ; upper - lower
    lda intOp1
    ldx intOp1 + 1
    inx
    bne :+                  ; Branch unless the high byte is $FF
    cmp #$ff
    bne OV                  ; Negative, but not -1
    lda #0                  ; An empty dynamic array
    rts
:   dex
    bne OV                  ; 257 or more
    cmp #$ff
    beq OV                  ; 256
    clc
    adc #1                  ; Length is actually upper - lower + 1
    rts
OV: lda #rteStringOverflow
    jmp runtimeError
.endproc
