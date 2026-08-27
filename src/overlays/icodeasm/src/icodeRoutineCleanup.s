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
localDeclsOffset = numLocalsOffset + 1
localVarsOffset = localDeclsOffset + 4

.export icodeRoutineCleanup

.import loadStackValue, icodeWriteInstruction, icodeLabel
.import icodeOper1Label, icodeOper2Short

.bss

varIndex: .res 1

.data

diStr: .asciiz "di"

.code

; Parameters on stack, from bottom to top
;   localVars pointer
;   localDecls pointer
;   number of local vars (one byte)
.proc icodeRoutineCleanup
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

:   ldz #localDeclsOffset
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
    bpl :+
    jmp DN

:   ldz #localVarsOffset
    jsr loadStackValue
    stq ptr1

    ldz varIndex
    nop
    lda (ptr1),z
    cmp #LOCALVARS_ARRAY
    bne :+
    jsr handleArray
    bra L1
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
    jsr popQ
    jsr popQ
    rts
.endproc

.proc handleArray
    ldz #localDeclsOffset
    jsr loadStackValue
    stq ptr1

    lda varIndex
    asl a
    asl a
    taz
    neg
    neg
    nop
    lda (ptr1),z
    jsr formatDeclLabel
    jsr icodeOper1Label
    lda #LOCALVARS_ARRAY
    jsr icodeOper2Short
    lda #IC_DCF
    jsr icodeWriteInstruction
    rts
.endproc

.proc formatDeclLabel
    stq intOp32
    ldx #0
:   lda diStr,x
    beq :+
    sta icodeLabel,x
    inx
    bne :-

:   stx tmp1
    lda #<icodeLabel
    clc
    adc tmp1
    pha
    lda #>icodeLabel
    adc #0
    tax
    pla
    jsr hexstr
    rts
.endproc
