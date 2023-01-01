; Floating point routines
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"

.import COMPLM, ROTATL, ROTL, ROTATR, ROTR, MOVIND, ADDER, CLRMEM, CALCPTR
.importzp ptr1, ptr2

.export FPNORM, FPMULT, FPADD, FPDIV, FPSUB
.export FPBASE, FPBUF

.bss

FPBASE: .res 44
FPBUF: .res FPBUFSZ

.code

; This routine normalizes the number in FPACC.  A number is normalized
; when the mantissa's most significant "1" is to the right of the
; implied binary point.

.proc FPNORM
    ldx #TSIGN
    lda FPBASE + FPMSW  ; Fetch FPACC most-significant byte
    bmi ACCMIN          ; If negative, branch
    pha
    lda #0              ; If positive, clear sign register
    sta FPBASE,x        ; by storing zero
    tay
    pla
    jmp ACZERT          ; Then test if FPACC=0
ACCMIN:
    sta FPBASE,x        ; Set sign indicator if minus
    ldy #4              ; Set precision counter
    ldx #FPLSWE
    jsr COMPLM          ; Two's complement FPACC
ACZERT:
    ldx #FPMSW
    ldy #4
LOOK0:
    lda FPBASE,x        ; See if FPACC = 0
    bne ACNONZ          ; Branch if non-zero
    dex                 ; Decrement index pointer
    dey                 ; Decrement byte counter
    bne LOOK0           ; If counter not zero, continue
    sty FPBASE + FPACCE ; FPACC = 0, clear exponent too
NORMEX:
    rts                 ; Exit normalization routine
ACNONZ:
    ldx #FPLSWE
    ldy #4              ; Set precision counter
    jsr ROTATL          ; Rotate FPACC left
    lda FPBASE,x        ; See if one is most-significant bit
    bmi ACCSET          ; If minus, properly justified
    dec FPBASE + FPACCE ; If position, decrement FPACC exponent
    jmp ACNONZ          ; Continue rotating
ACCSET:
    ldx #FPMSW
    ldy #3              ; Set precision counter
    jsr ROTATR          ; Compensating rotate right FPACC
    lda FPBASE + TSIGN  ; Is original sign positive?
    beq NORMEX          ; Yes, simply return
    ldy #3
    jmp COMPLM          ; Restore FPACC to negative and return
.endproc

; This routine adds FPOP to FPACC and leaves the result in FPACC.
; FPOP is also modified.

.proc FPADD
    lda FPBASE + FPMSW  ; See if FPACC most-significant byte = 0
    bne NONZAC          ; Branch if not zero
MOVOP:
    ldx #FOPLSW         ; Set pointer to FPOP LS byte
    stx FPBASE + FMPNT  ; Save in FMPNT
    ldx #FPLSW          ; Set pointer to FPACC LS byte
    stx FPBASE + TOPNT  ; Save in TOPNT
    ldx #$04            ; Set precision counter
    jmp MOVIND          ; Move FPOP to FPACC and return
NONZAC:
    lda FPBASE + FOPMSW ; See if FPOP most-significant byte = 0
    bne CKEQEX          ; No, check exponents
    rts                 ; Yes, return result = FPACC
CKEQEX:
    ldx #FPACCE         ; Set pointer to FPACC exponent
    lda FPBASE,x        ; Fetch FPACC exponent
    cmp FPBASE + FOPEXP ; Is it equal to FPOP exponent?
    beq SHACOP          ; Branch ahead if equal
    sec                 ; If not equal, determine which is larger
    lda #0              ; Form the two's complement
    sbc FPBASE,x        ; of the FPACC exponent
    adc FPBASE + FOPEXP ; Add in FPOP exponent
    bpl SKPNEG          ; If positive FPOP > FPACC
    sec                 ; If negative form two's complement
    sta FPBASE + TEMP1  ; of the result
    lda #0              ; This will be used to test the
    sbc FPBASE + TEMP1  ; Magnitude of the difference in exponents
SKPNEG:
    cmp #$18            ; Is difference < 18 hexadecimal?
    bmi LINEUP          ; If so, align the mantissas
    sec                 ; If not, is the FPOP > FPACC?
    lda FPBASE + FOPEXP ; This is tested by comparing
    sbc FPBASE,x        ; The exponents of each
    bpl MOVOP           ; FPOP larger, move FPOP to FPACC
    rts                 ; FPACC larger, return
