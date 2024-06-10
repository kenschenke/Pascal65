;
; trig.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sine and Cosine routines
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"
.include "float.inc"

.export cosine, sine, tangent

.import FPADD, FPMULT, FPDIV, FPSUB, COMPLM, floatGt, swapFPACCandFPOP

.data

; Constants
pi: .dword $026487ea            ; Pi 3.1415926535
doublePi: .dword $036487ea      ; Pi * 2
piSquared: .dword $044ef4ec     ; Pi * Pi
two: .dword $02400000           ; 2.00
four: .dword $03400000          ; 4.00
piHalf: .dword $016487ea        ; Pi / 2

.macro pushResult
    lda FPBASE + FPLSW
    pha
    lda FPBASE + FPNSW
    pha
    lda FPBASE + FPMSW
    pha
    lda FPBASE + FPACCE
    pha
.endmacro

.macro popResult
    pla
    sta FPBASE + FOPEXP
    pla
    sta FPBASE + FOPMSW
    pla
    sta FPBASE + FOPNSW
    pla
    sta FPBASE + FOPLSW
.endmacro

.code

; This routine approximates cosine by adding 1/2 pi to to the input angle
; then using the sine wave's polynomials. See the comments for sine.
; Input:
;    Angle in radians from 0 to 2*pi in A/X/sreg
; Output:
;    Cosine in A/X/sreg
.proc cosine
    ; Save the angle in the floating point accumulator
    sta FPBASE + FPLSW
    stx FPBASE + FPNSW
    lda sreg
    sta FPBASE + FPMSW
    lda sreg + 1
    sta FPBASE + FPACCE
    ; Load piHalf
    ldx #3
:   lda piHalf,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    ; Add
    jsr FPADD
    ; Store the result in tmp1-tmp4
    ldx #3
:   lda FPBASE + FPLSW,x
    sta tmp1,x
    dex
    bpl :-
    ; Normalize the angle to be between 0 and 2*pi radians
    jsr normalizeAngle
    ; Load pi
    ldx #3
:   lda pi,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    ; Is the angle > pi?
    jsr floatGt
    cmp #0
    beq LT              ; Branch if angle <= pi
    jsr calcPoly2
    jmp DN
LT: jsr calcPoly1
DN: ; Load the result and return
    jmp loadResult
.endproc

; This routine approximates sine using the polynomial
; 4*x/(pi^2) * (pi - x) where X is the input in radians.
; This polynomial is derived at https://datagenetics.com/blog/july12019/index.html
; The code refers to this as poly1. It works great for inputs between 0 and pi.
; Since the sine wave mirrors itself between pi and 2*pi, the routine uses a
; slightly modified polynomial for the second half of the sine wave.
; -((4*(pi*2-x))/(pi^2))*(pi-(pi*2-x))
; The code refers to this as poly2. Both polynomials are used for the calculation
; of parts of the sine and cosine waves.
;
; Input:
;    Angle in radians from 0 to 2*pi in A/X/sreg
; Output:
;    Sine in A/X/sreg
.proc sine
    ; Save the angle in tmp1-tmp4
    sta tmp1
    stx tmp2
    lda sreg
    sta tmp3
    lda sreg + 1
    sta tmp4
    ; Normalize the angle if > 2*pi
    jsr normalizeAngle
    ; If the angle is > pi then use the calcPoly2 polynomial instead
    ldx #3
:   lda pi,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    jsr floatGt
    cmp #0
    beq LT
    jsr calcPoly2
    jmp DN
LT: jsr calcPoly1
    ; Load the result into A/X/sreg
DN: jmp loadResult
.endproc

; This routine calculates tangent, which is really just sin / cos.
; Input:
;    Angle in radians from 0 to 2*pi in A/X/sreg
; Output:
;    Tangent in A/X/sreg
.proc tangent
    ; Store the input angle on the stack
    sta tmp1
    stx tmp2
    pha
    tax
    pha
    lda sreg
    pha
    lda sreg + 1
    pha
    ; Calculate cosine
    lda tmp1
    ldx tmp2
    jsr cosine
    ; Pop the input angle back off the stack and store it away
    pla
    sta tmp4
    pla
    sta tmp3
    pla
    sta tmp2
    pla
    sta tmp1
    ; Push the cosine onto the CPU stack
    lda FPBASE + FPACCE
    pha
    lda FPBASE + FPMSW
    pha
    lda FPBASE + FPNSW
    pha
    lda FPBASE + FPLSW
    pha
    ; Calculate the sine
    lda tmp4
    sta sreg + 1
    lda tmp3
    sta sreg
    ldx tmp2
    lda tmp1
    jsr sine
    ; Pop the cosine back off the CPU stack
    pla
    sta FPBASE + FOPLSW
    pla
    sta FPBASE + FOPNSW
    pla
    sta FPBASE + FOPMSW
    pla
    sta FPBASE + FOPEXP
    ; Divide sin by cos
    jsr FPDIV
    ; Load the result
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPMSW
    sta sreg
    ldx FPBASE + FPNSW
    lda FPBASE + FPLSW
    rts
