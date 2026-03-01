;
; icodeRoutineParamsCleanup.s
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

paramPtrsOffset = 0
paramTypesOffset = paramPtrsOffset + 4

.export icodeRoutineParamsCleanup

.import loadStackValue, icodeFormatLabel, lblDeclInit
.import icodeOper1Label, icodeOper2Short, icodeWriteInstruction

.bss

paramNum: .res 1

.code

; Parameters on stack, bottom to top:
;   paramTypes
;   paramPtrs
.proc icodeRoutineParamsCleanup
    ; Go to the last parameter
    ldz #paramTypesOffset
    jsr loadStackValue
    stq ptr1
    ldz #0
:   nop
    lda (ptr1),z
    cmp #END_OF_PARAMS
    beq :+
    inz
    bne :-
:   stz paramNum

    lda paramNum
    beq DN

    ; Loop through the parameters
L1: dec paramNum
    ldz #paramTypesOffset
    jsr loadStackValue
    stq ptr1
    ldz paramNum
    nop
    lda (ptr1),z
    cmp #ARRAYDECL_ARRAY
    bne :+
    jsr arrayCleanup
    bra L2
:   cmp #ARRAYDECL_RECORD
    bne :+
    jsr arrayCleanup
    bra L2
:   cmp #ARRAYDECL_STRING
    bne :+
    lda #IC_DEL
    jsr icodeWriteInstruction
    bra L2
:   lda #IC_POP
    jsr icodeWriteInstruction

L2: lda paramNum
    bne L1

DN: jsr popQ
    jsr popQ
    rts
.endproc

.proc arrayCleanup
    ldz #paramPtrsOffset
    jsr loadStackValue
    stq ptr1

    lda paramNum
    asl a
    asl a
    taz
    neg
    neg
    nop
    lda (ptr1),z
    stq intOp32
    lda #<lblDeclInit
    ldx #>lblDeclInit
    jsr icodeFormatLabel
    jsr icodeOper1Label

    ldz #paramTypesOffset
    jsr loadStackValue
    stq ptr1
    ldz paramNum
    nop
    lda (ptr1),z
    jsr icodeOper2Short

    lda #IC_DCF
    jsr icodeWriteInstruction
    rts
.endproc
