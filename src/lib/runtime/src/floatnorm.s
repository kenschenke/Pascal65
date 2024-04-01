;
; floatnorm.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to normalize a floating number.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"
.include "runtime.inc"

.export FPNORM

.import ROTATR, ROTATL, COMPLM

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
