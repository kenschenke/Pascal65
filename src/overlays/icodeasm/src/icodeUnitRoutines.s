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

.import units, icodeRoutineDeclarations, icodeUnitInit, writeModule

.bss

thisUnit: .res 4

.code

; This routine writes each unit's init block (icodeUnitInit), then its
; routines. A Pascal unit's start with MDL, so frame 0 is the unit's own
; (writeModule), and the program's code after them with MDL 0. MDL is
; written only when the frame changes.
.proc icodeUnitRoutines
    ldq units
    stq thisUnit

    ; Loop through the units
L1: ldq thisUnit
    jsr isQZero
    bne UN

    ; The program's code follows
    lda #0
    tax
    tay
    taz
    jmp writeModule

    ; A Pascal unit's code is its module's (MDL). A library has none.
UN: stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    bne :+
    ldq thisUnit
    jsr writeModule

:   ldq thisUnit
    jsr icodeUnitInit

    ldq thisUnit
    stq ptr1
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
    jmp L1
.endproc
