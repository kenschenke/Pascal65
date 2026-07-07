;
; exprCreate.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; exprCreate routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

kindOffset = 16
leftOffset = 12
rightOffset = 8
nameOffset = 4
valueOffset = 0

.export exprCreate

.import storeFromStack, heapAlloc, rtPopA, rtPopQ

; Allocate an expr structure and populate it with parameters.
; Inputs on runtime stack, bottom to top:
;    EXPR_* kind   - 1 byte
;    left pointer  - 4 bytes
;    right pointer - 4 bytes
;    name pointer  - 4 bytes
;    value bytes   - 4 bytes
; Returns pointer to expr structure in Q
.proc exprCreate
    ; Allocate the structure
    lda #.sizeof(expr)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the expr structure
    lda #0
    ldz #.sizeof(expr)-1
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Store the expr kind
    ldz #kindOffset
    nop
    lda (stackPointer),z
    ldz #expr::kind
    nop
    sta (ptr1),z

    ; Store the left pointer
    lda #leftOffset
    ldx #expr::left
    jsr storeFromStack

    ; Store the right pointer
    lda #rightOffset
    ldx #expr::right
    jsr storeFromStack

    ; Copy the name
    lda #0
    sta tmp1                ; tmp1 - index into source name
    lda #expr::name
    sta tmp2                ; tmp2 - offset in expr structure
    ldz #nameOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
:   ldz tmp1
    nop
    lda (ptr2),z
    beq :+
    ldz tmp2
    nop
    sta (ptr1),z
    inc tmp1
    inc tmp2
    bne :-

    ; Store the value pointer
:   lda #valueOffset
    ldx #expr::value
    jsr storeFromStack

    ; Pop the parameters off the stack
    jsr rtPopQ
    jsr rtPopQ
    jsr rtPopQ
    jsr rtPopQ
    jsr rtPopA

    ldq ptr1
    rts
.endproc
