;
; icodeWrite.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export icodeWriteX, currentLineNumber, loadStackValue
.export icodeLabel, icodeFormatLabel, lblRoutineEnter, lblRoutineReturn
.export lblDeclInit

.import icodeFileOpen, icodeFileClose, icodeWriteInstruction
.import icodeStmts, icodeUnitRoutines, icodeRoutineDeclarations
.import icodeUnitDeclarations, icodeVariableDeclarations
.import icodeInitData, icodeWriteData, icodeFreeData

.import operand1

.data

lblMain: .asciiz "main"
lblRoutineEnter: .asciiz "rtnenter"
lblRoutineReturn: .asciiz "rtnreturn"
lblDeclInit: .asciiz "di"

.bss

astRoot: .res 4
rootStmt: .res 4
localVars: .res MAX_LOCAL_VARS
localDecls: .res MAX_LOCAL_VARS*4
currentLineNumber: .res 2
icodeLabel: .res 20

.code

; Root of AST passed in Q
.proc icodeWriteX
    ; Keep a copy of the root
    stq astRoot

    ; Initialize the data segments
    jsr icodeInitData

    ; Open the icode temporary file
    jsr icodeFileOpen

    ; Enter the main scope
    ldq astRoot
    stq ptr1
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr scopeEnterSymtab

    ; Create stack entries for the global variables
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
    ldq astRoot
    stq ptr2
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr2),z
    stq rootStmt
    stq ptr2
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr2),z
    jsr pushQ                   ; declPtr
    jsr icodeVariableDeclarations
    jsr icodeUnitDeclarations

    ; Skip over global function/procedure declarations and start main code
    lda #IC_LBL
    sta operand1
    lda #<lblMain
    sta operand1+1
    lda #>lblMain
    sta operand1+2
    lda #IC_BRA
    jsr icodeWriteInstruction

    ; Root declarations
    ldq rootStmt
    stq ptr1
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeRoutineDeclarations

    jsr icodeUnitRoutines

    ; LOC: "main"
    lda #IC_LBL
    sta operand1
    lda #<lblMain
    sta operand1+1
    lda #>lblMain
    sta operand1+2
    lda #IC_LOC
    jsr icodeWriteInstruction

    ldq rootStmt
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    jsr scopeExit

    ; Write out the data segments
    jsr icodeWriteData

    ; Free data segments
    jsr icodeFreeData

    ; Close the temporary file
    jsr icodeFileClose

    rts
.endproc

.proc loadStackValue
    neg
    neg
    nop
    lda (stackPointer),z
    rts
.endproc

; This routine formats a label. The salt value is expected in intOp32.
; The prefix string is passed in A/X (null-terminated).
; The label is placed in icodeLabel and is null-terminated.
.proc icodeFormatLabel
    sta ptr1
    stx ptr1+1
    
    ; Copy the prefix into the label
    ldy #0
    ldx #0
:   lda (ptr1),y
    beq :+
    sta icodeLabel,x
    inx
    iny
    bne :-

    ; Add the prefix length to the address of the label
:   sty intOp2
    lda #0
    sta intOp2+1
    lda #<icodeLabel
    sta intOp1
    lda #>icodeLabel
    sta intOp1+1
    jsr addInt16

    ; Add the salt value to the end of the label
    lda intOp1
    ldx intOp1+1
    jsr hexstr
    rts
.endproc
