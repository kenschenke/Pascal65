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

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp sqr

; end of exports
.byte $00, $00, $00

; imports

int32Sqr: jmp $0000
floatSqr: jmp $0000
signExtend8To32: jmp $0000
signExtend16To32: jmp $0000
popToIntOp1: jmp $0000
popToIntOp1And2: jmp $0000
popToReal: jmp $0000
pushFromIntOp1And2: jmp $0000
pushRealStack: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

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
