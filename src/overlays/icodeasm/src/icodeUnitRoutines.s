;
; icodeUnitRoutines.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export icodeUnitRoutines

.import units, icodeRoutineDeclarations

.bss

thisUnit: .res 4

.code

.proc icodeUnitRoutines
    ldq units
    stq thisUnit

    ; Loop through the units
L1: ldq thisUnit
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeRoutineDeclarations

    ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq thisUnit
    bra L1
.endproc
