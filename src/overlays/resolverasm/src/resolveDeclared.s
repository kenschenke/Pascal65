;
; resolveDeclared.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveDeclared routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

declOffset = 10
symtabOffset = 6
membufOffset = 2
failIfExistsOffset = 1
kindOffset = 0

.export resolveDeclared

.import getTypePtr, resolverError

.proc resolveDeclared
    jsr getTypePtr
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne L2

    ; Name not found in symbol table
    ldz #membufOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    jsr isQZero
    bne :+
    ; No membuf supplied
    lda #errInvalidType
    jmp resolverError

:   ldz #0
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr isQZero
    bne L1
    ; No membuf is allocated yet
    jsr allocMemBuf
    stq ptr1
    ; Copy the new membuf to the membuf pointer
    ldz #membufOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #0
    ldx #0
:   lda ptr1,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ; Save the decl pointer to the membuf
L1: ldq stackPointer
    clc
    adcq #declOffset
    stq ptr2
    lda #4
    ldx #0
    jmp writeToMemBuf

    ; The symbol is found
L2: stq ptr2            ; save symbol ptr
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z        ; load the type pointer from the symbol

    jsr typeClone       ; clone the symbol type
    stq ptr2            ; cloned type in ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ENUMERATION
    bne L3
    ; Set the subtype
    jsr getTypePtr
    ; Copy the decl type into the cloned type's subtype
    ldz #type::subtype
    ldx #0
:   lda ptr1,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-
    bra L4              ; skip freeing the current declaration's type
L3: ; Free the declaration's current type
    jsr lookupDeclSymbol
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::size
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
L4: ; Store the cloned type back into the declaration
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::type
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    rts
.endproc

; This routine looks up the symbol for the current declaration
; The pointer to the symbol is returned in Q.
.proc lookupDeclSymbol
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    rts
.endproc
