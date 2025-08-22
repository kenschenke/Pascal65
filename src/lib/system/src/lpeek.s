;
; lpeek.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Peek runtime function

.include "runtime.inc"

.p4510

.export lpeek

; This routine returns the value in the address in the first parameter

.proc lpeek
    lda #0
    jsr rtLibLoadParam
    ; Use ptr1 and ptr2 as a 32-bit pointer
    sta ptr1
    stx ptr1 + 1
    lda sreg
    bne L1
    ldy #3
    lda (ptr1),y
    sta sreg + 1
    dey
    lda (ptr1),y
    sta sreg
    dey
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    bra L2
L1: sta ptr2
    lda sreg + 1
    sta ptr2 + 1
    ldz #3
    nop
    lda (ptr1),z
    sta sreg + 1
    dez
    nop
    lda (ptr1),z
    sta sreg
    dez
    nop
    lda (ptr1),z
    tax
    dez
    nop
    lda (ptr1),z 
L2: jmp rtLibReturnValue
.endproc
