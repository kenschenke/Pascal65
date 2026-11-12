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
.import currentLineNumber

; This routine checks an array declaration: the index type of each array
; written out in place (Array[A, B] is an array of arrays), the element
; type, and the dynamic arrays in it. A cloned type is skipped. It's a
; copy of a named type, or another variable in the same declaration,
; which was already checked.
.proc resolveArrayDecl
    jsr getTypePtr              ; type in ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCLONED
    bne DN
    ldq ptr1
    stq arrPtr

L1: ldq arrPtr
    stq ptr1
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr checkIndexType
    ldq arrPtr
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2
    stq arrPtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    beq L1

    ; The element type. A pointer can name a type declared later.
    cmp #TYPE_DECLARED
    bne L2
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne L2
    lda #errInvalidType
    jsr resolverError

L2: jmp checkDynamicElement
DN: rts
.endproc

; This routine checks the index type in Q. It is one or two bytes: a
; subrange, or the name of a subrange, an enumeration or a Byte or Word
; constant (Array[N] has N elements). These are what getArraySize can
; size. A type such as Char or Boolean, or an enumeration written in
; place, can't be an index. A size of zero is a name that isn't declared.
.proc checkIndexType
    stq idxPtr
    jsr getTypeSize
    cpx #0
    bne BD
    cmp #0
    beq BD
    cmp #3
    bcs BD

    ldq idxPtr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_SUBRANGE
    beq OK
    cmp #TYPE_DECLARED
    bne BD
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq BD
    stq ptr1                    ; symbol in ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                    ; the name's type in ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ENUMERATION
    beq OK
    cmp #TYPE_SUBRANGE
    beq OK
    cmp #TYPE_BYTE
    beq CN
    cmp #TYPE_WORD
    bne BD
CN: ldz #symbol::decl           ; A constant has a value
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq BD
    stq ptr3
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr3),z
    jsr isQZero
    bne OK

BD: lda #errInvalidIndexType
    jmp resolverError
OK: rts
.endproc

; Only one-dimensional dynamic arrays are supported. The parser catches
; arrays written out in place, as in Array[1..3] Of Array Of Integer.
; This routine catches a named array type as the element type: a named
; dynamic array as the element of any array, or a named array as the
; element of a dynamic array. The type isn't cloned (resolveArrayDecl).
.proc checkDynamicElement
    jsr getTypePtr              ; type in ptr1

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
    bne :+
    rts
:   stq ptr1
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
    ldz #type::name
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    jsr fieldTypeError          ; The field's type isn't declared
    bra NX
:   ldq fieldPtr
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
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
    jmp L1
.endproc

; This routine reports that the type of the field in fieldPtr isn't
; declared, on the field's line.
.proc fieldTypeError
    ldq fieldPtr
    stq ptr1
    ldz #decl::lineNumber
    nop
    lda (ptr1),z
    sta currentLineNumber
    inz
    nop
    lda (ptr1),z
    sta currentLineNumber+1
    lda #errInvalidType
    jmp resolverError
.endproc

.bss

dynFlag: .res 1
fieldPtr: .res 4
arrPtr: .res 4                  ; The array being checked
idxPtr: .res 4                  ; The index type being checked
