;
; hexstr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; hexstr routine

.include "4510macros.inc"
.include "zeropage.inc"

.export hexstr

.import isQZero

.data

hexDigits: .byte "0123456789abcdef"

.bss

hasDigits: .res 1           ; non-zero if digits shown (to skip leading zeros)
index: .res 1

.code

; This routine converts a 32-bit number into a string of hex digits.
; The number is passed in intOp32 and A/X is a pointer to the
; buffer to contain the hex string.
;
; The string is null-terminated.
.proc hexstr
    sta ptr1
    stx ptr1+1
    ldq intOp32
    jsr isQZero
    bne :+
    lda #'0'
    ldy #0
    sta (ptr1),y
    iny
    lda #0
    sta (ptr1),y
    rts
:   lda #0
    sta hasDigits
    tay

    lda #3
    sta index
L1: ldx index
    lda intOp32,x
    jsr showByte
    dec index
    bpl L1
    lda #0
    sta (ptr1),y
    rts
.endproc

.proc showByte
    cmp #0
    bne L1
    ldx hasDigits
    bne L1
    rts
L1: pha                 ; Save the byte
    lsr                 ; Move the high nibble to low
    lsr
    lsr
    lsr
    jsr showNibble
    pla
    and #$0f            ; Mask the high nibble
    jsr showNibble
    rts
.endproc

.proc showNibble
    cmp #0
    bne L1
    ldx hasDigits
    bne L1
    rts
L1: tax
    lda hexDigits,x
    sta (ptr1),y
    iny
    lda #1
    sta hasDigits
    rts
.endproc
