;
; nameCreate.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; nameCreate routine

.include "zeropage.inc"
.include "4510macros.inc"

.export nameCreate

.import heapAlloc

; This routine allocates memory to hold a null-terminated string
; then copies the string into the memory.
; The string is passed in A/X (bank 0).
.proc nameCreate
    sta ptr1
    stx ptr1+1

    pha
    phx

    ldy #0
:   lda (ptr1),y
    beq :+
    iny
    bne :-
:   iny
    tya
    ldx #0
    jsr heapAlloc
    stq ptr2

    pla
    sta ptr1+1
    pla
    sta ptr1
    ldy #0
    ldz #0
:   lda (ptr1),y
    nop
    sta (ptr2),z
    beq :+
    iny
    inz
    bne :-
:   ldq ptr2
    rts
.endproc
