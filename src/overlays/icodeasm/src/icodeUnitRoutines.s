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

.export icodeUnitRoutines, icodeUnitFile

.import units, icodeRoutineDeclarations, icodeUnitInit, moduleUnit
.import icodeUnitFileOpen, icodeUnitFileClose, writeUnitHeader
.import writeImports, writeFrames, icodeWriteEom
.import icodeKeepFeatures, icodeRestoreFeatures
.import icodeKeepData, icodeRestoreData, icodeWriteData, icodeFreeData

.bss

thisUnit: .res 4
fileUnit: .res 4

.code

; This routine writes each Pascal unit's icode file (icodeUnitFile). A
; library has no code. It runs while the program's file is written, in the
; program's scope, and leaves that file the output.
.proc icodeUnitRoutines
    ldq units
    stq thisUnit

    ; Loop through the units
L1: ldq thisUnit
    jsr isQZero
    bne :+
    rts

    ; A library has no code. Neither has a unit that wasn't parsed
    ; (icodetest's tests without units), and a unit loaded from its TPU
    ; has its code there.
:   stq ptr1
    ldz #unit::fromTpu
    nop
    lda (ptr1),z
    bne NX
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

    ldq thisUnit
    jsr icodeUnitFile

NX: ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq thisUnit
    bra L1
.endproc

; This routine writes the icode file of the Pascal unit in Q: its header,
; imports and frames, its init block (icodeUnitInit), its routines, its
; data segments and EOM. Its code is written in its own scope, the unit's
; symbol table, on top of the program's or, compiling the unit on its own
; (icodeWriteX), of the global scope, so both compiles write the same.
.proc icodeUnitFile
    stq fileUnit
    stq moduleUnit
    jsr icodeUnitFileOpen
    jsr icodeKeepFeatures
    jsr icodeKeepData
    ldq fileUnit
    jsr writeUnitHeader
    jsr writeImports
    jsr writeFrames

    ; The unit's scope
    ldq fileUnit
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr scopeEnterSymtab

    ldq fileUnit
    jsr icodeUnitInit

    ldq fileUnit
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
    jsr scopeExit

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
    rts
.endproc
