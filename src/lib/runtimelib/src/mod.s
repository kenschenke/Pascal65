.include "error.inc"

.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp modulus

; end of exports
.byte $00, $00, $00

; imports

divInt32: jmp $0000
multInt32: jmp $0000
swapInt32: jmp $0000
subInt32: jmp $0000
runtimeError: jmp $0000
prepOperands32: jmp $0000
pushFromIntOp1And2: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

dividend: .res 4
divisor: .res 4

; This routine finds the remainder (mod) of the two numbers on the runtime stack.
; The dividend (the number being divided) is at the top of the stack and the
; divisor is below it.  When the routine exits the remainder is atop the stack.
; It checks for mod 0 (divide by zero).
;
; dividend Mod divisor
;
; Inputs:
;    A - data type of the dividend
;    X - data type of the divisor
;
; 1.  Divide intOp1/intOp2 by intOp32
; 2.  Multiply answer by intOp32
; 3.  Subtract answer from intOp1/intOp2
; 4.  Result is remainder

.proc modulus
    jsr prepOperands32  ; Put the operands into intOp1/intOp2 and intOp32
    ; Check for divide by zero
    lda intOp32
    ora intOp32 + 1
    ora intOp32 + 2
    ora intOp32 + 3
    bne L1
    lda #rteDivisionByZero
    jmp runtimeError
L1:
    ; Copy intOp1/intOp2 to dividend
    ldx #3
:   lda intOp1,x
    sta dividend,x
    dex
    bpl :-
    ; Copy intOp32 to divisor
    ldx #3
:   lda intOp32,x
    sta divisor,x
    dex
    bpl :-
    ; Step 1
    jsr divInt32
    ; Load the divisor back into intOp32
    ldx #3
:   lda divisor,x
    sta intOp32,x
    dex
    bpl :-
    ; Step 2
    jsr multInt32
    ; Swap dividend and divisor
    jsr swapInt32
    ; Load the dividend back into intOp1/intOp2
    ldx #3
:   lda dividend,x
    sta intOp1,x
    dex
    bpl :-
    ; Step 3
    jsr subInt32
    ; Step 4 - remainder is pushed back onto stack
    jmp pushFromIntOp1And2
.endproc
