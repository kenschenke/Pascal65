;
; showAddr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; showAddr routine

.include "asmlib.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "zeropage.inc"

.export showAddr

.data

hexDigits: .byte "0123456789abcdef"
nullStr: .asciiz "null"

.bss

hasDigits: .res 1           ; non-zero if digits shown (to skip leading zeros)
addr: .res 4

.code

.proc showAddr
    stq addr
    jsr isQZero
    bne :+
    jmp showNullStr
:   lda #0
    sta hasDigits
    lda #'$'
    jsr CHROUT

    lda #3
    sta tmp1
L1: ldx tmp1
    lda addr,x
    jsr showByte
    dec tmp1
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
    jsr CHROUT
    lda #1
    sta hasDigits
    rts
.endproc

.proc showNullStr
    ldx #0
:   lda nullStr,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc
