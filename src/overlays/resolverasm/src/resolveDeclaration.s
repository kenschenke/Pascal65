;
; resolveDeclaration.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveDeclaration routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

declOffset = 10
membufOffset = 6
symtabOffset = 2
failIfExistsOffset = 1
kindOffset = 0

.export resolveDeclaration, getTypePtr, getTypeKind

.import currentLineNumber, resolveDeclarationName, injectUnit
.import exprResolve, getTypeSize, resolveArrayDecl, resolveDeclared
.import resolveEnumDecl, resolveRecordDecl, resolveDeclCode, calcNamePtr

.proc resolveDeclaration
    jsr determineScopeKind

    ; Update the current line number
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::lineNumber
    nop
    lda (ptr1),z
    sta currentLineNumber
    inz
    nop
    lda (ptr1),z
    sta currentLineNumber+1

    ; Does the declaration have a name?
    ldz #decl::name
    nop
    lda (ptr1),z
    jsr isQZero
    beq L1
    ldq ptr1
    ldz #decl::name
    jsr calcNamePtr
    jsr resolveDeclarationName

    ; Is this declaration a record?
L1: jsr getTypeKind
    cmp #TYPE_RECORD
    bne L2
    jsr getTypePtr
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L2
    jsr resolveRecordDecl

    ; Copy the record's symbol table from the original type
    ; into the cloned type in the declaration's symbol.
    jsr storeSymtabInSymbolType

L2: jsr getTypeKind
    cmp #TYPE_ENUMERATION
    bne L3
    jsr resolveEnumDecl

L3: jsr getTypeKind
    cmp #TYPE_DECLARED
    bne L4
    jsr resolveDeclared

L4: jsr getTypeKind
    cmp #TYPE_ARRAY
    bne L5
    jsr resolveArrayDecl

    ; Store the size of the declaration
L5: jsr getTypePtr
    ldq ptr1
    jsr getTypeSize
    sta intOp1
    stx intOp1+1
    pha
    phx
    jsr getTypePtr
    ldz #type::size+1
    pla
    nop
    sta (ptr1),z
    dez
    pla
    nop
    sta (ptr1),z

    ; Store it in the symbol's type too
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L6
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::size
    lda intOp1
    nop
    sta (ptr1),z
    inz
    lda intOp1+1
    nop
    sta (ptr1),z

    ; If the type has a subtype, set its size as well
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L6
    stq ptr1
    jsr getTypeSize
    ldz #type::size
    nop
    sta (ptr1),z
    inz
    txa
    nop
    sta (ptr1),z

    ; Resolve the declaration's value
L6: ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L7
    jsr pushQ               ; expr
    jsr pushQZero           ; symtab
    lda #0
    jsr pushA               ; isRtnCall
    jsr exprResolve

L7: ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    lda #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    bne L8
    ldq ptr1
    ldz #decl::name
    jsr calcNamePtr
    jsr injectUnit

L8: ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L9
    ldq ptr1
    jsr resolveDeclCode

L9: jsr popA
    jsr popA
    jsr popQ
    jsr popQ
    jsr popQ
    rts
.endproc

; This routine looks at the scope level and determines if
; the current scope is local or global. If the scope level
; is 2 or greater, it's local. Otherwise it's global.
; Once the scope level is determined, it's put on the stack.
.proc determineScopeKind
    jsr scopeLevel
    cmp #2
    bpl :+
    lda #SYMBOL_GLOBAL
    bra L1
:   lda #SYMBOL_LOCAL
L1: jsr pushA
    rts
.endproc

; This routine puts the declaration's type in ptr1
.proc getTypePtr
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    rts
.endproc

; This routine looks up the type kind for the declaration
.proc getTypeKind
    jsr getTypePtr
    ldz #type::kind
    nop
    lda (ptr1),z
    rts
.endproc

; This routine stores the symbol table into the symbol's cloned type.
; When a symbol is created for a record's declaration, the symbol gets
; its own cloned copy of the record's type. The cloned copy needs to
; have a copy of the record's symbol table also.
;
; ptr2 contains the symbol table to copy.
.proc storeSymtabInSymbolType
    ; Get the decl in ptr1
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1            ; decl in ptr1

    ; Look up the decl's type
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2

    ; Look up the type's symbol table
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2            ; symtab in ptr2

    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1            ; symbol in ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1            ; symbol type in ptr1
    ldz #type::symtab
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
