.include "inputbuf.inc"

.import intOp1, intBuf, getline, readInt16
.importzp ptr1

.export _clearInputBuf, _isInputEndOfLine, _readCharFromInput, _readIntFromInput, inputBuf, inputBufUsed

.bss

inputBuf: .res INPUTBUFLEN
inputBufUsed: .res 1
inputPos: .res 1

.code

.proc _clearInputBuf
    lda #0
    sta inputBufUsed
    sta inputPos
    rts
.endproc

.proc _isInputEndOfLine
    lda #1
    ldx inputBufUsed
    dex
    bmi L1
    cpx inputPos            ; carry set inputPos <= inputBufUsed-1 -- carry clear inputPos > inputBufUsed-1
    bcc L1
    lda #0
L1:
    ldx #0
    rts
.endproc

.proc _readCharFromInput
    ldx inputBufUsed        ; Check how many unread chars in input buffer
    dex                     ; Less One
    bmi L1                  ; If negative, need to read a line
    cpx inputPos            ; Compare inputBufUsed to inputPos
    bcs L2                  ; If inputPos < inputBufUsed - 1, don't need to read
L1:
    jsr getline             ; Read a line from the input
L2:
    ldx inputPos            ; Use inputPos as index into inputBuf
    lda inputBuf,x          ; Load current character from inputBuf
    inc inputPos            ; Move the input position forward
    ldx #0                  ; Clear X for CC65 return value
    rts
.endproc

; Reads an integer from inputBuf and returns it in A/X
.proc _readIntFromInput
    ; Clear intBuf
    lda #<intBuf
    sta ptr1
    lda #>intBuf
    sta ptr1 + 1
    ldy #6
    lda #0
L1:
    sta (ptr1),y
    dey
    bpl L1

    ; Skip spaces.  If end of line reached, get another line.
    ; Repeat as necessary until non-space reached.
    ldy inputPos
L2:
    lda #<inputBuf
    sta ptr1
    lda #>inputBuf
    sta ptr1 + 1
L3:
    cpy #INPUTBUFLEN - 1
    beq L4          ; End of input buffer reached?
    cpy inputBufUsed
    bcs L4          ; End of input buffer reached?
    lda (ptr1),y    ; Look at the next character
    cmp #' '        ; Is it a space?
    bne L5          ; Not a space
    iny             ; Go to the next character
    jmp L3
L4:
    jsr getline     ; read another input line
    ldy #0          ; Reset buffer position
    jmp L2
L5:
    cmp #'-'        ; Is the first character a dash?
    bne L6          ; Not a dash
    sta intBuf      ; Store the minus sign in intBuf
    ldx #1          ; Start at the 2nd char in intBuf
    iny             ; Skip to the next character in the input buffer
    jmp L7          ; Start reading digits
L6:
    ldx #0          ; Use X as an offset into the integer buffer
L7:
    cpy #INPUTBUFLEN - 1
    beq L8          ; End of input buffer reached
    lda (ptr1),y    ; Load next character from input buffer
    cmp #'0'
    bcc L8          ; Done if character below '0'
    cmp #'9'+1
    bcs L8          ; Done if character after '9'
    sta intBuf,x    ; Store the digit in intBuf
    iny             ; Move to next character in input buffer
    inx             ; Move to next spot in intBuf
    cmp #7          ; End of intBuf?
    bne L7          ; No.  Keep reading characters
L8:
    sty inputPos    ; Remember intPos
    jsr readInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc
