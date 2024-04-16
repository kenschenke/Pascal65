;
; beginswith.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; BeginsWith runtime function
;
; Inputs:
;   ptr1: pointer to source string
;   ptr2: pointer to sub string
;   tmp1: length of source string
;   tmp2: length of substring
; Returns:
;   A: 1 if source string starts with substring

.include "runtime.inc"

.export beginswith

.import strFind

.proc beginswith
    jsr strFind
    cmp #0
    beq :+
    cpy #0
    beq :+
    lda #0
:   rts
.endproc
