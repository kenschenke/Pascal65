;
; floatadd.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Routine to add two floating point numbers.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"
.include "runtime.inc"

.export FPADD

.import ROTR, ROTATR, FPNORM, ADDER, MOVIND

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
