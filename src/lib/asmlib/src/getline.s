;
; getline.s
; Ken Schenke (kenschenke@gmail.com)
;
; Read a line of input from the console
; 
; Copyright (c) 2024-2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
.include "cbm_kernal.inc"
.include "c64.inc"
.include "zeropage.inc"
.include "editor.inc"

INPUTBUFLEN = 20

.export getline

.import clearKeyBuf, getKey

.proc clearBuf
    lda #0
    ldy #INPUTBUFLEN-1
:   sta (ptr1),y
    dey
    bpl :-
    rts
.endproc

.proc renderInputCursor
    lda #CH_ORANGE
    jsr CHROUT
    lda #CH_REVERSE_ON
    jsr CHROUT
    lda #' '
    jsr CHROUT
    lda #CH_REVERSE_OFF
    jsr CHROUT
    lda #CH_WHITE
    jsr CHROUT
    rts
.endproc

.proc clearInputCursor
    lda #CH_WHITE
    jsr CHROUT
    lda #CH_BACKSPACE
    jsr CHROUT
    rts
.endproc

; Read an input line from the keyboard into a caller-supplied buffer,
; passed in A/X. The buffer must be in bank 0 and be at least 20 bytes long.
; The carry flag is cleared on exit if the user presses Esc.
; The number of characters read is returned in A.
; The input buffer is not zero-terminated.
.proc getline
    sta ptr1
    stx ptr1+1
    jsr clearBuf
    jsr clearKeyBuf
    ; turn the cursor on
.ifdef __MEGA65__
    jsr renderInputCursor
    lda #0
.else
    lda #0
    sta CURS_FLAG
.endif
    sta tmp1
Loop:
    jsr getKey
    cmp #CH_ENTER
    beq EnterKey
    cmp #CH_BACKSPACE
    beq DeleteKey
    cmp #CH_ESC
    beq EscKey
    ; Is the character less than 32?
    cmp #32
    bcc Loop        ; Yes - ignore it
    ; Is the character > 160?
    cmp #160
    bcs Keep        ; Yes - keep it
    ; Is the character > 127?
    cmp #127
    bcs Loop        ; Yes - ignore it
Keep:
    ; Has the user already typed the maximum allowed characters?
    ldx tmp1
    cpx #INPUTBUFLEN
    beq Loop        ; Yes - ignore the key
.ifdef __MEGA65__
    pha
    lda #CH_BACKSPACE
    jsr CHROUT
    pla
.endif
    jsr CHROUT
    ldy tmp1
    sta (ptr1),y
    inc tmp1
.ifdef __MEGA65__
    jsr renderInputCursor
.endif
    bra Loop
DeleteKey:
    ; Delete
    ldx tmp1
    beq Loop        ; Already at start of buffer
    jsr CHROUT
.ifdef __MEGA65__
    jsr CHROUT
    jsr renderInputCursor
.endif
    dec tmp1
    ldy tmp1
    lda #' '
    sta (ptr1),y
    bra Loop

EnterKey:
    ; User pressed Enter
.ifdef __MEGA65__
    jsr clearInputCursor
.else
    lda #1
    sta CURS_FLAG
    lda #' '
    jsr CHROUT
.endif
    jsr clearKeyBuf
    lda tmp1
    sec
    rts

EscKey:
    ; User pressed Esc
    jsr clearInputCursor
    lda tmp1
    clc
    rts
.endproc
