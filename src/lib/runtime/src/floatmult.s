;
; floatmult.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Routine to multiply one floating number by another.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"
.include "runtime.inc"

.export FPMULT, EXMLDV, CKSIGN

.import CLRMEM, COMPLM, FPNORM, MOVIND, ADDER, ROTATR

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

