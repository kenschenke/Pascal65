;
; icodeUnitDeclarations.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; A unit's variables are slots in the program's level 1 frame, after the
; program's own, in the order of the units list. A library's are pushed
; by the program's startup. A Pascal unit's are pushed by the unit's own
; init block (icodeUnitInit), which the startup calls with UIC. The block
; is part of the unit's icode, so the unit sets up its own variables.

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export icodeUnitDeclarations, icodeUnitInit

.import units, icodeVariableDeclarations, icodeWriteInstruction
.import icodeFormatLabel, icodeOper1Label

.data

lblUnitInit: .asciiz "uinit"

.bss

thisUnit: .res 4
unitDecl: .res 4
localVars: .res MAX_LOCAL_VARS
localDecls: .res MAX_LOCAL_VARS*4
stmtPtr: .res 4

.code

; This routine writes the units' part of the program's startup: a
; library's variables, or a UIC to a Pascal unit's init block.
.proc icodeUnitDeclarations
    ldq units
    stq thisUnit

    ; Loop through the units
L1: ldq thisUnit
    jsr isQZero
    bne :+
    rts

:   ldq thisUnit
    jsr loadUnitDecl
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    beq UN

    ; A library's variables
    jsr unitVariables
    bra NX

    ; UIC: the unit's init block
UN: jsr formatInitLabel
    jsr icodeOper1Label
    lda #IC_UIC
    jsr icodeWriteInstruction

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

; This routine writes a Pascal unit's init block: a LOC, the code that
; pushes and initializes the unit's variables, then UIR. It writes
; nothing for a library. The unit is passed in Q.
.proc icodeUnitInit
    jsr loadUnitDecl
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    beq :+
    rts

:   jsr formatInitLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    jsr unitVariables

    lda #IC_UIR
    jmp icodeWriteInstruction
.endproc

; This routine stores the root declaration of the unit in Q in unitDecl
; and ptr1.
.proc loadUnitDecl
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq unitDecl
    stq ptr1
    rts
.endproc

; This routine formats the label of the init block of the unit in
; unitDecl in icodeLabel.
.proc formatInitLabel
    ldq unitDecl
    stq intOp32
    lda #<lblUnitInit
    ldx #>lblUnitInit
    jmp icodeFormatLabel
.endproc

; This routine writes the code that pushes and initializes the variables
; of the unit in unitDecl.
.proc unitVariables
    ldq unitDecl
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq stmtPtr
    stq ptr1

    lda #<localVars
    ldx #>localVars
    ldy #0
    ldz #0
    jsr pushQ               ; localVars
    lda #<localDecls
    ldx #>localDecls
    ldy #0
    ldz #0
    jsr pushQ               ; localDecls
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ               ; declPtr
    jsr icodeVariableDeclarations

    lda #<localVars
    ldx #>localVars
    ldy #0
    ldz #0
    jsr pushQ                   ; localVars
    lda #<localDecls
    ldx #>localDecls
    ldy #0
    ldz #0
    jsr pushQ                   ; localDecls
    ldq stmtPtr
    stq ptr1
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ                   ; declPtr
    jmp icodeVariableDeclarations
.endproc
