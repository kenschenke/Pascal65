;
; dumpHex.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpHex routine

.include "asmlib.inc"
.include "4510macros.inc"
.include "zeropage.inc"

.export dumpHex

.import dumpChar, printz

.data

hexDigits: .byte "0123456789abcdef"
zeroStr: .asciiz "0"

.bss

hasDigits: .res 1           ; non-zero if digits shown (to skip leading zeros)
value: .res 4
index: .res 1

.code

.proc dumpHex
    stq value
    jsr isQZero
    bne :+
    lda #<zeroStr
    ldx #>zeroStr
    jmp printz
:   lda #0
    sta hasDigits

    lda #3
    sta index
L1: ldx index
    lda value,x
    jsr showByte
    dec index
    bpl L1
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
    jsr dumpChar
    lda #1
    sta hasDigits
    rts
.endproc
