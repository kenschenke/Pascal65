; Routine to divide one floating point number by another.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"

.import FPBASE, CALCPTR, EXMLDV, ROTATR, ROTATL, ROTL, MOVIND, CKSIGN
.importzp ptr1, ptr2

.export FPDIV

; This routine divides FPACC by FPOP and leaves the result in FPACC.
; FPOP is also modified.
;
; This routine checks for divide by zero and just returns zero.
; Any special handling for divide by zero is to be handled elsewhere.

.proc FPDIV
    lda #FPLSW          ; Set pointer to FPACC
    sta FPBASE + FMPNT  ; Store in FMPNT
    lda #WORK0          ; Set pointer to work area
    sta FPBASE + TOPNT  ; Store in TOPNT
    ldx #$04            ; Move four bytes
    jsr MOVIND          ; Move FPACC to work area
    lda #FOPLSW         ; Set pointer to FPOP
    sta FPBASE + FMPNT  ; Store in FMPNT
    lda #FPLSW          ; Set pointer to FPACC
    sta FPBASE + TOPNT  ; Store in TOPNT
    ldx #$04            ; Move four bytes
    jsr MOVIND          ; Move FPOP to FPACC
    lda #WORK0          ; Set pointer to work area
    sta FPBASE + FMPNT  ; Store in FMPNT
    lda #FOPLSW         ; Set pointer to FPOP
    sta FPBASE + TOPNT  ; Store in TOPNT
    ldx #$04            ; Move four bytes
    jsr MOVIND          ; Move work area to FPOP
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

