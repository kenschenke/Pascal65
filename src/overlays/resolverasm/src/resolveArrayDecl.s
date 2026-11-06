;
; resolveArrayDecl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveArrayDecl routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export resolveArrayDecl

.import getTypePtr, getTypeSize, resolverError, dynArrayError

.proc resolveArrayDecl
    ; Get the declaration type
    jsr getTypePtr              ; type in ptr1
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getTypeSize
    sta intOp1
    stx intOp1+1
    lda #2
    sta intOp2
    lda #0
    sta intOp2+1
    jsr gtInt16
    beq :+
    lda #errInvalidIndexType
    jsr resolverError
:   jmp checkDynamicElement
.endproc

; Only one-dimensional dynamic arrays are supported. The parser catches
; arrays written out in place, as in Array[1..3] Of Array Of Integer.
; This routine catches a named array type as the element type: a named
; dynamic array as the element of any array, or a named array as the
; element of a dynamic array.
;
; A cloned type is skipped. It's a copy of a named type, or another
; variable in the same declaration, which was already checked.
.proc checkDynamicElement
    jsr getTypePtr              ; type in ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCLONED
    bne DN

    ; Find the innermost array type of an array written out in place
L1: ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq DN
    stq ptr2                    ; element type in ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ARRAY
    bne L2
    ldq ptr2
    stq ptr1
    bra L1

L2: cmp #TYPE_RECORD
    bne :+
    jmp checkRecordFields
:   cmp #TYPE_DECLARED
    bne DN
    ldz #type::flags
    nop
    lda (ptr1),z
    sta dynFlag                 ; flags of the innermost array
    ldz #type::name
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq DN
    stq ptr1                    ; symbol in ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq DN
    stq ptr1                    ; named type in ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne DN
    ldz #type::flags
    nop
    lda (ptr1),z
    ora dynFlag
    and #TYPE_FLAG_ISDYNAMIC
    beq DN
    lda #errMultiDimDynArray
    jmp resolverError

DN: rts
.endproc

; The element of an array is a record written out in place. Its fields
; aren't resolved by resolveRecordDecl, so check here that none is a
; named dynamic array type. The parser catches a field written out in
; place as Array Of T. The record type is in ptr2.
.proc checkRecordFields
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr2),z
    stq fieldPtr

L1: ldq fieldPtr
    jsr isQZero
    beq DN
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq NX
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_DECLARED
    bne NX
    ldq ptr3
    jsr getBaseType
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_ARRAY
    bne NX
    ldz #type::flags
    nop
    lda (ptr3),z
    and #TYPE_FLAG_ISDYNAMIC
    beq NX
    ldq fieldPtr
    stq ptr1                    ; field decl for dynArrayError
    jsr dynArrayError

NX: ldq fieldPtr
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq fieldPtr
    bra L1

DN: rts
.endproc

.bss

dynFlag: .res 1
fieldPtr: .res 4
