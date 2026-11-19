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
.include "cbm_kernal.inc"

.export icodeWriteX, currentLineNumber, loadStackValue
.export icodeLabel, icodeFormatLabel, lblRoutineEnter, lblRoutineReturn
.export lblDeclInit, lblParamDeclInit
.export getRuntimeFeatures, setRuntimeFeature, setRuntimeMode, setStackSize

.import icodeFileOpen, icodeFileClose, icodeWriteInstruction
.import icodeStmts, icodeUnitRoutines, icodeRoutineDeclarations
.import icodeUnitDeclarations, icodeVariableDeclarations
.import icodeInitData, icodeWriteData, icodeFreeData, icodeSuppress
.import writeImports

.import operand1

.data

lblMain: .asciiz "main"
lblRoutineEnter: .asciiz "rtnenter"
lblRoutineReturn: .asciiz "rtnreturn"
lblDeclInit: .asciiz "di"
; Declaration block for a dynamic array parameter. A parameter has no decl,
; so its label is made from its symbol.
lblParamDeclInit: .asciiz "dp"

.bss

astRoot: .res 4
rootStmt: .res 4
currentLineNumber: .res 2
icodeLabel: .res 20
; The runtime packages the program needs (RTF_* in asm.inc). Code
; generation links only these (see rtpkg.inc).
runtimeFeatures: .res 1
; The parser's settings, for the icode file's header. The compiler apps
; set them (setRuntimeMode, setStackSize) before icodeWriteX.
runtimeMode: .res 1
stackSize: .res 2
nameLen: .res 1             ; for writeHeader
nameIndex: .res 1

.code

; Returns the runtime features (RTF_* in asm.inc) the program uses in A.
; The compiler apps pass them to code generation.
.proc getRuntimeFeatures
    lda runtimeFeatures
    rts
.endproc

; Records that the program uses the runtime feature (RTF_*) in A
.proc setRuntimeFeature
    ora runtimeFeatures
    sta runtimeFeatures
    rts
.endproc

; Sets the runtime mode (RT_MODE_* in asm.inc) in A, for the header
.proc setRuntimeMode
    sta runtimeMode
    rts
.endproc

; Sets the runtime stack size in A/X, for the header
.proc setStackSize
    sta stackSize
    stx stackSize+1
    rts
.endproc

; This routine writes the icode file's header (icode.inc) to the current
; output. The module's root declaration is in astRoot.
.proc writeHeader
    lda #ICODE_MAGIC0
    jsr CHROUT
    lda #ICODE_MAGIC1
    jsr CHROUT
    lda #ICODE_VERSION
    jsr CHROUT

    ; The kind: a unit or the program
    ldq astRoot
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    ldx #ICODE_KIND_PROGRAM
    cmp #TYPE_UNIT
    bne :+
    ldx #ICODE_KIND_UNIT
:   txa
    jsr CHROUT

    lda runtimeMode
    jsr CHROUT
    lda stackSize
    jsr CHROUT
    lda stackSize+1
    jsr CHROUT

    ; The name's length, then the name. CHROUT may change Z, so the
    ; index is kept in nameIndex.
    ldz #decl::name
    ldx #0
:   nop
    lda (ptr1),z
    beq :+
    inz
    inx
    cpx #ICODE_MAX_NAME
    bne :-
:   stx nameLen
    txa
    jsr CHROUT
    lda #0
    sta nameIndex
:   lda nameIndex
    cmp nameLen
    beq :+
    clc
    adc #decl::name
    taz
    nop
    lda (ptr1),z
    jsr CHROUT
    inc nameIndex
    bra :-
:   rts
.endproc

; Root of AST passed in Q
.proc icodeWriteX
    ; Keep a copy of the root
    stq astRoot

    lda #0
    sta runtimeFeatures

    lda #0
    sta icodeSuppress

    ; Initialize the data segments
    jsr icodeInitData

    ; Open the icode temporary file and write its header and imports
    jsr icodeFileOpen
    jsr writeHeader
    ldq astRoot
    jsr writeImports

    ; Enter the main scope
    ldq astRoot
    stq ptr1
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr scopeEnterSymtab

    ; Create stack entries for the global variables. Globals are never
    ; freed, so nothing is recorded for cleanup (no localVars storage).
    jsr pushQZero               ; localVars
    jsr pushQZero               ; localDecls
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

    ; The end of the module, with the runtime features it needs
    lda #IC_IBU
    sta operand1
    lda runtimeFeatures
    sta operand1+1
    lda #IC_EOM
    jsr icodeWriteInstruction

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
