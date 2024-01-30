.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp multInt16

; end of exports
.byte $00, $00, $00

; imports

absInt16: jmp $0000
invertInt16: jmp $0000
swapInt16: jmp $0000
multUint16: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

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

