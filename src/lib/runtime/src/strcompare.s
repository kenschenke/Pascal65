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

.export strCompare

; First string in ptr3
; Second string in ptr4
; A contains results
;    < 0 is s1 < s2
;    = 0 if s1 = s2
;    > 0 if s1 > s2
; tmp1 - remaining length of s1
; tmp2 - remaining length of s2
.proc strCompare
    ldy #0
    lda (ptr3),y
    sta tmp1            ; length of s1 in tmp1
    lda (ptr4),y
    sta tmp2            ; length of s2 in tmp2
    ora tmp1            ; Are both strings empty?
    beq EQ              ; If so, they're equal and we're done
L1:
    iny                 ; increment index to compare at
    ; If no more characters in s1, done
    lda tmp1
    beq S1L
    ; If no more characters in s2, done
    lda tmp2
    beq S2L
    lda (ptr3),y
    cmp (ptr4),y
    beq LP
    ; The characters are different
    bcc S1L
    bcs S2L
LP:
    ; Move to the next character
    dec tmp1
    dec tmp2
    ; Are we done with both strings?
    lda tmp1
    ora tmp2
    bne L1
EQ: lda #0
    rts
S1L:
    lda #$ff
    rts
S2L:
    lda #$1
    rts
.endproc
