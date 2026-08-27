;
; getBaseType.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeUnits routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export getBaseType

.import scopeLookup, isQZero

.bss

wasSubrange: .res 1

.code

; This routine gets the base type of the type passed in Q.
; The base type is returned in Q.
.proc getBaseType
    stq ptr1
    lda #0
    sta wasSubrange

L1: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION
    bne :+
    jmp DN
:   cmp #TYPE_ENUMERATION_VALUE
    bne :+
    jmp DN
:   cmp #TYPE_DECLARED
    beq :+
    jmp L8

    ; Declared type
:   ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1
    bra L1

:   ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    jmp DN

:   stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    jmp DN
:   stq ptr2
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr1
    lda wasSubrange
    bne L2
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION_VALUE
    bne L2
    ; This happens when a subrange lower limit is an enumeration.
    ; The subrange type is the type of the enumeration value, so
    ; the kind needs to be TYPE_ENUMERATION.
    ldz #type::kind
    lda #TYPE_ENUMERATION
    nop
    sta (ptr1),z

L2: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION
    bne L1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jmp L1
:   ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #type::subtype
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

L8: cmp #TYPE_SUBRANGE
    bne DN
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq DN
    ; Get the subtype
    stq ptr1
    lda #1
    sta wasSubrange
    jmp L1

DN: ldq ptr1
    rts
.endproc
