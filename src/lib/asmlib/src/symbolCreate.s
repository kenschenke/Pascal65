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

kindOffset = 4
typeOffset = 0

.export symbolCreate

.import storeFromStack, heapAlloc, rtPopA, rtPopQ

; Allocate a symbol structure and populate it with parameters.
; Inputs on runtime stack, bottom to top:
;    SYMBOL_* kind - 1 byte
;    type pointer  - 4 bytes
;
; The symbol does not hold a name. The name is the key of the symbol table
; node that points to the symbol.
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

    ; Pop the parameters off the stack
    jsr rtPopQ
    jsr rtPopA

    ldq ptr1
    rts
.endproc
