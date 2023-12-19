; This routine is part of the Pascal runtime and calculates
; the absolute value of an integer or real.  The routine
; expects the value to be at the top of the runtime stack
; and leaves the absolute value in its place.
;
; The data type of the input value is passed in A.  Values
; are defined in types.inc.

.include "types.inc"

.include "runtime.inc"

.export abs
.import absInt8, absInt16, absInt32, floatAbs
.import popToIntOp1, popToIntOp1And2, popToReal
.import pushFromIntOp1, pushFromIntOp1And2, pushRealStack

.import pusheax

.proc abs
    cmp #TYPE_SHORTINT
    beq L8
    cmp #TYPE_INTEGER
    beq L16
    cmp #TYPE_LONGINT
    beq L32

    ; Real
    jsr popToReal
    jsr floatAbs
    jmp pushRealStack
    rts

    ; 8-bit
L8:
    jsr popToIntOp1
    jsr absInt8
    jmp pushFromIntOp1

    ; 16-bit
L16:
    jsr popToIntOp1
    jsr absInt16
    jmp pushFromIntOp1

    ; 32-bit
L32:
    jsr popToIntOp1And2
    jsr absInt32
    jmp pushFromIntOp1And2
.endproc
