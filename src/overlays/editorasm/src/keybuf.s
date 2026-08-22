;
; keybuf.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Keyboard input

.include "editor.inc"
.include "zeropage.inc"

.export clearKeyBuf, editorReadKey

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

.proc editorReadKey
    lda #0                  ; Use tmp1 as an "Escape-pressed" flag
    sta tmp1
L1: ldx KEYBUF
    beq L1
    lda #0
    sta KEYBUF
    txa
    ; brk
    ldx tmp1                ; Was the last key esc?
    beq NE                  ; Branch if not
    cmp #'5'
    bne :+
    lda #CH_50_ROWS
    rts
:   cmp #'8'
    bne :+
    lda #CH_25_ROWS
    rts
:   jsr fixAlphaCase
    cmp #'j'
    bne :+
    lda #CTRL_J
    rts
:   cmp #'b'
    bne :+
    lda #CTRL_B
    rts
:   cmp #'e'
    bne :+
    lda #CTRL_E
    rts
:   cmp #'k'
    bne :+
    lda #CTRL_K
    rts
:   cmp #CH_CURS_UP
    bne :+
    lda #CTRL_P
    rts
:   cmp #CH_CURS_DOWN
    bne :+
    lda #CTRL_N
    rts
:   cmp #'p'
    bne :+
    lda #CH_DELETE_SOL
    rts
:   cmp #'q'
    bne :+
    lda #CH_DELETE_EOL
    rts
:   cmp #'v'
    bne :+
    lda #CTRL_V
    rts
:   cmp #'w'
    bne :+
    lda #CTRL_W
    rts
:
NE: cmp #CH_ESC
    bne :+
    lda #1
    sta tmp1
    bra L1
:   cmp #$40            ; "@"
    bne :+
    rts
:   cmp #$af            ; "^" (up arrow)
    bne :+
    lda #$5e
    rts
:   jsr fixAlphaCase
    rts
.endproc