.endproc

; This routine calculates the result of the polynomial
; 4*x/(pi^2) * (pi - x) where X is the input in radians.
; The input radians is expected in tmp1-tmp4
; and the output is left in the floating point accumulator.
.proc calcPoly1
    ldx #3
:   lda tmp1,x
    sta FPBASE + FPLSW,x
    dex
    bpl :-
    ; Load 4
    ldx #3
:   lda four,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    ; Multiply the angle * 4
    jsr FPMULT
    ; Load Pi^2
    ldx #3
:   lda piSquared,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    ; Divide
    jsr FPDIV
    ; Store the result on the stack for a bit
    pushResult
    ; Load Pi into FPACC
    ldx #3
:   lda pi,x
    sta FPBASE + FPLSW,x
    dex
    bpl :-
    ; Load the angle
    ldx #3
:   lda tmp1,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    ; Subtract
    jsr FPSUB
    ; Load the product result back off the stack
    popResult
    ; Multiply
    jmp FPMULT
.endproc

; This routine calculates the result of the polynomial
; -((4*(pi*2-x))/(pi^2)) * (pi-(pi*2-x)) where X is the input in radians.
; The input radians is expected in tmp1-tmp4
; and the output is left in the floating point accumulator.
.proc calcPoly2
    jsr doublePiMinusX
    ; Load 4
    ldx #3
:   lda four,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    jsr FPMULT
    ; Load pi squared
    ldx #3
:   lda piSquared,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    jsr FPDIV
    ; Store the result on the stack for a bit
    pushResult
    jsr doublePiMinusX
    jsr swapFPACCandFPOP
    ; Load Pi
    ldx #3
:   lda pi,x
    sta FPBASE + FPLSW,x
    dex
    bpl :-
    jsr FPSUB
    ; Load the product result back off the stack
    popResult
    jsr FPMULT
    ; Negate the result
    ldx #FPLSW
    ldy #3
    jmp COMPLM
.endproc

; This helper routine doubles pi and subtracts the angle (in tmp1-tmp4)
; The result is left in the floating point accumulator
.proc doublePiMinusX
    ; Load the Pi*2 constant
    ldx #3
:   lda doublePi,x
    sta FPBASE + FPLSW,x
    dex
    bpl :-
    ; Load the angle
    ldx #3
:   lda tmp1,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    jmp FPSUB
.endproc

; This helper routine loads the result from the floating point
; accumulator into A/X/sreg. It is used by sine and cosine when done.
.proc loadResult
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPMSW
    sta sreg
    ldx FPBASE + FPNSW
    lda FPBASE + FPLSW
    rts
.endproc

; This helper routine loads 2*pi and the input angle into
; FPACC and FOPACC (primary and secondary floating point accumulators).
.proc loadDoublePiAndAngle
    ldx #3
:   lda tmp1,x
    sta FPBASE + FPLSW,x
    lda doublePi,x
    sta FPBASE + FOPLSW,x
    dex
    bpl :-
    rts
.endproc

; This routine normalizes the angle so it between 0 and 2*pi radians.
; It expects the angle to be in tmp1-tmp4 and leaves the
; normalized angle there.
.proc normalizeAngle
    ; Loop, subtracting 2*pi until the angle is less than 2*pi
L1: jsr loadDoublePiAndAngle
    jsr floatGt
    cmp #0
    beq DN
    ; Subtract 2*pi
    jsr loadDoublePiAndAngle
    jsr FPSUB
    ; Store the angle back in tmp1-tmp4
    ldx #3
:   lda FPBASE + FPLSW,x
    sta tmp1,x
    dex
    bpl :-
    jmp L1
DN: jmp loadDoublePiAndAngle
.endproc
