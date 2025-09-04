;
; getdatetime.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; GetDateTime for Time Unit

.include "runtime.inc"
.include "4510macros.inc"

.p4510

.export getDateTime

.struct DATETIME
    hour .byte
    minute .byte
    second .byte
    month .byte
    day .byte
    year .word
.endstruct

.proc getDateTime
    ; Get a pointer to the caller's DATETIME record
    lda #0
    jsr rtLibLoadParam
    sta ptr4
    stx ptr4+1
    ldy #0
    lda (ptr4),y
    sta ptr3
    iny
    lda (ptr4),y
    sta ptr3+1

    ; Set up ptr1 and ptr2 as a 32-bit pointer to $0ffd7110
    lda #$10
    sta ptr1
    lda #$71
    sta ptr1+1
    lda #$fd
    sta ptr2
    lda #$0f
    sta ptr2+1

    ; Store the six bytes at $0ffd7110 in intOp1, intOp2, and intOp32
    ; which are contiguous in zero page.
    ldz #0
    ldx #0
L1: nop
    lda (ptr1),z
    sta intOp1,x
    inz
    inx
    cpx #6
    bne L1

    ; Seconds
    lda intOp1
    jsr fromBCD
    ldy #DATETIME::second
    sta (ptr3),y

    ; Minutes
    lda intOp1+1
    jsr fromBCD
    ldy #DATETIME::minute
    sta (ptr3),y

    ; Hours
    lda intOp2
    and #$7f
    jsr fromBCD
    ldy #DATETIME::hour
    sta (ptr3),y

    ; Day
    lda intOp2+1
    jsr fromBCD
    ldy #DATETIME::day
    sta (ptr3),y

    ; Month
    lda intOp32
    jsr fromBCD
    ldy #DATETIME::month
    sta (ptr3),y

    ; Year
    ldy #DATETIME::year
    lda #.LOBYTE(2000)
    sta (ptr3),y
    iny
    lda #.HIBYTE(2000)
    sta (ptr3),y
    lda intOp32+1
    jsr fromBCD
    dey
    clc
    adc (ptr3),y
    sta (ptr3),y
    iny
    lda (ptr3),y
    adc #0
    sta (ptr3),y

    rts
.endproc

; This routine converts the value in A from BCD to binary
.proc fromBCD
    sta tmp2
    lsr
    lsr
    lsr
    lsr
    ; Multiply by 10
    asl
    sta tmp1
    asl
    asl
    clc
    adc tmp1
    sta tmp1
    lda tmp2
    and #$0f
    clc
    adc tmp1
    rts
.endproc
