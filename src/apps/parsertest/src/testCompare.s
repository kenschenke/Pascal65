;
; testCompare.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; testCompare routine

.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export testCompare

.data

strL1: .asciiz "hellos"
strR1: .asciiz "he"

.code

.proc testCompare
    lda #<strL1
    sta ptr1
    lda #>strL1
    sta ptr1+1

    lda #<strR1
    sta ptr4
    lda #>strR1
    sta ptr4+1

    lda #0
    sta ptr1+2
    sta ptr1+3
    sta ptr4+2
    sta ptr4+3

    jsr compareKeys
    php

    jsr printL
    plp
    jsr printResult
    jsr printR

    lda #13
    jsr CHROUT
    rts
.endproc

.proc printL
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    jsr CHROUT
    inz
    bne :-
:   rts
.endproc

.proc printR
    ldz #0
:   nop
    lda (ptr4),z
    beq :+
    jsr CHROUT
    inz
    bne :-
:   rts
.endproc

.proc printResult
    bmi L1
    bne L2

    ; ptr1 = ptr4
    lda #' '
    jsr CHROUT
    lda #'='
    jsr CHROUT
    lda #' '
    jsr CHROUT
    rts

    ; ptr1 < ptr4
L1: lda #' '
    jsr CHROUT
    lda #'<'
    jsr CHROUT
    lda #' '
    jsr CHROUT
    rts

    ; ptr1 > ptr4
L2: lda #' '
    jsr CHROUT
    lda #'>'
    jsr CHROUT
    lda #' '
    jsr CHROUT
    rts
.endproc

; This routine compares the keys for two nodes
; and sets CPU flags to indicate sort order.
; If the N flag is set if the key in ptr1 < ptr4
; If the Z flag is set key in ptr1 == ptr4.
; If the Z flag is cleared, the key in ptr1 > ptr4.
.proc compareKeys
    ldz #0
L1: nop
    lda (ptr1),z
    beq L2
    nop
    cmp (ptr4),z
    bne L3
    inz
    bne L1
L2: nop
    lda (ptr4),z
    beq L3
    lda #$80            ; Set the N flag
L3: rts
.endproc
