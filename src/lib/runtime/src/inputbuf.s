.include "inputbuf.inc"
.include "float.inc"
.include "runtime.inc"

.import getline, readInt16, FPINP

.export clearInputBuf, isInputEndOfLine, readCharFromInput
.export readFloatFromInput, readIntFromInput, inputBuf, inputBufUsed

.bss

inputBuf: .res INPUTBUFLEN
inputBufUsed: .res 1
inputPos: .res 1
sawDecimalPoint: .res 1
sawExponent: .res 1
sawExponentSign: .res 1

.code

.proc clearInputBuf
    lda #0
    sta inputBufUsed
    sta inputPos
    rts
.endproc

.proc isInputEndOfLine
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

.proc readCharFromInput
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

; Reads a floating point number from inputBuf, calls FPINP, and leaves it in FPACC
.proc readFloatFromInput
    ; Clear a few variables first
    lda #0
    sta sawDecimalPoint
    sta sawExponent
    sta sawExponentSign
    ; Clear FPBUF
    lda #<FPBUF
    sta ptr1
    lda #>FPBUF
    sta ptr1 + 1
    ldy #FPBUFSZ - 1
    lda #0
L1:
    sta (ptr1),y
    dey
    bpl L1

    ; Skip spaces in input
    jsr skipSpaces  ; Skip spaces in input buffer
    ldy inputPos    ; Load inputPos into Y
    lda (ptr1),y
    cmp #'-'        ; Is the first character a dash?
    bne L2          ; Not a dash
    sta FPBUF       ; Store the minus sign in intBuf
    ldx #1          ; Start at the 2nd char in intBuf
    iny             ; Skip to the next character in the input buffer
    jmp L3          ; Start reading digits
L2:
    ldx #0          ; Use X as an offset into the floating point string buffer
L3:
    cpy #INPUTBUFLEN - 1
    beq L11         ; End of input buffer reached
    lda (ptr1),y    ; Load next character from input buffer
    cmp #'.'        ; Compare to decimal point
    bne L4          ; Not a decimal point
    lda sawDecimalPoint
    bne L11         ; Already saw a decimal point - done with input
    lda (ptr1),y    ; Load the decimal back into A
    sta FPBUF,x     ; Store the decimal point in FPBUF
    lda #1
    sta sawDecimalPoint
    jmp L10         ; Move to the next character
L4:
    cmp #'e'        ; Is the char 'e'?
    beq L5          ; Yes
    cmp #'E'        ; Is the char 'E'?
    bne L6          ; No
L5:                 ; Character is 'e' or 'E'
    lda sawExponent
    bne L11         ; Already saw an 'e' or 'E' - done with input
    lda (ptr1),y    ; Load the 'e' or 'E' back into A
    sta FPBUF,x     ; Store it in FPBUF
    lda #1
    sta sawExponent
    jmp L10         ; Move to the next character
L6:
    cmp #'-'        ; Is the char '-'?
    beq L7          ; Yes
    cmp #'+'        ; Is the char '+'?
    bne L9
L7:                 ; Character is '-' or '+'
    lda sawExponent
    beq L11         ; Did not see 'e' or 'E' so this isn't part of the number
    lda sawExponentSign
    bne L11         ; Already saw an exponent sign
    lda (ptr1),y    ; Load the sign back into A
    sta FPBUF,x     ; Store it in FPBUF
    lda #1
    sta sawExponentSign
    jmp L10
L9:
    cmp #'0'
    bcc L11         ; Done if character below '0'
    cmp #'9'+1
    bcs L11         ; Done if character after '9'
    sta FPBUF,x     ; Store the digit in FPBUF
L10:
    iny             ; Move to next character in input buffer
    inx             ; Move to next spot in FPBUF
    cmp #FPBUFSZ    ; End of FPBUF?
    bne L3          ; No.  Keep reading characters
L11:
    sty inputPos    ; Remember input position
    jmp FPINP       ; Parse FPBUF into FPACC
.endproc

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
    sty inputPos
    txa
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

; This routine skips ahead to the first non-space in the input
; buffer.  If it reaches the end of the input line it will read
; the next line, and so on until it finds a non-space.
.proc skipSpaces
    ldy inputPos
L1:
    lda #<inputBuf
    sta ptr1
    lda #>inputBuf
    sta ptr1 + 1
L2:
    cpy #INPUTBUFLEN - 1
    beq L3          ; End of input buffer reached?
    cpy inputBufUsed
    bcs L3          ; End of input buffer reached?
    lda (ptr1),y    ; Look at the next character
    cmp #' '        ; Is it a space?
    bne L4          ; Not a space
    iny             ; Go to the next character
    jmp L2
L3:
    jsr getline     ; read another input line
    ldy #0          ; Reset buffer position
    jmp L1
L4:
    sty inputPos    ; Put Y back into inputPos
    rts
.endproc
