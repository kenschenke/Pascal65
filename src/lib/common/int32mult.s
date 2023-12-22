.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp tmp1
.import intOp1, intOp2, intOp32
.endif

.import absInt32, invertInt32, swapInt32, multUint32

.export multInt32

; This routine multiplies two signed 32-bit integers stored in intOp1/intOp2 and
; intOp32. The result is stored in intOp1/intOp2. It does not check for overflow.
;
; It checks the sign bits of each operand. If either is negative, the result
; is negative. If both are negative, the result is positive.
;
; It then takes the absolute value of both operands and calls multUint32
; then negates the result if either operand was negative.

.proc multInt32
    ; If both operands negative, result is negative.
    ; If both are negative, result is positive.
    lda intOp2 + 1
    and #$80                ; Isolate the sign bit
    sta tmp1                ; Store it in tmp1
    lda intOp32 + 3
    and #$80                ; Isolate the sign bit
    eor tmp1                ; Exclusive OR both sign bits
    pha                     ; A is non-zero if either is negative but not both
    ; Take the absolute value of both operands
    jsr absInt32
    jsr swapInt32
    jsr absInt32
    jsr multUint32
    pla                     ; Pull negative flag back off CPU stack
    beq :+                  ; Branch if result is not negative
    jsr invertInt32         ; Invert result
:   rts
.endproc
