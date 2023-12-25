; This routine is part of the Pascal runtime and squares
; the integer or real.  The routine expects the value to
; be at the top of the runtime stack and leaves the
; sqaured value in its place.
;
; The data type of the input value is passed in A.  Values
; are defined in types.inc.

.include "types.inc"

.include "runtime.inc"
.include "float.inc"

.export sqr
.import int32Sqr, floatSqr, signExtend8To32, signExtend16To32
.import popToIntOp1, popToIntOp1And2, popToReal
.import pushFromIntOp1And2, pushRealStack

.import pusheax

.proc sqr
    cmp #TYPE_BYTE
    beq L8U
    cmp #TYPE_SHORTINT
    beq L8
    cmp #TYPE_WORD
    beq L16U
    cmp #TYPE_INTEGER
    beq L16
    cmp #TYPE_CARDINAL
    beq L32
    cmp #TYPE_LONGINT
    beq L32

    ; Real
    jsr popToReal
    jsr floatSqr
    jmp pushRealStack

    ; 8-bit
L8:
    jsr popToIntOp1
    jsr signExtend8To32
    clc
    bcc Finish

L8U:
    jsr popToIntOp1
    clc
    bcc Finish

    ; 16-bit
L16:
    jsr popToIntOp1
    jsr signExtend16To32
    clc
    bcc Finish

L16U:
    jsr popToIntOp1
    clc
    bcc Finish

    ; 32-bit
L32:
    jsr popToIntOp1And2

Finish:
    jsr int32Sqr
    jmp pushFromIntOp1And2
.endproc