LINEUP:
    lda FPBASE + FOPEXP ; Fetch FPOP exponent
    sec                 ; Set carry for subtraction
    sbc FPBASE,x        ; Subtract FPOP-FPACC exponents
    tay                 ; Save difference in Y
    bmi SHIFTO          ; If negative, FPACC >, shift FPOP
MORACC:
    ldx #FPACCE
    jsr SHLOOP          ; Shift FPACC to right, one bit
    dey                 ; Decrement difference counter
    bne MORACC          ; If not zero, continue
    jmp SHACOP          ; When zero, set up for addition
SHIFTO:
    ldx #FOPEXP
    jsr SHLOOP          ; Shift FPOP to right, one bit
    iny                 ; Increment difference counter
    bne SHIFTO          ; Not zero, countinue
SHACOP:
    lda #0              ; Prepare for addition
    sta FPBASE + FPLSWE ; Clear FPACC least-significant byte - 1
    sta FPBASE + FOLSWE ; Clear FPOP least-significant byte - 1
    ldx #FPACCE         ; Set pointer to FPACC exponent
    jsr SHLOOP          ; Rotate FPACC right to allow for overflow
    ldx #FOPEXP         ; Set pointer to FPOP exponent
    jsr SHLOOP          ; Rotate FPOP right to keep alignment
    ldx #FOLSWE         ; Set pointer to FPOP least-significant byte - 1
    stx FPBASE + FMPNT  ; Store in FMPNT
    ldx #FPLSWE         ; Set pointer to FPACC least-significant byte - 1
    stx FPBASE + TOPNT  ; Store in TOPNT
    ldx #$04            ; Set precision counter
    jsr ADDER           ; Add FPOP to FPACC
    jmp FPNORM          ; Normalize result and return
SHLOOP:
    inc FPBASE,x        ; Increment exponent value
    dex                 ; Decrement pointer
    tya                 ; Save difference counter
    ldy #4              ; Set precision counter
FSHIFT:
    pha                 ; Store difference counter on stack
    lda FPBASE,x        ; Fetch most-significant byte of value
    bmi BRING1          ; If negative, must rotate one in MSB
    jsr ROTATR          ; Positive, rotate value right one bit
    jmp RESCNT          ; Return to calling program
BRING1:
    sec                 ; Set carry to maintain minus
    jsr ROTR            ; Rotate value right one bit
RESCNT:
    pla                 ; Fetch difference counter
    tay                 ; Restore in Y
    rts                 ; Return
.endproc

; This routine subtracts FPOP from FPACC and leaves the result in FPACC.
; FPOP is also modified.

.proc FPSUB
    ldx #FPLSW          ; Set pointer to FPACC least-significant byte
    ldy #3              ; Set precision counter
    jsr COMPLM          ; Complement FPACC
    jmp FPADD           ; Subtract by adding negative
.endproc

; This routine multiplies FPACC by FPOP and leaves the result in FPACC.
; FPOP is also modified.

FPMULT:
    jsr CKSIGN          ; Set up and check sign of mantissa
    lda FPBASE + FOPEXP ; Get FPOP exponent
    clc                 ; Add FPOP exponent
    adc FPBASE + FPACCE ; to FPACC exponent
    sta FPBASE + FPACCE ; Save in FPACC exponent
    inc FPBASE + FPACCE ; Add one for algorithm compensation
SETMCT:
    lda #$17            ; Set bit counter
    sta FPBASE + CNTR   ; Store bit counter
MULTIP:
    ldx #FPMSW          ; Set offset to FPACC most-significant byte
    ldy #3              ; Set precision counter
    jsr ROTATR          ; Rotate FPACC right
    bcc NADOPP          ; Carry = zero, don't add partial product
ADOPP:
    ldx #MCAND1         ; Pointer to least-significant byte of multiplicand
    stx FPBASE + FMPNT  ; Store pointer
    ldx #WORK1          ; Pointer to least-significant byte of partial product
    stx FPBASE + TOPNT  ; Store pointer
    ldx #$06             ; Set precision counter
    jsr ADDER           ; Add multiplicand to partial product
