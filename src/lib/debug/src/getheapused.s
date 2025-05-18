;
; getheapused.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Calculate the bytes used by the heap
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

; First entry in MAT
; Assuming a 2k stack size
.ifdef __MEGA65__
MAT = $B7FC
.else
MAT = $C7FC
.endif

.export getHeapUsed

.proc getHeapUsed
    lda #0
    sta intOp1
    sta intOp1 + 1
    lda #$ff
    tax
    jsr rtHeapAlloc
    sta ptr1
    stx ptr1+1

    ; Loop through the MAT

    ; Is this entry the end?
LP: ldy #3
:   lda (ptr1),y
    bne :+
    dey
    bpl :-
    bmi DN
:   ldy #1
    lda (ptr1),y
    and #$80
    beq NX
    ldy #0
    lda (ptr1),y
    clc
    adc intOp1
    sta intOp1
    iny
    lda (ptr1),y
    and #$7f
    adc intOp1 + 1
    sta intOp1 + 1
NX: lda ptr1
    sec
    sbc #4
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    jmp LP

    ; Done looping. Return the total.
DN: lda stackP
    sec
    sbc #4
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    ldy #0
    lda intOp1
    sta (ptr1),y
    iny
    lda intOp1 + 1
    sta (ptr1),y
    rts
.endproc
