.include "cbm_kernal.inc"
.include "c64.inc"
.include "float.inc"

.import FPBASE, COMPLM, CALCPTR, MOVIND, ROTATL, ROTATR, pushax, DECBIN, FPD10, FPX10

.export FPOUT

FPOUT:
    lda #0
    sta FPBASE + IOEXPD ; Clear decimal exponent storage
    lda FPBASE + FPMSW  ; Is value to output negative?
    bmi OUTNEG          ; Yes, make positive and output minus
    lda #'+'            ; Else, set ASCII code for plus sign
    bne AHEAD1          ; Go display plus sign
OUTNEG:
    ldx #FPLSW          ; Set pointer to LS byte of FPACC
    ldy #$3             ; Set precision counter
    jsr COMPLM          ; Make FPACC positive
    lda #'-'            ; Set ASCII code for minus sign
AHEAD1:
    jsr CHROUT          ; Output sign of result
    lda #'0'            ; Set up ASCII zero
    jsr CHROUT          ; Output zero to display
    lda #'.'            ; Set up ASCII decimal point
    jsr CHROUT          ; Output decimal point
    dec FPBASE + FPACCE ; Decrement FPACC exponent
DECEXT:
    bpl DECEXD          ; If compensated, exponent >= 0
    lda #$4             ; Exponent negative, add four to FPACCE
    clc                 ; Clear carry for addition
    adc FPBASE + FPACCE ; Add four to FPACC exponent
    bpl DECOUT          ; If exponent >= 0, output mantissa
    jsr FPX10           ; Else, multiply mantissa by ten
DECREP:
    lda FPBASE + FPACCE ; Get exponent
    jmp DECEXT          ; Repeat test for >= 0
DECEXD:
    jsr FPD10           ; Multiply FPACC by 0.1
    jmp DECREP          ; Check status of FPACC exponent
DECOUT:
    ldy #IOSTR          ; Set up for move operation
    jsr CALCPTR         ; Calculate pointer
    jsr pushax          ; Store on parameter stack
    ldy #FPLSW          ; Set pointer to FPACC LS byte
    jsr CALCPTR         ; Calculate pointer
    jsr pushax          ; Store on parameter stack
    lda #$3             ; Set precision counter
    jsr MOVIND          ; Move FPACC to output registers
    lda #$0
    sta FPBASE + IOSTR3 ; Clear output register MS byte + 1
    ldx #IOSTR          ; Set pointer to LS byte
    ldy #$3             ; Set precision counter
    jsr ROTATL          ; Rotate to compensate for sign bit
    jsr DECBIN          ; Output register x 10, overflow in MS byte + 1
COMPEN:
    inc FPBASE + FPACCE ; Increment FPACC exponent
    beq OUTDIG          ; Output digit when compensation is done
    ldx #IOSTR3         ; Else, rotate right to compensate
    ldy #$4             ; For any remainder in binary exponent
    jsr ROTATR          ; Perform rotate right operation
    jmp COMPEN          ; Repeat loop until exponent = 0
OUTDIG:
    lda #$7             ; Set digit counter to seven
    sta FPBASE + CNTR   ; For output operation
    lda FPBASE + IOSTR3 ; Fetch BCD, see if first digit = zero
    beq ZERODG          ; Yes, check remainder of digits
OUTDGS:
    lda FPBASE + IOSTR3 ; Get BCD from output register
    ora #'0'            ; Form ASCII code for numbers
    jsr CHROUT          ; And output digit
DECRDG:
    dec FPBASE + CNTR   ; Decrement digit counter
    beq EXPOUT          ; = zero, done output exponent
    jsr DECBIN          ; Else, get next digit
    jmp OUTDGS          ; Form ASCII and output
ZERODG:
    dec FPBASE + IOEXPD ; Decrement exponent for skipping display
    lda FPBASE + IOSTR2 ; Check if mantissa = 0
    bne DECRDG          ; If not zero, continue output
    lda FPBASE + IOSTR1
    bne DECRDG
    lda FPBASE + IOSTR
    bne DECRDG
    lda #$0             ; Mantissa zero, clear exponent
    sta FPBASE + IOEXPD
    beq DECRDG          ; Before finishing display
EXPOUT:
    lda #'E'            ; Setup ASCII code for E
    jsr CHROUT          ; Display E for exponent
    lda FPBASE + IOEXPD ; Test if negative
    bmi EXOUTN          ; Yes, display minus sign and negate
    lda #'+'            ; No, set ASCII code for plus sign
    jmp AHEAD2          ; Display exponent value
EXOUTN:
    eor #$ff            ; Two's complement exponent
    sta FPBASE + IOEXPD ; To make negative value position
    inc FPBASE + IOEXPD ; For output of exponent value
    lda #'-'            ; Set ASCII code for minus sign
AHEAD2:
    jsr CHROUT          ; Output sign of exponent
    ldy #$0             ; Clear ten's counter
    lda FPBASE + IOEXPD ; Fetch exponent
SUB12:
    sec                 ; Set carry for subtraction
    sbc #$0a            ; Subtract ten's from exponent
    bmi TOMUCH          ; If minus, read for output
    sta FPBASE + IOEXPD ; Restore positive result
    iny                 ; Advance ten's counter
    jmp SUB12           ; Continue subtraction
TOMUCH:
    tya                 ; Put MS digit into A
    ora #'0'            ; Form ASCII code
    jsr CHROUT          ; Output ten's digit to display
    lda FPBASE + IOEXPD ; Fetch unit's digit
    ora #'0'            ; Form ASCII code
    jmp CHROUT          ; Output digit and return
