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
.import resolveEnumDecl, resolveRecordDecl, resolveDeclCode

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
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L1
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

    ; Resolve the declaration's value
    ldz #declOffset
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
    beq L6
    jsr pushQ               ; expr
    jsr pushQZero           ; symtab
    lda #0
    jsr pushA               ; isRtnCall
    jsr exprResolve

L6: ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    lda #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    bne L7
    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr injectUnit

L7: ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L8
    ldq ptr1
    jsr resolveDeclCode

L8: jsr popA
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
