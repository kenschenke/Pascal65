;
; resolveRecordDecl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveRecordDecl routine

.include "ast.inc"
.include "asmlib.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export resolveRecordDecl

.import getTypePtr, declResolve, resolverError, currentLineNumber

.proc resolveRecordDecl
    jsr getTypePtr          ; type in ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2

    ldq ptr2
    jsr pushQ
    lda #type::symtab
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq ptr1
    clc
    adcq intOp32
    jsr pushQ
    jsr declResolve

    ; offset
    lda #0
    sta intOp1
    sta intOp1+1

    jsr getTypePtr
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    beq L2

    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2            ; symbol in ptr2

    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3            ; type in ptr3

    ; A field can't be a dynamic array. The parser catches one written
    ; out in place. A field of a named type has that type by now.
    ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_ARRAY
    bne :+
    ldz #type::flags
    nop
    lda (ptr3),z
    and #TYPE_FLAG_ISDYNAMIC
    beq :+
    jsr dynArrayError

    ; Set the symbol offset
:
    ldz #symbol::offset
    lda intOp1
    nop
    sta (ptr2),z
    inz
    lda intOp1+1
    nop
    sta (ptr2),z

    ; Increment the offset
    ldz #type::size
    nop
    lda (ptr3),z
    clc
    adc intOp1
    sta intOp1
    inz
    nop
    lda (ptr3),z
    adc intOp1+1
    sta intOp1+1

    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L2: rts
.endproc

; This routine reports a dynamic array record field. The field's decl
; is in ptr1. The error is reported on the field's line. ptr1 through
; ptr3 and intOp1 are preserved.
.proc dynArrayError
    ldz #decl::lineNumber
    nop
    lda (ptr1),z
    sta currentLineNumber
    inz
    nop
    lda (ptr1),z
    sta currentLineNumber+1
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    lda intOp1
    ldx intOp1+1
    jsr pushAX
    lda #errDynArrayInRecord
    jsr resolverError
    jsr popAX
    sta intOp1
    stx intOp1+1
    jsr popQ
    stq ptr3
    jsr popQ
    stq ptr2
    jsr popQ
    stq ptr1
    rts
.endproc
