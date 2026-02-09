;
; checkArray.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

elemTypeOffset = 0
indexTypeOffset = 4

.export checkArray

.import loadStackValue, isTypeOrdinal, typeCheckError

.proc checkArray
    ; If the index type is a subrange, get the subtype
    ldz #indexTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_SUBRANGE
    bne L1
    ; Get the subtype
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ; Update the indexType pointer
    ldz #indexTypeOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; If the index type is not an ordinal, the type must be a character
    ; ptr1 still points to the index type
L1: ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeOrdinal
    beq L2                  ; Branch if it's an ordinal
    ; Make sure the index type is a character
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq L2
    ldz #errInvalidIndexType
    jsr typeCheckError

    ; If this an array of arrays, check the embedded array as well
L2: ldz #elemTypeOffset
    jsr loadStackValue
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L3
    ; Check the embedded array too
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr checkArray

L3: jsr popQ
    jsr popQ
    rts
.endproc
