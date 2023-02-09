; Routine to parse a floating number from a string.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"

.import FPBASE, CLRMEM, ADDER, ROTATL, FPMULT, MOVIND, COMPLM, FPNORM, FPBUF, XBUF
.export FPINP, DECBIN, FPD10, FPX10

; This routine reads a floating point number from FPBUF into FPACC.
; It supports standard floating point format (1, 2.25)
; and scientific notation (1.2E+5 or 0.1E-4).

FPINP:
    cld                 ; Clear decimal mode flag
    ldx #INMTAS         ; Set pointer to storage area
    stx FPBASE + TOPNT  ; Store in TOPNT
    ldx #$0c            ; Set precision counter
    jsr CLRMEM          ; Clear storage area
    ldx #$00            ; Clear A
    stx XBUF            ; Clear the buffer index
    lda FPBUF,x         ; Get the first character from the buffer
    inc XBUF            ; Increment counter
    cmp #'+'            ; Test if plus sign
    beq NINPUT          ; Yes, continue
    cmp #'-'            ; Test if minus sign
    bne NOTPLM          ; No, test if valid character
    sta FPBASE + INMTAS ; Make input sign nonzero
NINPUT:
    ldx XBUF
    lda FPBUF,x         ; Get the next character from the buffer
    inc XBUF            ; Increment index
NOTPLM:
    cmp #'.'            ; Test for decimal point
    bne SPRIOD          ; No, skip period
PERIOD:
    bit FPBASE + INPRDI ; Set decimal pointer indicator
    bpl PER1            ; No decimal point yet, continue
    bmi ISLAND          ; Yes, end input
PER1:
    sta FPBASE + INPRDI ; Set decimal pointer indicator
    ldy #0
    sty FPBASE + CNTR   ; Reset digit counter
    jmp NINPUT          ; Get next character
SPRIOD:
    cmp #'E'            ; Test E for exponent
    beq FNDEXP          ; Yes, parse Exponent
    cmp #'e'            ; Test e for exponent
    bne SFNDXP          ; No, skip Exponent
FNDEXP:
    ldx XBUF            ; Load the buffer index
    lda FPBUF,x         ; Get the next character
    inc XBUF            ; Increment the index
    cmp #'+'            ; Test for plus sign
    beq EXPINP          ; Yes
    cmp #'-'            ; Test for minus sign
    bne NOEXPS          ; No, test for digit
    sta FPBASE + INEXPS ; Yes, store minus character
EXPINP:
    ldx XBUF            ; Load buffer index
    lda FPBUF,x         ; Get next character
    inc XBUF            ; Increment the index
NOEXPS:
    cmp #'0'            ; Number, test low limit
ISLAND:
    bmi ENDINP          ; No, end input string
    cmp #'9' + 1        ; Test upper limit
    bpl ENDINP          ; No, end input string
    and #$0f            ; Mask and strip ASCII
    sta FPBASE + TEMP1  ; Store BCD in temporary storage
    ldx #IOEXPD         ; Set pointer to exponent storage
    lda #$03            ; Test for upper limit of exponent
    cmp FPBASE,x        ; Is ten's digit > 3?
    bmi ENDINP          ; Yes, end input
    lda FPBASE,x        ; Store temporarily in A
    clc                 ; Clear carry
    rol FPBASE,x        ; Exponent x 2
    rol FPBASE,x        ; Exponent x 4
    adc FPBASE,x        ; Add original (x 5)
    rol A               ; Exponent x 10
    adc FPBASE + TEMP1  ; Add new input
    sta FPBASE,x        ; Store in exponent storage
    lda #'0'            ; Restore ASCII code
    ora FPBASE + TEMP1  ; By OR'ing with the value
    bne EXPINP          ; Next digit
SFNDXP:
    cmp #'0'            ; Test for valid number
    bmi ENDINP          ; Too low, end input
    cmp #'9' + 1        ; Test for upper limit
    bpl ENDINP          ; If not valid, end input
    tay                 ; Save temporarily
    lda #$f8            ; Input too large?
    bit FPBASE + IOSTR2 ; Test for too large
    bne JNINPUT         ; Yes, ignore present input
    tya                 ; No, fetch digit again
    inc FPBASE + CNTR   ; Increment digit counter
    and #$0f            ; Mask off ASCII
    pha                 ; Save BCD digit temporarily
    jsr DECBIN          ; Multiply previous value x 10
    ldx #IOSTR          ; Set pointer to storage
    pla                 ; Fetch digit just entered
    clc                 ; Clear carry for addition
    adc FPBASE,x        ; Add digit to storage
    sta FPBASE,x        ; Save new total
    lda #$0             ; Clear A for next addition
    adc FPBASE+1,x      ; Add carry to next byte
    sta FPBASE+1,x      ; Save new total
    lda #$0             ; Clear A again for addition
    adc FPBASE+2,x      ; Add carry to final byte
    sta FPBASE+2,x      ; Save final byte of total
