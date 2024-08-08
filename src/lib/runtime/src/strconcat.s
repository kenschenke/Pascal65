;
; strconcat.s
; Ken Schenke (kenschenke@gmail.com)
;
; Concatenate two strings
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "types.inc"
.include "runtime.inc"
.include "error.inc"

.export concatString

.import subInt16, addInt16, heapFree

.bss

srcPtr: .res 2
strPtr: .res 2

; These are the values for the two sides of a string concatenation.
;    a) Char array: ptr to array heap
;    b) Character: char value
;    c) String literal: pointer to string data
;    d) String variable: pointer to string heap
;    e) String object: pointer to string heap
concat1: .res 2
concat2: .res 2

type1: .res 1
type2: .res 1
tmpOffset: .res 1

; This routine concatenates strings, char arrays, and characters
; into strings. The values can be any combination of:
;   a) A string variable
;   b) A string literal
;   c) A string object
;   d) An array of chars
;   e) A character
; A new string is allocated and returned in A/X.  Any string object
; passed in will be freed.
;   ptr1 - pointer to string variable's position on stack
;   srcPtr - pointer to source
;   ptr4 - pointer to destination
; Inputs:
;   A - data type of first string
;   X - data type of second string
;   ptr1 - first string
;   ptr2 - second string

.code

.proc concatString
    sta type1
    stx type2
    lda ptr1
    sta concat1
    lda ptr1 + 1
    sta concat1 + 1
    lda ptr2
    sta concat2
    lda ptr2 + 1
    sta concat2 + 1
    lda concat1
    ldx concat1 + 1
    ldy type1
    jsr getLength
    sta intOp1
    lda #0
    sta intOp1 + 1
    lda concat2
    ldx concat2 + 1
    ldy type2
    jsr getLength
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr addInt16
    lda intOp1 + 1
    beq :+
    lda #rteStringOverflow
    jsr rtRuntimeError
:   lda intOp1
    pha
    clc
    adc #1
    ldx #0
    jsr rtHeapAlloc
    sta strPtr
    sta ptr2
    stx strPtr + 1
    stx ptr2 + 1
    ldy #0
    pla
    sta (ptr2),y
    lda concat1
    sta ptr1
    lda concat1 + 1
    sta ptr1 + 1
    iny
    lda type1
    jsr concat
    lda concat2
    sta ptr1
    lda concat2 + 1
    sta ptr1 + 1
    lda type2
    jsr concat
    lda strPtr
    ldx strPtr + 1
    rts
.endproc

; Value in A/X, type in Y
.proc getLength
    cpy #TYPE_STRING_LITERAL
    beq SL
    cpy #TYPE_STRING_VAR
    beq SV
    cpy #TYPE_STRING_OBJ
    beq SV
    cpy #TYPE_ARRAY
    beq SA
    lda #1
    rts
SL: jmp strLiteralLength
SV: jmp strVarLength
SA: jmp arrayLength
.endproc

; String in A/X, returned in A.
.proc strVarLength
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    rts
.endproc

.proc strLiteralLength
    sta ptr1
    stx ptr1 + 1
    ldy #0
:   lda (ptr1),y
    beq DN
    iny
    bne :-
DN: tya
    rts
.endproc

; Array in A/X, returned in A.
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
    jsr subInt16
    lda intOp1 + 1          ; Look at high byte of array length
    beq :+                  ; Branch if array <= 255
    lda #rteStringOverflow
    jsr rtRuntimeError
:   inc intOp1              ; Length is actually upper - lower + 1
    lda intOp1
    rts
.endproc

; Type in A
; Y - offset in dest
; ptr1 - source
; ptr2 - dest
.proc concat
    cmp #TYPE_STRING_LITERAL
    beq SL
    cmp #TYPE_STRING_VAR
    beq SV
    cmp #TYPE_STRING_OBJ
    beq SO
    cmp #TYPE_ARRAY
    beq SA
    lda ptr1
    sta (ptr2),y
    iny
    rts
SL: jmp concatLiteral
SV: jmp concatStringVar
SO: jmp concatStringObj
SA: jmp concatArray
.endproc

.proc concatLiteral
    sty tmp2
    lda #0
    sta tmp1
LP: ldy tmp1
    lda (ptr1),y
    beq DN
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    bne LP
DN: ldy tmp2
    rts
.endproc

.proc concatStringObj
    jsr concatStringVar
    sty tmpOffset
    lda ptr2
    pha
    lda ptr2 + 1
    pha
    lda ptr1
    ldx ptr1 + 1
    jsr heapFree
    pla
    sta ptr2 + 1
    pla
    sta ptr2
    ldy tmpOffset
    rts
.endproc

.proc concatStringVar
    sty tmp2
    lda #1
    sta tmp1
    ldy #0
    lda (ptr1),y
    tax
    beq DN
LP: ldy tmp1
    lda (ptr1),y
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    dex
    bne LP
DN: ldy tmp2
    rts
.endproc

.proc concatArray
    sty tmp2
    lda #6
    sta tmp1
    lda ptr1
    ldx ptr1 + 1
    jsr arrayLength
    tax
LP: ldy tmp1
    lda (ptr1),y
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    dex
    bne LP
    ldy tmp2
    rts
.endproc
