; This routine is part of the Pascal runtime and calculates
; the absolute value of an integer or real.  The routine
; expects the value to be at the top of the runtime stack
; and leaves the absolute value in its place.
;
; The data type of the input value is passed in A.  Values
; are defined in types.inc.

.include "types.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp abs

; end of exports
.byte $00, $00, $00

; imports

absInt8: jmp $0000
absInt16: jmp $0000
absInt32: jmp $0000
floatAbs: jmp $0000
popToIntOp1: jmp $0000
popToIntOp1And2: jmp $0000
popToReal: jmp $0000
pushFromIntOp1: jmp $0000
pushFromIntOp1And2: jmp $0000
pushRealStack: jmp $0000
pusheax: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

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
