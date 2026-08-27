;
; icodeRoutineDeclaration.s
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

; Local variables
; localVarsOffset must be zero
localVarsOffset = 0
localDeclsOffset = localVarsOffset + MAX_LOCAL_VARS
numLocalsOffset = localDeclsOffset + MAX_LOCAL_VARS*4
; Parameters passed from caller
typeOffset = numLocalsOffset + 1
declOffset = typeOffset + 4

.export icodeRoutineDeclaration

.import loadStackValue, icodeRoutineDeclarations, icodeFormatLabel
.import lblRoutineEnter, icodeOper1Label, icodeWriteInstruction
.import icodeVariableDeclarations, icodeRoutineCleanup, icodeStmts

; Parameters are passed on the stack, bottom to top:
;   Declaration
;   Type
.proc icodeRoutineDeclaration
    lda #0
    jsr pushA               ; numLocals
    lda #MAX_LOCAL_VARS*4
    jsr pushBlock
    lda #MAX_LOCAL_VARS
    jsr pushBlock

    ; If this is a forward declaration, skip it
    ldz #typeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISFORWARD
    beq :+
    jmp DN

    ; Clear localVars
:   lda #0
    tax
    ldz #localVarsOffset
:   nop
    sta (stackPointer),z
    inz
    inx
    cpx #MAX_LOCAL_VARS
    bne :-

    ; Handle any nested routines
    ldz #declOffset
    jsr loadStackValue
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

    ; If this is a unit, enter the unit's scope
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::unitSymtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr scopeEnterSymtab

:   ldz #declOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblRoutineEnter
    ldx #>lblRoutineEnter
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    ; Push the local variables onto the stack
    ldq stackPointer
    stq ptr1
    lda #localDeclsOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr3
    ldz #declOffset
    jsr loadStackValue
    stq ptr2
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldq ptr1
    jsr pushQ               ; localVars storage
    ldq ptr3
    jsr pushQ               ; localDecls storage
    ldq ptr2
    jsr pushQ               ; first declaration
    jsr icodeVariableDeclarations
    ldz #numLocalsOffset
    nop
    sta (stackPointer),z

    ; Process the routine's statements
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    ; If this is a unit, exit the unit's scope
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::unitSymtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr scopeExit

    ; Tear down the routine's stack frame and free its local variables
:   ldz #numLocalsOffset
    nop
    lda (stackPointer),z
    pha
    lda #localDeclsOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    ldq stackPointer
    jsr pushQ               ; localVars
    ldq ptr2
    jsr pushQ               ; localDecls
    pla
    jsr pushA               ; numLocals
    jsr icodeRoutineCleanup
    lda #IC_RTS
    jsr icodeWriteInstruction

DN: lda #MAX_LOCAL_VARS
    jsr popBlock
    lda #MAX_LOCAL_VARS*4
    jsr popBlock
    jsr popA
    jsr popQ
    jsr popQ
    rts
.endproc
