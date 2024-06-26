;
; _printz.s
; Ken Schenke (kenschenke@gmail.com)
; 
; String output to console
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "cbm_kernal.inc"

.export _printz, _printlnz, _printzLeftPad, _printlnzLeftPad
.import leftpad, simCHROUT
.importzp ptr1

; This routine prints a null-terminated string to the current
; output device using the Kernal CHROUT routine.  The .A register
; contains the lower byte of the string's address and the .X
; register contains the upper byte.  ptr1 is corrupted.
.proc _printz
    sta ptr1
    stx ptr1 + 1

    ; loop until 0 byte
    ldy #0
L1:
    lda (ptr1),y
    beq L2
.ifdef __SIM6502__
    jsr simCHROUT
.else
    jsr CHROUT
.endif
    iny
    jmp L1

L2:
    rts
.endproc

; This routine prints a null-terminated string and outputs
; a end of line character (return).
.proc _printlnz
    jsr _printz
    lda #13
.ifdef __SIM6502__
    jsr simCHROUT
.else
    jsr CHROUT
.endif
    rts
.endproc

; This routine prints a null-terminated string to the current
; output device using the Kernal CHROUT routine.  The .A register
; contains the lower byte of the string's address and the .X
; register contains the upper byte.  The .Y register contains
; the padded width.  ptr1 is corrupted.
.proc _printzLeftPad
    sta ptr1
    stx ptr1 + 1
    tya
    pha
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    iny
    jmp L1
L2:
    tya
    tax
    pla
    jsr leftpad
    lda ptr1
    ldx ptr1 + 1
    jmp _printz
.endproc

.proc _printlnzLeftPad
    jsr _printzLeftPad
    lda #13
.ifdef __SIM6502__
    jsr simCHROUT
.else
    jsr CHROUT
.endif
    rts
.endproc
