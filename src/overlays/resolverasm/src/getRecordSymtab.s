;
; getRecordSymtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getRecordSymtab routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

exprOffset = 4
symtabOffset = 0

.export getRecordSymtab, typeRecordSymtab

.import getEmbeddedRecordSymtab, getEmbeddedArraySymtab

.bss

symType: .res 4

.code

; On entry, runtime stack bottom to top
;    ptr to expression
;    ptr to symbol table
.proc getRecordSymtab
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_FIELD
    bne L1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; left expr in ptr2
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3                ; right expr in ptr3
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr4                ; symtab in ptr4
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    ldq ptr4
    jsr pushQ
    jsr getEmbeddedRecordSymtab
    stq ptr1
    jsr popQ
    jsr popQ
    ldq ptr1
    rts

L1: cmp #EXPR_SUBSCRIPT
    bne L2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; left expr in ptr2
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr3                ; symtab in ptr3
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    jsr getEmbeddedArraySymtab
    stq ptr1
    jsr popQ
    jsr popQ
    ldq ptr1
    rts

    ; A pointer: look at what it points to. That can be another pointer,
    ; a field or an array element (p^^.f, r.p^.f, a[i]^.f), so start over
    ; with it.
L2: cmp #EXPR_POINTER
    bne L3
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #exprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp getRecordSymtab

L3: ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L4
    jsr popQ
    jsr popQ
    lda #0
    tax
    tay
    taz
    rts

L4: stq ptr4                ; name in ptr4
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L5
    stq ptr1                ; symtab root in ptr1
    jsr symtabLookup
    bra :+

L5: jsr scopeLookup
:   jsr isQZero
    bne L6
    ; Not declared. exprResolve reports it when it resolves the name.
    jsr popQ
    jsr popQ
    lda #0
    tax
    tay
    taz
    rts

L6: stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeRecordSymtab
    stq ptr1
    jsr popQ
    jsr popQ
    ldq ptr1
    rts
.endproc

; This routine returns the symbol table of the record that the type in Q
; is, names, or holds: through declared types, array elements and
; pointers. It returns NULL for a type that isn't a record.
.proc typeRecordSymtab
    stq symType
    jsr resolveRecordSymtab
    ldq symType
    jsr isQZero
    beq L1
    stq ptr1
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
L1: rts
.endproc

; This routine loops, looking the symbol type and
; continues looping while the type is declared, array, or pointer.
.proc resolveRecordSymtab
L1: ldq symType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_DECLARED
    beq L2
    cmp #TYPE_ARRAY
    beq L4
    cmp #TYPE_POINTER
    beq L3
    rts

    ; TYPE_DECLARED
L2: ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    bne L4
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    beq L4
    ; Look up the symbol by name
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    stq symType             ; Not declared: no record (exprResolve)
    rts
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq symType
    bra L1

    ; TYPE_POINTER
L3: ; fall through

    ; TYPE_DECLARED with subtype or TYPE_ARRAY
L4: ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq symType
    bra L1
.endproc
