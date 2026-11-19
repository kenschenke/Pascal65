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

.import units, icodeRoutineDeclarations, icodeUnitInit, moduleUnit
.import icodeUnitFileOpen, icodeUnitFileClose, writeUnitHeader
.import writeImports, writeFrames, icodeWriteEom
.import icodeKeepFeatures, icodeRestoreFeatures
.import icodeKeepData, icodeRestoreData, icodeWriteData, icodeFreeData

.bss

thisUnit: .res 4

.code

; This routine writes each Pascal unit's icode file: its header, imports
; and frames, its init block (icodeUnitInit), its routines, its data
; segments and EOM. A library has no code. It runs while the program's
; file is written, in the program's scope, and leaves that file the
; output.
.proc icodeUnitRoutines
    ldq units
    stq thisUnit

    ; Loop through the units
L1: ldq thisUnit
    jsr isQZero
    bne :+
    rts

    ; A library has no code. Neither has a unit that wasn't parsed
    ; (icodetest's tests without units).
:   stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq NX
    stq ptr1
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    bne NX

    ; The unit's own file
    ldq thisUnit
    stq moduleUnit
    jsr icodeUnitFileOpen
    jsr icodeKeepFeatures
    jsr icodeKeepData
    ldq thisUnit
    jsr writeUnitHeader
    jsr writeImports
    jsr writeFrames

    ldq thisUnit
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

    jsr icodeWriteData
    jsr icodeWriteEom
    jsr icodeFreeData
    jsr icodeRestoreData
    jsr icodeRestoreFeatures
    jsr icodeUnitFileClose
    lda #0
    tax
    tay
    taz
    stq moduleUnit

NX: ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq thisUnit
    jmp L1
.endproc
