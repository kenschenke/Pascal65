;
; icodeLibrarySubroutineCall.s
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
.include "asm.inc"

levelOffset = 0
paramPtrsOffset = levelOffset + 1
paramTypesOffset = paramPtrsOffset + MAX_NUM_PARAMS*4
isRtnPtrOffset = paramTypesOffset + MAX_NUM_PARAMS
rtnTypeOffset = isRtnPtrOffset + 1
symPtrOffset = rtnTypeOffset + 4
exprOffset = symPtrOffset + 4

.export icodeLibrarySubroutineCall

.import icodeRoutineCall, icodeFormatLabel, icodeWriteInstruction
.import icodeOper1Label, icodeOper1Short, icodeOper2Short, icodeOper3Short
.import icodeRoutineParamsCleanup, loadStackValue, lblRoutineEnter, lblRoutineReturn
.import setRuntimeFeature

.data

; Library routines that need the runtime's trig package (System's Sin, Cos
; and Tan). The list ends with an empty name.
; One .asciiz per name: with several strings .asciiz ends only the last.
trigNames:
    .asciiz "sin"
    .asciiz "cos"
    .asciiz "tan"
    .byte 0

.code

; This routine records RTF_TRIG if the library routine being called is
; Sin, Cos or Tan. Its declaration is in intOp32, which is preserved. The
; names are compared without case.
.proc checkTrigCall
    ldx #0                  ; Index into trigNames
NX: ldz #decl::name
CL: nop
    lda (intOp32),z         ; Next character of the routine's name
    and #$7f                ; Ignore case
    cmp trigNames,x
    bne SK                  ; Branch if not this name
    cmp #0
    beq FD                  ; Branch if the whole name matched
    inz
    inx
    bra CL
SK: lda trigNames,x         ; Skip the rest of this name
    beq :+
    inx
    bra SK
:   inx                     ; Past the null
    lda trigNames,x
    bne NX                  ; Branch if there's another name
    rts
FD: lda #RTF_TRIG
    jmp setRuntimeFeature
.endproc

; Arguments passed on stack, bottom to top:
;   expression ptr
;   symbol ptr
;   routine type ptr
;   isRtnPtr
.proc icodeLibrarySubroutineCall
    lda #MAX_NUM_PARAMS
    jsr pushBlock                   ; paramTypes

    lda #MAX_NUM_PARAMS*4
    jsr pushBlock                   ; paramPtrs

    lda #0
    jsr pushA                       ; level

    ; Set all paramTypes to END_OF_PARAMS
    ldz #paramTypesOffset
    lda #END_OF_PARAMS
    ldx #0
:   nop
    sta (stackPointer),z
    inz
    inx
    cpx #MAX_NUM_PARAMS
    bne :-
    
    ; Handle the routine call
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #symPtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #rtnTypeOffset
    jsr loadStackValue
    stq ptr3
    ldz #isRtnPtrOffset
    nop
    lda (stackPointer),z
    pha
    ldq stackPointer
    stq ptr4
    ldq ptr1
    jsr pushQ               ; expression
    ldq ptr2
    jsr pushQ               ; symbol
    ldq ptr3
    jsr pushQ               ; type
    lda #1
    jsr pushA               ; is a library call
    pla
    jsr pushA               ; isRtnPtr
    lda #paramTypesOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq ptr4
    clc
    adcq intOp32
    jsr pushQ               ; paramTypes
    lda #paramPtrsOffset
    sta intOp32
    ldq ptr4
    clc
    adcq intOp32
    jsr pushQ               ; paramPtrs
    jsr icodeRoutineCall
    ldz #levelOffset
    nop
    sta (stackPointer),z

    ; Call the routine
    ldz #isRtnPtrOffset
    nop
    lda (stackPointer),z
    beq :+
    ; Routine pointer
    lda #IC_JRP
    jsr icodeWriteInstruction
    bra L1

    ; Not a routine pointer
:   ldz #symPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq intOp32
    jsr checkTrigCall
    lda #<lblRoutineEnter
    ldx #>lblRoutineEnter
    jsr icodeFormatLabel
    jsr icodeOper1Label
    ldz #levelOffset
    nop
    lda (stackPointer),z
    jsr icodeOper2Short
    lda #1
    jsr icodeOper3Short
    lda #IC_JSR
    jsr icodeWriteInstruction

L1: ldz #exprOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblRoutineReturn
    ldx #>lblRoutineReturn
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    ; Tear down the routine's stack frame and free parameters

    ldq stackPointer
    stq ptr1
    lda #paramTypesOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq ptr1
    clc
    adcq intOp32
    jsr pushQ
    lda #paramPtrsOffset
    sta intOp32
    ldq ptr1
    clc
    adcq intOp32
    jsr pushQ
    jsr icodeRoutineParamsCleanup

    ldz #rtnTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_PROCEDURE
    beq :+
    lda #1
    bra L2
:   lda #0
L2: jsr icodeOper1Short
    lda #0
    jsr icodeOper2Short
    lda #IC_POF
    jsr icodeWriteInstruction

    ldz #rtnTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_PROCEDURE
    beq :+

    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    bra DN

:   lda #TYPE_VOID
DN: pha
    jsr popA
    lda #MAX_NUM_PARAMS*4
    jsr popBlock
    lda #MAX_NUM_PARAMS
    jsr popBlock
    jsr popA
    jsr popQ
    jsr popQ
    jsr popQ
    pla
    rts
.endproc