JNINPUT:
    jmp NINPUT          ; Look for next character input
ENDINP:
    lda FPBASE + INMTAS ; Test is positive or negative
    beq FINPUT          ; Indicator zero, number positive
    ldx #IOSTR          ; Index to LSB of input mantissa
    ldy #$03            ; Set precision counter
    jsr COMPLM          ; Two's complement for negative
FINPUT:
    lda #$0
    sta FPBASE + IOSTR - 1  ; Clear input storage LSB - 1
    lda #FPLSWE         ; Set destination to FPACC
    sta FPBASE + TOPNT  ; Set TOPNT to FPACC
    lda #IOSTR - 1      ; Set source to input storage
    sta FPBASE + FMPNT  ; Set byte counter
    ldx #$04            ; Number of bytes to move
    jsr MOVIND          ; Move input to FPACC
    ldy #$17            ; Set exponent for normalization
    sty FPBASE + FPACCE ; Normalize the input
    jsr FPNORM          ; Test exponent sign indicator
    lda FPBASE + INEXPS ; Positive? Same exponent
    beq POSEXP          ; Minus, form two's complement
    lda #$ff            ; Of exponent value
    eor FPBASE + IOEXPD ; By complementing and incrementing
    sta FPBASE + IOEXPD
    inc FPBASE + IOEXPD ; Test period indicator
POSEXP:
    lda FPBASE + INPRDI
    beq EXPOK           ; If zero, no decimal point
    lda #$0             ; Clear A
    sec                 ; Set carry for subtraction
    sbc FPBASE + CNTR   ; Form negative of count
EXPOK:
    clc                 ; Clear carry for addition
    adc FPBASE + IOEXPD ; Add to compensate for decimal point
    sta FPBASE + IOEXPD ; Store results
    bmi MINEXP          ; Negative exponent, adjust to zero
    bne EXPFIX          ; Not zero, adjust to zero
    rts                 ; Return with value in FPACC
EXPFIX:
    jsr FPX10           ; Multiply by ten
    bne EXPFIX          ; Exponent not zero, multiply again
    rts                 ; Return
FPX10:
    lda #$04            ; Multiply FPACC x 10
    sta FPBASE + FOPEXP ; Load FPOP with a value of ten
    lda #$50            ; By setting the exponent to four
    sta FPBASE + FOPMSW ; And the mantissa to $50,$00,$00
    lda #$00
    sta FPBASE + FOPNSW
    sta FPBASE + FOPLSW
    jsr FPMULT          ; Multiply FPACC x FPOP
    dec FPBASE + IOEXPD ; Decrement decimal exponent
    rts                 ; Return to test for completion
MINEXP:
    jsr FPD10           ; Compensated decimal exponent minus
    bne MINEXP          ; FPACC x 0.1 until decimal exponent = zero
    rts                 ; Return
FPD10:
    lda #$fd            ; Place 0.1 in FPOP by
    sta FPBASE + FOPEXP ; Setting FPOP exponent to -3
    lda #$66            ; And loading mantissa with $66,$66,$67
    sta FPBASE + FOPMSW
    sta FPBASE + FOPNSW
    lda #$67
    sta FPBASE + FOPLSW
    jsr FPMULT          ; Multiply FPACC x FPOP
    inc FPBASE + IOEXPD ; Increment decimal exponent
    rts                 ; Return
DECBIN:
    lda #$0
    sta FPBASE + IOSTR3 ; Clear MS byte + 1 of result
    ldx #IOLSW          ; Set pointer to I/O work area
    stx FPBASE + TOPNT  ; Store in TOPNT
    ldx #IOSTR          ; Set pointer to I/O storage
    stx FPBASE + FMPNT  ; Store in FMPNT
    ldx #$04            ; Set precision counter
    jsr MOVIND          ; Move I/O storage to work area
    ldx #IOSTR          ; Set pointer to original value
    ldy #$04            ; Set precision counter
    jsr ROTATL          ; Start X 10 routine (total = X2)
    ldx #IOSTR          ; Reset pointer
    ldy #$04            ; Set precision counter
    jsr ROTATL          ; Multiply by two again (total = X4)
    ldx #IOLSW          ; Set pointer to I/O work area
    stx FPBASE + FMPNT  ; Store in FMPNT
    ldx #IOSTR          ; Set pointer to I/O storage
    stx FPBASE + TOPNT  ; Store in TOPNT
    ldx #$04            ; Set precision counter
    jsr ADDER           ; Add original to rotated (X5)
    ldx #IOSTR          ; Reset pointer
    ldy #$04            ; Set precision counter
    jmp ROTATL          ; X2 again (total = X10) and return
