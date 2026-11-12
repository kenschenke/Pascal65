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

.import getRecordSymtab

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
:   ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
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
    jmp L7                      ; The array isn't declared
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z

    stq typePtr
    stq ptr1
    ; Follow array elements and what pointers point to (a[i]^.f)
L2: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    beq :+
    cmp #TYPE_POINTER
    bne L3
:   ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq typePtr
    stq ptr1
    bra L2
L3: cmp #TYPE_DECLARED
    beq :+
    jmp L6
:   ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
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
    bne :+
    jmp L7
:   bra L5

L4: jsr scopeLookup
    jsr isQZero
    beq L7

L5: stq ptr2
    ; Skip cloning the type if typePtr already has a subtype
    ldq typePtr
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne SC
    ldq ptr2
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
SC: ldz #symbol::type
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

    ; A name isn't declared: there's no record. exprResolve reports the
    ; array or the field.
L7: jsr popQ
    jsr popQ
    lda #0
    tax
    tay
    taz
    rts
.endproc
