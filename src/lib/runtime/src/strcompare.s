;
; strcompare.s
; Ken Schenke (kenschenke@gmail.com)
;
; Compare two strings
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"

.export strCompare, strCompareN

; This routine compares two length-prefixed strings (rtStrCompare).
; First string in ptr3
; Second string in ptr4
; A contains results
;    $ff if s1 < s2
;    0 if s1 = s2
;    1 if s1 > s2
; ptr3 and ptr4 are left past the length bytes.
.proc strCompare
    ldy #0
    lda (ptr3),y
    sta tmp1            ; length of s1 in tmp1
    lda (ptr4),y
    sta tmp2            ; length of s2 in tmp2
    inc ptr3            ; The first characters
    bne :+
    inc ptr3 + 1
:   inc ptr4
    bne :+
    inc ptr4 + 1
:   ; Fall through to strCompareN
.endproc

; This routine compares two strings, each given by a pointer to its first
; character and its length. The characters are compared unsigned (PETSCII
; order), and a string that is a prefix of the other sorts first.
; First string's characters in ptr3, its length in tmp1
; Second string's characters in ptr4, its length in tmp2
; A contains the results, as strCompare's
.proc strCompareN
    ldy #0
LP: lda tmp1
    beq E1              ; No more characters in s1
    lda tmp2
    beq GT              ; No more in s2, but more in s1
    lda (ptr3),y
    cmp (ptr4),y
    bcc LT
    bne GT
    iny                 ; The same: on to the next characters
    dec tmp1
    dec tmp2
    jmp LP
E1: lda tmp2
    bne LT              ; More characters in s2
    lda #0              ; Equal
    rts
LT: lda #$ff
    rts
GT: lda #1
    rts
.endproc
