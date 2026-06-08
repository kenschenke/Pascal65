;
; resolveDeclarationName.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveDeclarationName routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

declOffset = 10
membufOffset = 6
symtabOffset = 2
failIfExistsOffset = 1
kindOffset = 0

.export resolveDeclarationName

.import getTypeKind, getTypePtr

.bss

nodePtr: .res 4

.code

.proc resolveDeclarationName
    stq ptr4                ; Store the name in ptr4
    jsr getTypeKind
    cmp #TYPE_PROCEDURE
    beq :+
    cmp #TYPE_FUNCTION
    bne L1
:   jsr scopeLookup
    stq ptr2                ; symtab node in ptr2
    jsr isQZero
    beq L1
    ; Forward declaration
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1                ; decl in ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    rts

    ; Copy the declaration pointer to the symtab decl
:   ldx #0
    ldz #symbol::decl
:   lda ptr1,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ; Copy the symtab's node to the decl
    ldz #decl::node
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts

    ; Is this a unit?
L1: jsr getTypeKind
    cmp #TYPE_UNIT
    bne L2
    rts             ; Nothing to do

    ; Is this the PROGRAM declaration?
L2: cmp #TYPE_PROGRAM
    bne L3
    rts             ; Nothing to do

L3: jsr getTypePtr
    stq ptr2            ; decl type in ptr2
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1            ; decl in ptr1
    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3            ; decl name in ptr3
    ldz #kindOffset
    nop
    lda (stackPointer),z
    jsr pushA           ; kind
    ldq ptr2
    jsr pushQ           ; type
    ldq ptr3
    jsr pushQ           ; name
    jsr symbolCreate
    stq ptr2            ; symbol in ptr2
    stq nodePtr
    ; Put new symbol in decl::node
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::node
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ; Put decl in symbol::decl
    ldz #symbol::decl
    ldx #0
:   lda ptr1,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ; Copy ptr2 to ptr3
    ldq ptr2
    stq ptr3
    ; Put name in ptr2
    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2            ; name in ptr2

    ; If there is a symbol table, add the new symbol to it.
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L4              ; Branch if adding to the scope's symbol table
    ; Load the symbol table pointer and put it in ptr1
    stq ptr1
    ldz #0
    neg
    neg
    nop
    lda (ptr1),z

    ; Add the new symbol to the symbol table
    stq ptr1            ; symtab pointer in ptr1
    ldq nodePtr
    stq ptr3
    clc
    ldz #failIfExistsOffset
    nop
    lda (stackPointer),z
    beq :+
    sec
    jsr scopeBindSymtab
    ; Store symtab root back into the symtab pointer
    stq ptr2
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr4            ; ptr4 points to the symtab pointer
    ldx #0
    ldz #0
:   lda ptr2,x
    nop
    sta (ptr4),z
    inx
    inz
    cpx #4
    bne :-
    rts

    ; No symbol table - add the new symbol to the current scope
L4: ldq nodePtr
    stq ptr3
    clc
    ldz #failIfExistsOffset
    nop
    lda (stackPointer),z
    beq :+
    sec
:   jsr scopeBind
    rts
.endproc
