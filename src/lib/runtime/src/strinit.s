;
; strinit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Initialize a new string variable
;
; This routine initializes a new string variable from a string literal.
; It allocates memory to hold the string value.
; It copies the string literal into the string's memory
; It pushes the new string variable onto the stack.

.include "runtime.inc"
.include "types.inc"

.export stringInit

.import heapAlloc, pusheax

; String literal passed in A/X (both zero if empty string)
.proc stringInit
    ; Check if string literal is zero
    cmp #0
    bne NotEmpty
    cpx #0
    bne NotEmpty
    ; String literal is NULL - allocate an empty string
    lda #1
    ldx #0
    jsr heapAlloc
    sta ptr1
    stx ptr1 + 1
    ldy #0
    sty sreg
    sty sreg + 1
    jsr pusheax
    lda #0
    tay
    sta (ptr1),y
    rts

NotEmpty:
    ; Count the length of the string literal
    sta ptr1
    stx ptr1 + 1
    ldy #0
:   lda (ptr1),y
    beq :+
    iny
    bne :-
    ; Allocate a heap for the string
:   tya
    pha     ; Save string length on stack
    iny
    ; Keep the string literal pointer on the stack
    lda ptr1
    pha
    lda ptr1 + 1
    pha
    tya
    ldx #0
    jsr heapAlloc
    sta ptr2
    stx ptr2 + 1
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    pla
    ldy #0
    sta (ptr2),y
:   lda (ptr1),y
    beq :+
    iny
    sta (ptr2),y
    bne :-
:   sta sreg
    sta sreg + 1
    lda ptr2
    ldx ptr2 + 1
    jmp pusheax
.endproc
