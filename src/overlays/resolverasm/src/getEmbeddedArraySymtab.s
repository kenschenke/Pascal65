;
; getEmbeddedArraySymtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getEmbeddedArraySymtab routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

recordExprOffset = 4
symtabOffset = 0

.export getEmbeddedArraySymtab

.import getRecordSymtab, resolverError, calcNamePtr

.bss

typePtr: .res 4

.code

; This function looks up the symbol table of a record within an array
; On entry, runtime stack bottom to top
;    array expression ptr
;    record symbol table
.proc getEmbeddedArraySymtab
    ldz #recordExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_FIELD
    bne :+
    jmp getRecordSymtab
:   ldq ptr1
    ldz #expr::name
    jsr calcNamePtr
    stq ptr4
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    jsr isQZero
    beq :+
    jsr symtabLookup
    bra L1
:   jsr scopeLookup
L1: jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr resolverError
    jsr popQ
    jsr popQ
    lda #0
    tax
    tay
    taz
    rts
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z

    stq typePtr
    stq ptr1
L2: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L3
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq typePtr
    stq ptr1
    bra L2
L3: cmp #TYPE_DECLARED
    bne L6
    ldq ptr1
    ldz #type::name
    jsr calcNamePtr
    stq ptr4
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L4
    stq ptr1
    jsr symtabLookup
    jsr isQZero
    beq L7
    bra L5

L4: jsr scopeLookup
    jsr isQZero
    beq L7

L5: stq ptr2
    jsr pushQ
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    jsr typeClone
    stq ptr4
    jsr popQ
    stq ptr2
    ldq typePtr
    stq ptr1
    ldz #type::subtype
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq typePtr
    stq ptr1
    jmp L2

L6: ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr popQ
    jsr popQ
    ldq ptr1
    rts

L7: lda #errUndefinedIdentifier
    jsr resolverError
    jsr popQ
    jsr popQ
    lda #0
    tax
    tay
    taz
    rts
.endproc
