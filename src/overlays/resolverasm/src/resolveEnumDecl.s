;
; resolveEnumDecl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveEnumDecl routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export resolveEnumDecl

.import addEnumsToSymtab, resolverError, getTypePtr, calcNamePtr

.proc resolveEnumDecl
    jsr getTypePtr
    ldz #type::name
    nop
    lda (ptr1),z
    beq L1

    ; Look up the enum name
    ldq ptr1
    ldz #type::name
    jsr calcNamePtr
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    lda #errInvalidType
    jmp resolverError

:   stq ptr2                ; symbol in ptr2
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; symbol type in ptr3

    jsr getTypePtr
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr2                ; paramFields in ptr2

    ; Copy the param fields into the decl type
    ldz #type::paramFields
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts

    ; Name is null - add the enums to the symbol table
    ; type is in ptr1
    ; paramFields is in ptr2
L1: ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    jsr addEnumsToSymtab
    rts
.endproc
