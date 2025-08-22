;
; lpoke.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Poke runtime function

.include "runtime.inc"

.p4510

.export lpoke

; This routine stores the value from the second parameter
; into the address in the first parameter.

.proc lpoke
    lda #1
    jsr rtLibLoadParam
    pha
    phx
    lda sreg
    pha
    lda sreg + 1
    pha
    lda #0
    jsr rtLibLoadParam
    ; Use ptr2 and ptr3 as a 32-bit pointer
    sta ptr2
    stx ptr2 + 1
    lda sreg
    bne L1
    ldy #3
:   pla
    sta (ptr2),y
    dey
    bpl :-
    rts
L1: sta ptr3
    lda sreg + 1
    sta ptr3 + 1
    ldz #3
:   pla
    nop
    sta (ptr2),z
    dez
    bpl :-
    rts
.endproc
