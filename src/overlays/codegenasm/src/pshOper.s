;
; pshOper.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; pshOper routine

.include "asm.inc"
.include "icode.inc"
.include "linker.inc"
.include "asmlib.inc"
.include "codegen.inc"
.include "zeropage.inc"

.export pshOper

.import operand1, genOneInstruction, genTwoInstruction, genThreeAddr
.import addStringLiteral, frameReloc, isUnitModule

.data

lblStr: .asciiz "strVal"

.bss

label: .res 16

.code

.proc pshOper
    lda operand1
    cmp #IC_BOO
    beq byteOper
    cmp #IC_CHR
    beq byteOper
    cmp #IC_IBU
    beq byteOper
    cmp #IC_IBS
    beq byteOper
    cmp #IC_IWU
    beq wordOper
    cmp #IC_IWS
    beq wordOper
    cmp #IC_ILU
    beq dwordOper
    cmp #IC_ILS
    beq dwordOper
    cmp #IC_STR
    bne :+
    jsr strOper
    rts
:   cmp #IC_FLT
    bne :+
    jsr strOper
    rts
:   cmp #IC_VDR
    bne :+
    jmp vdrOper
:   cmp #IC_VDW
    bne :+
    jmp vdwOper
:   cmp #IC_VVR
    bne :+
    jmp vvrOper
:   cmp #IC_VVW
    bne :+
    jmp vvwOper
:   cmp #IC_RET
    bne :+
    jmp retOper
:   rts

byteOper:
    ; The byte follows the JSR
    genThree OC_JSR, RT_PUSHBYTEINLINE
    lda operand1+1
    jmp genOneInstruction

wordOper:
    ; The integer follows the JSR
    genThree OC_JSR, RT_PUSHINTINLINE
    lda operand1+1
    jsr genOneInstruction
    lda operand1+2
    jmp genOneInstruction

dwordOper:
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+3
    genTwoImmediate OC_STA_ZEROPAGE, ZP_SREGL
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+4
    genTwoImmediate OC_STA_ZEROPAGE, ZP_SREGH
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+2
    genThree OC_JSR, RT_PUSHEAX
    rts

vdrOper:
    ; At level 1 (a global) or 2 (in a routine declared in the program),
    ; the offset and type follow the JSR
    lda operand1+2
    cmp #1
    bne :+
    genThree OC_JSR, RT_PUSHGLOBALINLINE

    ldz #0
    jsr frameOffset
    lda operand1+3                  ; offset
    jsr genOneInstruction
    lda operand1+1                  ; type
    jmp genOneInstruction
    ; Otherwise the level, offset and type follow the JSR
:
    genThree OC_JSR, RT_PUSHVARINLINE
    lda operand1+2                  ; level
    jsr genOneInstruction
    lda operand1+3                  ; offset
    jsr genOneInstruction
    lda operand1+1                  ; type
    jmp genOneInstruction

vdwOper:
    ; At level 1 or 2, the offset follows the JSR
    lda operand1+2
    cmp #1
    bne :+
    genThree OC_JSR, RT_PUSHGLOBALADDR

    ldz #0
    jsr frameOffset
    lda operand1+3                  ; offset
    jmp genOneInstruction
:
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+2     ; level
    ldz #1
    jsr frameOffset
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+3     ; offset
    genThree OC_JSR, RT_PUSHVARADDR
    rts

vvrOper:
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+2     ; level
    ldz #1
    jsr frameOffset
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+3     ; offset
    genThree OC_JSR, RT_CALCSTACKOFFSET
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_LDX_ZEROPAGE, ZP_PTR1H
    genTwoImmediate OC_LDY_IMMEDIATE, 1
    genTwoImmediate OC_LDA_ZPINDIRECT, ZP_PTR1L
    genOne OC_TAX
    genOne OC_DEY
    genTwoImmediate OC_LDA_ZPINDIRECT, ZP_PTR1L
    genThree OC_JSR, RT_PUSHINTSTACK
    rts

vvwOper:
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+2     ; level
    ldz #1
    jsr frameOffset
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+3     ; offset
    genThree OC_JSR, RT_CALCSTACKOFFSET
    genTwoImmediate OC_LDA_IMMEDIATE, 0
    genTwoImmediate OC_STA_ZEROPAGE, ZP_SREGL
    genTwoImmediate OC_STA_ZEROPAGE, ZP_SREGH
    genTwoImmediate OC_LDY_IMMEDIATE, 1
    genTwoImmediate OC_LDA_ZPINDIRECT, ZP_PTR1L
    genOne OC_TAX
    genOne OC_DEY
    genTwoImmediate OC_LDA_ZPINDIRECT, ZP_PTR1L
    genThree OC_JSR, RT_PUSHEAX
    rts

retOper:
    genThree OC_JSR, RT_PUSHRETADDR
    rts
.endproc

; This routine writes a LINKADDR_FRAME relocation for a level 1 offset in
; another frame than the program's, Z bytes past codeOffset. The offset is
; relative to the frame's first slot, which the linker adds. The frame is
; operand1+4, from 1 in the file's frames table, or 0 for the module's own,
; which is relocated only in a unit's file (isUnitModule).
.proc frameOffset
    lda operand1+4
    bne RL
    lda operand1+2
    cmp #1
    bne :+
    lda isUnitModule
    beq :+
    lda #0
RL: jmp frameReloc
:   rts
.endproc

.proc strOper
    ; Format the label for the string literal
    ldx #0
:   lda lblStr,x
    beq :+
    sta label,x
    inx
    bne :-

:   stx intOp2
    lda #0
    sta intOp2+1
    lda #<label
    sta intOp1
    lda #>label
    sta intOp1+1
    jsr addInt16
    lda intOp1
    sta ptr1
    lda intOp1+1
    sta ptr1+1
    lda codeOffset
    sta intOp1
    lda codeOffset+1
    sta intOp1+1
    lda ptr1
    ldx ptr1+1
    jsr writeInt16

    ; Load A/X with the address of the string literal in the data segment
    lda #<label
    ldx #>label
    ldy #LINKADDR_LOW
    ldz #1
    jsr linkAddressLookup
    genTwoImmediate OC_LDA_IMMEDIATE, 0
    
    lda #<label
    ldx #>label
    ldy #LINKADDR_HIGH
    ldz #1
    jsr linkAddressLookup
    genTwoImmediate OC_LDX_IMMEDIATE, 0

    ; If this is a real literal, convert it first.
    lda operand1
    cmp #IC_FLT
    bne :+
    genThree OC_JSR, RT_STRTOFLOAT

    ; Push the string literal address onto the stack
:   genThree OC_JSR, RT_PUSHEAX

    ; Add the string literal to the data segment
    lda #<label
    ldx #>label
    jsr addStringLiteral

    rts
.endproc
