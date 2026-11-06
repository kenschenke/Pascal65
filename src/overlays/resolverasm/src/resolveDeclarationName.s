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
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

declOffset = 10
membufOffset = 6
symtabOffset = 2
failIfExistsOffset = 1
kindOffset = 0

.export resolveDeclarationName

.import getTypeKind, getTypePtr, calcNamePtr, resolverError

.bss

nodePtr: .res 4
namePtr: .res 4

.code

; The declaration's name is passed in Q
.proc resolveDeclarationName
    stq ptr4                ; Store the name in ptr4
    stq namePtr
    jsr getTypeKind
    cmp #TYPE_PROCEDURE
    beq :+
    cmp #TYPE_FUNCTION
    beq :+
    jmp L1

    ; A routine. If the name is already in this scope, it must be the
    ; routine's forward declaration and this must be its body.
:   jsr scopeLookupCurrent
    jsr isQZero
    bne :+
    jmp L1                  ; Not in this scope
:   stq ptr2                ; symbol in ptr2
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq RD
    stq ptr3                ; the symbol's type in ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_PROCEDURE
    beq :+
    cmp #TYPE_FUNCTION
    bne RD                  ; The name is something else
:   ldz #type::flags
    nop
    lda (ptr3),z
    and #TYPE_FLAG_ISFORWARD
    beq RD                  ; The routine wasn't declared forward
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; the symbol's decl in ptr3
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr3),z
    jsr isQZero
    bne RD                  ; The forward routine already has a body
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
    beq RD                  ; A second forward declaration

    ; This is the body of a forward declaration.
    ; Copy the declaration pointer to the symtab decl
    ldx #0
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

    ; The routine redefines a name in this scope. It gets no symbol.
RD: lda #errRedefinedIdentifier
    jmp resolverError

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
    jsr typeClone
    stq ptr2            ; decl type in ptr2
    ldz #kindOffset
    nop
    lda (stackPointer),z
    jsr pushA           ; kind
    ldq ptr2
    jsr pushQ           ; type
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
    ldq ptr1
    ldz #decl::name
    jsr calcNamePtr
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
:   jsr scopeBindSymtab
    php
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
    plp
    bcs redefined
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
    bcs redefined
    rts
.endproc

; The name is already in the symbol table, so the new symbol wasn't
; added. Report the error. The declaration keeps its symbol (decl::node)
; so the rest of the resolver can use it, but the symbol goes in a
; symbol table of its own in decl::symtab, which is freed with the
; declaration.
.proc redefined
    lda #errRedefinedIdentifier
    jsr resolverError
    lda #0
    tax
    tay
    taz
    stq ptr1            ; an empty table
    ldq namePtr
    stq ptr2            ; key
    ldq nodePtr
    stq ptr3            ; data
    clc
    jsr scopeBindSymtab
    stq ptr2            ; the new table's root
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::symtab
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
