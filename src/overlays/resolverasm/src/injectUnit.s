;
; injectUnit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; injectUnit routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export injectUnit

.import findUnit, resolverError

.bss

usesDecl: .res 4
interfaceDecl: .res 4
interfaceSym: .res 4
newSym: .res 4
symKey: .res 4

.code

; This routine injects a unit's interface declarations into the current
; scope. It does this by looping through the unit's interface symbol table
; and looking up the corresponding entry in the unit's implementation
; symbol table then adding those into the current scope's symbol table.
;
; The routine is passed the unit name in Q
.proc injectUnit
    jsr findUnit            ; unit returned in Q
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1                ; root decl in ptr1
    stq usesDecl
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1                ; code block in ptr1
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
    stq interfaceDecl

L1: jsr isQZero
    bne :+
    jmp L4

:   stq ptr1
    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    stq symKey
    ldq usesDecl
    stq ptr1
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr symtabLookup
    jsr isQZero
    bne L2
    lda #errMissingUnitDeclaration
    jsr resolverError
    jmp L3
L2: stq ptr1
    stq interfaceSym
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeClone
    stq ptr3
    ldq interfaceDecl
    stq ptr1
    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    lda #SYMBOL_GLOBAL
    jsr pushA               ; kind
    ldq ptr3
    jsr pushQ               ; type
    ldq ptr4
    jsr pushQ               ; name
    jsr symbolCreate
    stq ptr1
    stq newSym
    ldq usesDecl
    stq ptr2
    ldq interfaceSym
    stq ptr3
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldz #decl::isLibrary
    nop
    lda (ptr2),z
    nop
    sta (ptr3),z
    ldz #symbol::decl
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldq newSym
    stq ptr3
    ldq symKey
    stq ptr2
    sec
    jsr scopeBind

    ; Go to the next declaration
L3: ldq interfaceDecl
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq interfaceDecl
    jmp L1

L4: rts
.endproc