NADOPP:
    ldx #WORK6          ; Set pointer to most-significant byte of partial product
    ldy #6              ; Set precision counter
    jsr ROTATR          ; Rotate partial product right
    dec FPBASE + CNTR   ; Decrement bit counter
    bne MULTIP          ; Not zero, continue multiplying
    ldx #WORK6          ; Else, set pointer to partial product
    ldy #6              ; Set precision counter
    jsr ROTATR          ; Make room for possible rounding
    ldx #WORK3          ; Set pointer to 24th bit of partial product
    lda FPBASE,x        ; Fetch least significant byte minus 1 of result
    rol A               ; Rotate 24th bit to sign
    bpl PREXFR          ; If 24th bit = zero, branch ahead
    clc                 ; Clear carry for addition
    ldy #3              ; Set precision counter
    lda #$40            ; Add one to 23rd bit of partial product
    adc FPBASE,x        ; to round off result
    sta FPBASE + WORK3  ; Store sum in memory
CROUND:
    lda #0              ; Clear A without changing carry
    adc FPBASE,x        ; Add with carry to propogate
    sta FPBASE,x        ; Store in partial product
    inx                 ; Increment index pointer
    dey                 ; Decrement counter
    bne CROUND          ; Not zero. Add next byte
PREXFR:
    ldx #FPLSWE         ; Set pointer to FPACC LSW - 1
    stx FPBASE + TOPNT  ; Store in TOPNT
    ldx #WORK3          ; Set pointer to partial product LSW - 1
    stx FPBASE + FMPNT  ; Store in FMPNT
    ldx #$04            ; Set precision counter
EXMLDV:
    jsr MOVIND          ; Move partial-product to FPACC
    jsr FPNORM          ; Normalize result
    lda FPBASE + SIGNS  ; Get sign storage
    bne MULTEX          ; If not zero, sign is positive
    ldx #FPLSW          ; Else, set pointer to FPACC LS byte
    ldy #3              ; Set precision counter
    jsr COMPLM          ; Complement result
MULTEX:
    rts                 ; Exit FPMULT
CKSIGN:
    lda #WORK0          ; Set pointer to work area
    sta FPBASE + TOPNT  ; Store in TOPNT
    ldx #$8             ; Set precision counter
    jsr CLRMEM          ; Clear work area
    lda #MCAND0         ; Set pointer to multiplicand storage
    sta FPBASE + TOPNT  ; Store in TOPNT
    ldx #$4             ; Set precision counter
    jsr CLRMEM          ; Clear multiplicand storage
    lda #1              ; Initialize sign indicator
    sta FPBASE + SIGNS  ; By storing one in SIGNS
    lda FPBASE + FPMSW  ; Fetch FPACC MS byte
    bpl OPSGNT          ; Positive, check FPOP
NEGFPA:
    dec FPBASE + SIGNS  ; If negative, decrement signs
    ldx #FPLSW          ; Set pointer to FPACC LS byte
    ldy #3              ; Set precision counter
    jsr COMPLM          ; Make positive for multiplication
OPSGNT:
    lda FPBASE + FOPMSW ; Is FPOP negative?
    bmi NEGOP           ; Yes, complement value
    rts                 ; Else, return
NEGOP:
    dec FPBASE + SIGNS  ; Decrement SIGNS indicator
    ldx #FOPLSW         ; Set pointer to FPOP LS byte
    ldy #3              ; Set precision counter
    jmp COMPLM          ; Complement FPOP and return

; This routine divides FPACC by FPOP and leaves the result in FPACC.
; FPOP is also modified.

.proc FPDIV
    jsr CKSIGN          ; Clear work area and set SIGNS
    lda FPBASE + FPMSW  ; Check for divide by zero
    beq DERROR          ; Divisor = zero, divide by zero error
SUBEXP:
    lda FPBASE + FOPEXP ; Get DIVIDEND exponent
    sec                 ; Set carry for subtraction
    sbc FPBASE + FPACCE ; Subtract DIVISOR exponent
    sta FPBASE + FPACCE ; Store result in FPACC exponent
    inc FPBASE + FPACCE ; Compensate for divide algorithm
