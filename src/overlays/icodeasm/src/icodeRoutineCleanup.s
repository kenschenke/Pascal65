;
; icodeRoutineCleanup.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

numLocalsOffset = 0
localVarsOffset = numLocalsOffset + 1

.export icodeRoutineCleanup

.import loadStackValue, icodeWriteInstruction

.bss

varIndex: .res 1

.code

; Parameters on stack, from bottom to top
;   localVars pointer
;   number of local vars (one byte)
.proc icodeRoutineCleanup
    lda #0
    jsr pushA

    ldz #numLocalsOffset
    nop
    lda (stackPointer),z
    bne :+
    jmp DN

:   ldz #localVarsOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

    ; Loop through the localVars, in descending order
:   ldz #numLocalsOffset
    nop
    lda (stackPointer),z
    sta varIndex

L1: dec varIndex
    bne :+
    jmp DN

    ldz #localVarsOffset
    jsr loadStackValue
    stq ptr1

    ldz varIndex
    nop
    lda (ptr1),z
    cmp #LOCALVARS_ARRAY
    bne :+
    lda #IC_DEL
    jmp L2
:   cmp #LOCALVARS_RECORD
    bne :+
    lda #IC_DEL
    jmp L2
:   cmp #LOCALVARS_DEL
    bne :+
    lda #IC_DEL
    jmp L2
:   cmp #LOCALVARS_FILE
    bne :+
    lda #IC_DEF
    jmp L2
:   lda #IC_POP

L2: jsr icodeWriteInstruction
    bra L1

DN: jsr popA
    jsr popA
    jsr popQ
    rts
.endproc
