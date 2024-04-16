;
; endswith.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; EndsWith runtime function
;
; Inputs:
;   ptr1 - pointer to source string
;   ptr2 - pointer to substring
;   tmp1 - length of source string
;   tmp2 - length of substring
; Returns:
;   A: 1 if source string ends with substring

.include "runtime.inc"

.export endswith

.import strFind

.bss

srclen: .res 1
sublen: .res 2

.code

.proc endswith
    lda tmp1
    sta srclen
    lda tmp2
    sta sublen
    jsr strFind
    cmp #0
    beq DN
    lda srclen
    sec
    sbc sublen
    sty tmp1
    cmp tmp1
    beq EQ
    lda #0
    beq DN
EQ: lda #1
DN: rts
.endproc
