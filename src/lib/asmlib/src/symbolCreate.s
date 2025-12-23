;
; symbolCreate.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; symbolCreate routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

kindOffset = 8
typeOffset = 4
nameOffset = 0

.export symbolCreate

.import storeFromStack, nameClone, heapAlloc, rtPopA, rtPopQ, rtPushQ

; Allocate a symbol structure and populate it with parameters.
; Inputs on runtime stack, bottom to top:
;    SYMBOL_* kind - 1 byte
;    type pointer  - 4 bytes
;    name pointer  - 4 bytes
; Returns pointer to symbol structure in Q
.proc symbolCreate
    ; Allocate the structure
    lda #.sizeof(symbol)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the symbol structure
    lda #0
    ldz #.sizeof(symbol)-1
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Store the symbol kind
    ldz #kindOffset
    nop
    lda (stackPointer),z
    ldz #symbol::kind
    nop
    sta (ptr1),z

    ; Store the type pointer
    lda #typeOffset
    ldx #symbol::type
    jsr storeFromStack

    ; Clone the name
    ldz #nameOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldq ptr1
    jsr rtPushQ
    ldq ptr2
    jsr nameClone
    stq ptr2
    jsr rtPopQ
    stq ptr1
    ldx #0
    ldz #symbol::name
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; Pop the parameters off the stack
    jsr rtPopQ
    jsr rtPopQ
    jsr rtPopA

    ldq ptr1
    rts
.endproc
