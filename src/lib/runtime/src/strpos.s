;
; strpos.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; This routine implements the StrPos runtime function.
;
; Inputs:
;    ptr1: pointer to string to search in
;    ptr2: pointer to substring
;    A: starting offset in source to start the search
; Returns:
;    A: offset of result (1-based) or 0 if not found

.include "runtime.inc"

.export strPos

.import strFind

.bss

srcpos: .res 1

.code

.proc strPos
    cmp #0                  ; Is starting offset 0?
    beq DN                  ; Branch if it is.
    sta srcpos              ; Store the starting offset
    dec srcpos              ; Decrement it (0-based)
    ldy #0
    lda (ptr1),y            ; Load the length of the string to search in
    cmp srcpos              ; Is the starting offset > string length?
    bcs :+                  ; Skip if not
    lda #0                  ; Return 0 to caller
    jmp DN
:   sec
    sbc srcpos              ; Subtract starting offset from string length
    sta tmp1                ; Store it in tmp1 (length of source string)
    lda (ptr2),y            ; Load length of substring
    sta tmp2                ; Store it in tmp2
    inc ptr1                ; Increment ptr1 by 1
    bne :+
    inc ptr1 + 1
:   lda ptr1                ; Add the starting offset to ptr1
    clc
    adc srcpos
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    inc ptr2                ; Increment ptr2 by 1
    bne :+
    inc ptr2 + 1
:   jsr strFind             ; Search for substring
    cmp #0
    beq DN                  ; Branch if result not found
    iny                     ; Increment offset of result by 1
    tya                     ; Put it in A
    clc
    adc srcpos              ; Add the starting offset
DN: rts
.endproc
