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
.import addStringLiteral

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
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_PUSHBYTESTACK
    rts

wordOper:
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+2
    genThree OC_JSR, RT_PUSHINTSTACK
    rts

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
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+2     ; level
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+3     ; offset
    genTwoAbsolute OC_LDY_IMMEDIATE, operand1+1     ; type
    genThree OC_JSR, RT_PUSHVAR
    rts

vdwOper:
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+2     ; level
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+3     ; offset
    genThree OC_JSR, RT_CALCSTACKOFFSET
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_LDX_ZEROPAGE, ZP_PTR1H
    genThree OC_JSR, RT_PUSHADDRSTACK
    rts

vvrOper:
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+2     ; level
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
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_STACKFRAMEL
    genOne OC_SEC
    genTwoImmediate OC_SBC_IMMEDIATE, 4
    genOne OC_PHA
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_STACKFRAMEH
    genTwoImmediate OC_SBC_IMMEDIATE, 0
    genOne OC_TAX
    genOne OC_PLA
    genThree OC_JSR, RT_PUSHEAX
    rts
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
