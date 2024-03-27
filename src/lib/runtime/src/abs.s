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

.import absInt8, absInt16, absInt32, floatAbs, pusheax

.proc abs
    cmp #TYPE_SHORTINT
    beq L8
    cmp #TYPE_INTEGER
    beq L16
    cmp #TYPE_LONGINT
    beq L32

    ; Real
    jsr rtPopToReal
    jsr floatAbs
    jmp rtPushReal
    rts

    ; 8-bit
L8:
    jsr rtPopToIntOp1
    jsr absInt8
    jmp rtPushFromIntOp1

    ; 16-bit
L16:
    jsr rtPopToIntOp1
    jsr absInt16
    jmp rtPushFromIntOp1

    ; 32-bit
L32:
    jsr rtPopToIntOp1And2
    jsr absInt32
    jmp rtPushFromIntOp1And2
.endproc
