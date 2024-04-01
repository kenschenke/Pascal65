;
; int16mult.s
; Ken Schenke (kenschenke@gmail.com)
; 
; 16-bit integer multiplication
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp tmp1
.import intOp1, intOp2
.endif

.import absInt16, invertInt16, swapInt16, multUint16

.export multInt16

; This routine multiplies two signed 16-bit integers stored in intOp1 and intOp2.
; The result is stored in intOp1.  It does not check for overflow.
;
; It checks the sign bits of each operand. If either is negative, the result
; is negative. If both are negative, the result is positive.
;
; It then takes the absolute value of both operands and calls multUint16
; then negates the result if either operand was negative.

.proc multInt16
    ; If intOp1 or intOp2 is negative, result is negative.
    ; If both are negative, result is positive.
    lda intOp1 + 1
    and #$80                ; Isolate the sign bit
    sta tmp1                ; Store it in tmp1
    lda intOp2 + 1
    and #$80                ; Isolate the sign bit
    eor tmp1                ; Exclusive OR both sign bits
    pha                     ; A is non-zero if either is negative but not both
    ; Take the absolute value of both operands
    jsr absInt16
    jsr swapInt16
    jsr absInt16
    jsr multUint16
    pla                     ; Pull negative flag back off CPU stack
    beq :+                  ; Branch if result is not negative
    jsr invertInt16         ; Invert result
:   rts
.endproc

