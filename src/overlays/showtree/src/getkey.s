;
; getkey.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Keyboard routines

.include "zeropage.inc"

.export clearKeyBuf, getKey

KEYBUF = $d610

.proc clearKeyBuf
    lda #0
L1: ldx KEYBUF
    beq L2
    sta KEYBUF
    bne L1
L2: rts
.endproc

.proc fixAlphaCase
    cmp #96
    bcc L1
    cmp #123
    bcs L2
    sec
    sbc #32
    jmp L2
L1: cmp #64
    bcc L2
    cmp #91
    bcs L2
    clc
    adc #128
L2: rts
.endproc

.proc getKey
L1: ldx KEYBUF
    beq L1
    lda #0
    sta KEYBUF
    txa
    jmp fixAlphaCase
.endproc

