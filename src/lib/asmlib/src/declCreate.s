;
; declCreate.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; declCreate routine

.include "zeropage.inc"
.include "ast.inc"
.include "4510macros.inc"

kindOffset = 12
nameOffset = 8
typeOffset = 4
valueOffset = 0

.export declCreate

.import storeFromStack, heapAlloc, rtPopA, rtPopQ

; Allocate a decl structure and populate it with parameters.
; Inputs on runtime stack, bottom to top:
;    DECL_* kind   - 1 byte
;    name pointer  - 4 bytes
;    type pointer  - 4 bytes
;    value pointer - 4 bytes
; Returns pointer to decl structure in Q
.proc declCreate
    ; Allocate the structure
    lda #.sizeof(decl)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the decl structure
    lda #0
    ldz #.sizeof(decl)-1
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Store the decl kind
    ldz #kindOffset
    nop
    lda (stackPointer),z
    ldz #decl::kind
    nop
    sta (ptr1),z

    ; Store the name
    ldz #nameOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2                ; source name
    lda #decl::name
    sta tmp1                ; index in dest
    lda #0
    sta tmp2                ; index in source
:   ldz tmp2
    nop
    lda (ptr2),z
    beq :+
    ldz tmp1
    nop
    sta (ptr1),z
    inc tmp1
    inc tmp2
    bra :-

    ; Store the type pointer
:   lda #typeOffset
    ldx #decl::type
    jsr storeFromStack

    ; Store the value pointer
    lda #valueOffset
    ldx #decl::value
    jsr storeFromStack

    ; Pop the parameters off the stack
    jsr rtPopQ
    jsr rtPopQ
    jsr rtPopQ
    jsr rtPopA

    ldq ptr1
    rts
.endproc
