;
; strfind.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to find a substring in a string.
; Returns index of first occurrence of substring in another string.
;
; Inputs:
;    ptr1 - first character of string to search in
;    ptr2 - first character of substring
;    tmp1 - length of string to search in
;    tmp2 - length of substring
;
; Returns:
;    A - non-zero if substring was found
;    Y - offset (zero-based) in string of substring match

.include "runtime.inc"

.export strFind

.bss

srcNdx: .res 1      ; index (zero-based) in source string
destNdx: .res 1     ; index (zero-based) in substring

; tmp3 - first index of match in source string

.code

.proc strFind
    lda #0
    sta srcNdx
    sta destNdx
    ; Look for first character of substring
LP: lda srcNdx      ; Compare source index
    cmp tmp1        ; to length of source string
    beq NF          ; Branch if reached end of source string
    ldy srcNdx      ; Load source index into Y
    lda (ptr1),y    ; Load next character in source string
    ldy destNdx     ; Load substring index into Y
    cmp (ptr2),y    ; Compare to first character in substring
    beq CS          ; Branch if a match (to look at remainder of substring)
    inc srcNdx      ; Increment source index
    jmp LP          ; Look at next character in source string
NF: lda #0          ; substring not found
    rts
DN: lda #1          ; substring found
    ldy tmp3        ; offset of substring in source string
    rts
CS: lda srcNdx      ; Load the source index
    sta tmp3        ; store it in tmp3 in case this is a match
LS: lda destNdx     ; Compare substring index
    cmp tmp2        ; to length of substring
    beq DN          ; Branch if reached end of substring (it's a match)
    lda srcNdx      ; Compare source index
    cmp tmp1        ; to length of source string
    beq NF          ; Branch if reached end of source string
    ldy srcNdx      ; Load source index into Y
    lda (ptr1),y    ; Load next character in source string
    ldy destNdx     ; Load substring index into Y
    cmp (ptr2),y    ; Compare to next character in substring
    bne NM          ; Not a match
    inc srcNdx      ; Increment source index
    inc destNdx     ; Increment substring index
    jmp LS          ; Loop to comparing next character in substring
NM: inc tmp3        ; Go to next character in source string
    lda tmp3        ; Load index in source string
    sta srcNdx      ; Store it in source string
    jmp LP          ; Go back to looking for matched in source string
.endproc