SETDCT:
    lda #$17            ; Set bit counter storage
    sta FPBASE + CNTR   ; to 17 hex
DIVIDE:
    jsr SETSUB          ; Subtrsct DIVISOR from DIVIDEND
    bmi NOGO            ; If result is minus, rotate zero in QUOTIENT
    ldx #FOPLSW         ; Set pointer to DIVIDEND
    stx FPBASE + TOPNT  ; Store in TOPNT
    ldx #WORK0          ; Set pointer to QUOTIENT
    stx FPBASE + FMPNT  ; Store in FMPNT
    ldx #$3             ; Set precision counter
    jsr MOVIND          ; Move QUOTIENT to DIVIDEND
    sec                 ; Set carry for positive results
    jmp QUOROT
DERROR:
    lda #'?'            ; Set ASCII for "?""
    jmp ERROUT          ; Print "?" and return
NOGO:
    clc                 ; Negative result, clear carry
QUOROT:
    ldx #WORK4          ; Set pointer to QUOTIENT LS byte
    ldy #3              ; Set precision counter
    jsr ROTL            ; Rotate carry into LSB of QUOTIENT
    ldx #FOPLSW         ; Set pointer to DIVIDEND LS byte
    ldy #3              ; Set precision counter
    jsr ROTATL          ; Rotate DIVIDEND left
    dec FPBASE + CNTR   ; Decrement bit counter
    bne DIVIDE          ; If not zero, continue
    jsr SETSUB          ; Do one more for rounding
    bmi DVEXIT          ; If minus, no rounding
    lda #1              ; If 0 or +, add one to 23rd bit
    clc                 ; Clear carry for addition
    adc FPBASE + WORK4  ; Round of LS byte of QUOTIENT
    sta FPBASE + WORK4  ; Restore byte in work area
    lda #0              ; Clear A, not the carry
    adc FPBASE + WORK5  ; Add carry to second byte of QUOTIENT
    sta FPBASE + WORK5  ; Store result
    lda #0              ; Clear A, not the carry
    adc FPBASE + WORK6  ; Add carry to MS byte of QUOTIENT
    sta FPBASE + WORK6  ; Store result
    bpl DVEXIT          ; If MSB = 0, exit
    ldx #WORK6          ; Else prepare to rotate right
    ldy #3              ; Set precision counter
    jsr ROTATR          ; Clear sign bit counter
    inc FPBASE + FPACCE ; Compensate exponent for rotate
DVEXIT:
    ldx #FPLSWE         ; Set pointer to FPACC
    stx FPBASE + TOPNT  ; Store in TOPNT
    ldx #WORK3          ; Set pointer to QUOTIENT
    stx FPBASE + FMPNT  ; Store in FMPNT
    ldx #$04            ; Set precision counter
    jmp EXMLDV          ; Move QUOTIENT to FPACC
SETSUB:
    ldx #WORK0          ; Set pointer to work area
    stx FPBASE + TOPNT  ; Store in TOPNT
    ldx #FPLSW          ; Set pointer to FPACC
    stx FPBASE + FMPNT  ; Store in FMPNT
    ldx #$3             ; Set precision counter
    jsr MOVIND          ; Move FPACC to work area
    ldy #FOPLSW         ; Set pointer to FPOP LS byte - 1
    jsr CALCPTR         ; Calculate pointer
    sta ptr1            ; Save to ZP pointer 1
    stx ptr1 + 1
    ldy #WORK0          ; Prepare for subtraction
    jsr CALCPTR         ; Calculate pointer
    sta ptr2            ; Save to ZP pointer 2
    stx ptr2 + 1
    ldy #0              ; Initialize index pointer
    ldx #3              ; Set precision counter
    sec                 ; Set carry for subtraction
SUBR1:
    lda (ptr1),y        ; Fetch FPOP byte (DIVIDEND)
    sbc (ptr2),y        ; Subtract FPACC byte (DIVISOR)
    sta (ptr2),y        ; Store in place of DIVISOR
    iny                 ; Advance index pointer
    dex                 ; Decrement precision counter
    bne SUBR1           ; Not zero, continue subtraction
    lda FPBASE + WORK2  ; Set sign bit result in N flag
ERROUT:
    rts                 ; Return with flag conditioned
.endproc

