;
; nameClone.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; nameClone routine

.include "zeropage.inc"
.include "4510macros.inc"

.export nameClone

.import rtPushQ, rtPopQ, heapAlloc

; This routine clones a null-terminated string.
; The string is passed in Q.
.proc nameClone
    stq ptr1

    jsr rtPushQ

    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    inz
    bne :-
:   inz
    tza
    ldx #0
    jsr heapAlloc
    stq ptr2

    jsr rtPopQ
    stq ptr1
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    beq :+
    inz
    bne :-
:   ldq ptr2
    rts
.endproc
