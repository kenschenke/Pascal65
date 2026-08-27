;
; resolveUnits.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveUnits routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export resolveUnits

.import units, declResolve

.bss

currentUnit: .res 4

.code

.proc resolveUnits
    ldq units
    stq currentUnit

L1: ldq currentUnit
    jsr isQZero
    beq L9

    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr pushQZero
    jsr declResolve

    ; Get the astRoot for the current unit
    ldq currentUnit
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1                ; unit root in ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; stmt block in ptr2
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; stmt declaration block in ptr3
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4                ; unit symtab in ptr4
    jsr setUnitDecl

    ; Go to the next unit
L8: ldq currentUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq currentUnit
    bra L1

L9: rts
.endproc

.proc setUnitDecl
L1: ldq ptr3
    jsr isQZero
    beq L2

    ldz #decl::unitSymtab
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr3),z
    inz
    inx
    cpx #4
    bne :-

    ldz #decl::next
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    bra L1

L2: rts
.endproc
