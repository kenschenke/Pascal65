.include "cbm_kernal.inc"

.export printz, printlnz
.importzp ptr1

; This routine prints a null-terminated string to the current
; output device using the Kernal CHROUT routine.  The .A register
; contains the lower byte of the string's address and the .X
; register contains the upper byte.  ptr1 is corrupted.
.proc printz
    sta ptr1
    stx ptr1 + 1

    ; loop until 0 byte
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    jsr CHROUT
    iny
    jmp L1

L2:
    rts
.endproc

; This routine prints a null-terminated string and outputs
; a end of line character (return).
.proc printlnz
    jsr printz
    lda #13
    jsr CHROUT
    rts
.endproc
