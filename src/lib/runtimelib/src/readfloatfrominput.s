.include "inputbuf.inc"
.include "runtime.inc"
.include "float.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp readFloatFromInput

; end of exports
.byte $00, $00, $00

; imports

FPINP: jmp $0000
skipSpaces: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

sawDecimalPoint: .res 1
sawExponent: .res 1
sawExponentSign: .res 1

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
    lda (inputBuf),y
    cmp #'-'        ; Is the first character a dash?
    bne L2          ; Not a dash
    sta FPBUF       ; Store the minus sign in intBuf
    ldx #1          ; Start at the 2nd char in intBuf
    iny             ; Skip to the next character in the input buffer
    bne L3          ; Start reading digits
L2:
    ldx #0          ; Use X as an offset into the floating point string buffer
L3:
    cpy #INPUTBUFLEN - 1
    beq L11         ; End of input buffer reached
    lda (inputBuf),y    ; Load next character from input buffer
    cmp #'.'        ; Compare to decimal point
    bne L4          ; Not a decimal point
    lda sawDecimalPoint
    bne L11         ; Already saw a decimal point - done with input
    lda (inputBuf),y    ; Load the decimal back into A
    sta FPBUF,x     ; Store the decimal point in FPBUF
    lda #1
    sta sawDecimalPoint
    bne L10         ; Move to the next character
L4:
    cmp #'e'        ; Is the char 'e'?
    beq L5          ; Yes
    cmp #'E'        ; Is the char 'E'?
    bne L6          ; No
L5:                 ; Character is 'e' or 'E'
    lda sawExponent
    bne L11         ; Already saw an 'e' or 'E' - done with input
    lda (inputBuf),y    ; Load the 'e' or 'E' back into A
    sta FPBUF,x     ; Store it in FPBUF
    lda #1
    sta sawExponent
    bne L10         ; Move to the next character
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
    lda (inputBuf),y    ; Load the sign back into A
    sta FPBUF,x     ; Store it in FPBUF
    lda #1
    sta sawExponentSign
    bne L10
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
