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
.include "zeropage.inc"
.include "4510macros.inc"

.export resolveRecordDecl

.import getTypePtr, declResolve

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
    ldq ptr1
    clc
    adcq #type::symtab
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

    ; Set the symbol offset
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
