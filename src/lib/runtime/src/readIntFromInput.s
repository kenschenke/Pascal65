.include "inputbuf.inc"
.include "runtime.inc"

.export readIntFromInput

.import readInt16, inputPos, skipSpaces

; Reads an integer from inputBuf and returns it in A/X
.proc readIntFromInput
    ; Clear intBuf
    ldy #6
    lda #0
L1:
    sta (intPtr),y
    dey
    bpl L1

    ; Skip spaces in input
    jsr skipSpaces  ; Skip spaces in input buffer
    ldy inputPos    ; Load inputPos into Y
    lda (ptr1),y
    cmp #'-'        ; Is the first character a dash?
    bne L2          ; Not a dash
    ldy #0
    sta (intPtr),y  ; Store the minus sign in intBuf
    ldy inputPos    ; Load inputPos back into Y
    ldx #1          ; Start at the 2nd char in intBuf
    iny             ; Skip to the next character in the input buffer
    jmp L3          ; Start reading digits
L2:
    ldx #0          ; Use X as an offset into the integer buffer
L3:
    cpy #INPUTBUFLEN - 1
    beq L4          ; End of input buffer reached
    lda (ptr1),y    ; Load next character from input buffer
    cmp #'0'
    bcc L4          ; Done if character below '0'
    cmp #'9'+1
    bcs L4          ; Done if character after '9'
    sty inputPos    ; Save Y
    pha             ; Save A
    txa             ; Transfer X
    tay             ; to Y
    pla             ; Recover A
    sta (intPtr),y  ; Store the digit in intBuf
    ldy inputPos
    iny             ; Move to next character in input buffer
    inx             ; Move to next spot in intBuf
    cmp #7          ; End of intBuf?
    bne L3          ; No.  Keep reading characters
L4:
    sty inputPos    ; Remember intPos
    jsr readInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

