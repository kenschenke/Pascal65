; A BCD to Floating-Point Binary Routine
; Marvin L. De Jong
; from Compute! Issue 9 / February 1981 / Page 46

; A Floating-Point Binary to BCD Routine
; Marvin L. De Jong
; from Compute! Issue 11 / April 1981 / Page 66

.importzp ptr1, ptr2, tmp1
.import popa, popax

.bss

OVFLO   .res 1  ; overflow byte for the accumulator when it is shiftef left or multiplied by ten.
MSB     .res 1  ; most-significant byte of the accumulator
NMSB    .res 1  ; next-most-significant byte of the accumulator.
NLSB    .res 1  ; next-least-significant byte of the accumulator.
LSB     .res 1  ; least-significant byte of the accumulator
BEXP    .res 1  ; contains the binary exponent, bit seven is the sign bit.
CHAR    .res 1  ; used to store the character input from the keyboard.
MFLAG   .res 1  ; set to $FF when a minus sign is entered.
DPFLAG  .res 1  ; decimal point flag, set when decimal point is entered.
ESIGN   .res 1  ; set to $FF when a minus sign is entered for the exponent.
MEM     .res 1  ; ???
ACC     .res 1  ; ???
ACCB    .res 1  ; ???
TEMP    .res 1  ; temporary storage location
EVAL    .res 1  ; value of the decimal exponent entered after the "E."
DEXP    .res 1  ; current value of the decimal exponent
BCDA    .res 5  ; BCD accumulator (5 bytes)
BCDN    .res 1  ; ???

.code

; Floating-Point Binary to BCD Routine
; floatToBCD(unsigned char *acc, unsigned char minusFlag, unsigned char *buf, char buflen)
;       acc:
;           points to four byte accumulator buffer
;       minusFlag:
;           $FF if minus sign
;       buf:
;           points to caller-supplied buffer to receive output BCD
;       buflen:
;           length of caller's buffer
;
; On entry, buflen is in .A and the other params are on the stack
floatToBCD:
    sta tmp1    ; store the caller's buflen
    jsr popax   ; pull the buf pointer into .A and .X
    sta ptr2
    stx ptr2+1
    jsr popa    ; pull the minusFlag from the stack
    sta MFLAG   ; store minusFlag
    jsr popax   ; pull the acc pointer into .A and .X
    sta ptr1    ; LSB of acc pointer in ptr1
    stx ptr1+1  ; MSB of acc pointer in ptr1 + 1
    ; store the four bytes from the acc
    ldy #3
    lda (ptr1),y
    sta LSB
    dey
    lda (ptr1),y
    sta NLSB
    dey
    lda (ptr1),y
    sta NMSB
    dey
    lda (ptr1),y
    sta MSB
    ; zero out the caller's buffer
    ldy tmp1
    dey
    lda #0
@LoopBufZero:
    sta (ptr2),y
    dey
    bne @LoopBufZero

    lda MSB     ; Test MSB to see if mantissa is zero.
    BNE BRT     ; If it is, emit a zero then get out.
    lda #'0'    ; Get ASCII zero.
    sta (ptr2),y
    rts
BRT:
    lda #$0     ; Clear OVFLO location
    sta OVFLO
BRY:
    lda BEXP    ; Is the binary exponent negative?
    bpl BRZ     ; No.
    jsr TENX    ; Yes. Multiply by ten until the exponent is not negative
    jsr NORM
    dec DEXP    ; Decrement decimal exponent
    clv         ; force a jump
    bvc BRY     ; repeat
BRZ:
    lda BEXP    ; Compare the binary exponent to
    cmp #$20    ; $20 = 32
    beq BCD     ; Equal. Convert binary to BCD
    bcc BRX1    ; Less than.
    jsr DIVTEN  ; Greater than. Divide by ten until BEXP is less than 32.
    inc DEXP
    clv         ; Force a jump.
    bvc BRZ
BRX1:
    lda #$00    ; Clear OVFLO
    sta OVFLO
BRW:
    jsr TENX    ; Multiple by ten.
    jsr NORM    ; Then normalize.
    dec DEXP    ; Decrement decimal exponent.
    lda BEXP    ; Test binary exponent
    cmp #$20    ; Is it 32?
    beq BCD     ; Yes.
    bcc BRW     ; It's less than 32 so multiply by 10.
    jsr DIVTEN  ; It's greater than 32 so divide.
    inc DEXP    ; Increment decimal exponent
BRU:
    lda BEXP    ; Test binary exponent.
    cmp #$20    ; Compare with 32.
    beq BRV     ; Shift mantissa right until exponent
    lsr MSB     ; is 32.
    ror NMSB
    ror NLSB
    ror LSB
    ror TEMP    ; Least-significant bit into TEMP.
    inc BEXP    ; Increment exponent for each shift
    clv         ; right.
    bvc BRU
BRV:
    lda TEMP    ; Test to see if we need to round
    bpl BCD     ; up. No.
    sec         ; Yes. Add one to mantissa.
    ldx #$04
BRS:
    lda ACC,x   ; invalid address mode!
