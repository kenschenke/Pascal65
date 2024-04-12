;
; waitforkey.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Wait for a key press
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "cbm_kernal.inc"

.export _waitforkey

; This routine waits for a key press, which is discarded.
; This is used when the compiler encounters error(s) and
; prompts the user to press a key.

.proc _waitforkey

.ifdef __MEGA65__
 :  lda $d610
    beq :-
    lda #0
    sta $d610
.else
:   jsr GETIN
    cmp #0
    beq :-
.endif

    rts
.endproc
