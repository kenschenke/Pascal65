;
; libutil.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Utility routines for shared libraries to process
; parameters and return values.

.include "runtime.inc"

.export storeVarParam, loadParam, returnVal

; This routine calculates the address of a parameter and
; leaves it in ptr1.
; parameter number (0-based) in A.
.proc calcParam
    tax                 ; Parameter number in X
    lda stackP
    sec
    sbc #20             ; first parameter is 20 bytes below stack frame ptr
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    cpx #0
    beq DN
:   lda ptr1
    sec
    sbc #4
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    dex
    bne :-
DN: rts
.endproc

; Stores the value into a Var parameter.
; Value in A/X/sreg
; Parameter number (0-based) in Y
.proc storeVarParam
    pha
    txa
    pha
    tya
    jsr calcParam
    ldy #0
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2 + 1
    pla
    sta (ptr2),y
    dey
    pla
    sta (ptr2),y
    ldy #2
    lda sreg
    sta (ptr2),y
    iny
    lda sreg + 1
    sta (ptr2),y
    nop
    nop
    nop
    nop
    nop
    rts
.endproc

; This routine loads a parameter off the runtime stack
; into A/X/sreg.
;
; Parameter number in A (0-based)
.proc loadParam
    jsr calcParam
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
    rts
.endproc

; This routine stores the value in A/X/sreg into the
; return value spot in the current stack frame.
.proc returnVal
    pha
    lda stackP
    sec
    sbc #4
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    ldy #0
    pla
    sta (ptr1),y
    txa
    iny
    sta (ptr1),y
    lda sreg
    iny
    sta (ptr1),y
    lda sreg + 1
    iny
    sta (ptr1),y
    rts
.endproc

