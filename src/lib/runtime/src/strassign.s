;
; strassign.s
; Ken Schenke (kenschenke@gmail.com)
;
; String assignment
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "types.inc"
.include "runtime.inc"
.include "error.inc"

.export assignString

.import convertString, popax

.bss

srcPtr: .res 2
varPtr: .res 2

.code

; This routine assigns one string to another.
; The left side will always be a newly allocated string.
; The right side can be one of:
;   a) Another string (variable or object)
;   b) A string literal
;   c) An array of char
;   d) A character literal
; The right type is pushed onto the stack with pushax
; and then the pointer to the variable on the stack is pushed onto the stack.
; The pointer to the right value is passed in A/X
;   srcPtr - pointer to source
;   varPtr - pointer to variable on stack
.proc assignString
    sta srcPtr              ; Save the source pointer
    stx srcPtr + 1
    jsr popax
    sta varPtr              ; Save the pointer to the string variable
    sta ptr1
    stx varPtr + 1
    stx ptr1 + 1
    jsr popax
    pha                     ; Save the source type
    ; Free the current string variable
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr rtHeapFree
    pla                     ; Pop the source type
    tay                     ; and move it to Y
    lda srcPtr
    ldx srcPtr + 1
    jsr convertString
    sta tmp1                ; Save the new string ptr in tmp1/tmp2
    stx tmp2
    lda varPtr
    sta ptr1
    lda varPtr + 1
    sta ptr1 + 1
    ldy #0
    lda tmp1
    sta (ptr1),y
    iny
    lda tmp2
    sta (ptr1),y
    rts
.endproc

