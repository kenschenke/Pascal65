;
; genUnary.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; genUnary routine

.include "asm.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"
.include "zeropage.inc"

.export genUnary

.import pshOper, outOper, inpOper, strbuf
.import genOneInstruction, genTwoInstruction, genThreeAddr, operand1
.import genDeclInit, addStringLiteral

.data

strLbl: .asciiz "strval"

.bss

label: .res 16

.code

.proc genUnary
    cmp #IC_PSH
    bne :+
    jsr pshOper
    rts

:   cmp #IC_OUT
    bne :+
    jsr outOper
    rts

:   cmp #IC_INP
    bne :+
    jsr inpOper
    rts

:   cmp #IC_SST
    bne :+
    jsr sstOper
    rts

:   cmp #IC_LOC
    bne :+
    lda #<strbuf
    ldx #>strbuf
    jsr linkAddressSet
    rts

:   cmp #IC_BRA
    bne :+
    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_BOTH
    ldz #1
    jsr linkAddressLookup
    genThree OC_JMP, 0

:   cmp #IC_BIF
    bne :+
    jsr bifOper
    rts

:   cmp #IC_BIT
    bne :+
    jsr bitOper
    rts

:   cmp #IC_PRE
    bne :+
    jsr predSucc
    rts
:   cmp #IC_SUC
    bne :+
    jsr predSucc
    rts

:   cmp #IC_NEW
    bne :+
    jsr newOper
    rts

:   cmp #IC_AIX
    bne :+
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_CALCARRAYELEM
    rts

:   cmp #IC_BWC
    bne :+
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_BITWISEINVERT
    rts

:   cmp #IC_ABS
    bne :+
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_ABS
    rts

:   cmp #IC_SQR
    bne :+
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_SQR
    rts

:   cmp #IC_CPY
    bne :+
    jsr cpyOper
    rts

:   cmp #IC_SCV
    bne :+
    jsr scvOper
    rts

:   cmp #IC_ASF
    bne :+
    jsr asfOper
    rts

:   cmp #IC_SSP
    bne :+
    jsr sspOper
    rts

:   cmp #IC_LIN
    bne :+
    ; genOne OC_NOP
    ; genOne OC_PHA
    ; genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    ; genOne OC_PLA
    ; genOne OC_NOP
    rts

:   cmp #IC_MEM
    bne :+
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_READVAR
    rts

:   cmp #IC_PPF
    bne :+
    jsr ppfOper
    rts

:   cmp #IC_DIA
    bne :+
    lda #ARRAYDECL_ARRAY
    jsr genDeclInit
    rts

:   cmp #IC_DIR
    bne :+
    lda #ARRAYDECL_RECORD
    jsr genDeclInit

:   rts
.endproc

.proc asfOper
    genOne OC_PLA
    genTwoImmediate OC_STA_ZEROPAGE, ZP_STACKFRAMEH
    genOne OC_PLA
    genTwoImmediate OC_STA_ZEROPAGE, ZP_STACKFRAMEL
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_NESTINGLEVEL
    genOne OC_PHA
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoImmediate OC_STA_ZEROPAGE, ZP_NESTINGLEVEL
    rts
.endproc

.proc bifOper
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_CMP_IMMEDIATE, 0
    genTwoImmediate OC_BNE, 3
    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_BOTH
    ldz #1
    jsr linkAddressLookup
    genThree OC_JMP, 0
    rts
.endproc

.proc bitOper
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_CMP_IMMEDIATE, 0
    genTwoImmediate OC_BEQ, 3
    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_BOTH
    ldz #1
    jsr linkAddressLookup
    genThree OC_JMP, 0
    rts
.endproc

.proc cpyOper
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+2
    genThree OC_JSR, RT_HEAPALLOC
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genOne OC_PHA
    genOne OC_TXA
    genOne OC_PHA
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+2
    genThree OC_JSR, RT_MEMCOPY
    genTwoImmediate OC_LDA_IMMEDIATE, 0
    genTwoImmediate OC_STA_ZEROPAGE, ZP_SREGL
    genTwoImmediate OC_STA_ZEROPAGE, ZP_SREGH
    genOne OC_PLA
    genOne OC_TAX
    genOne OC_PLA
    genThree OC_JSR, RT_PUSHEAX
    rts
.endproc

.proc newOper
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+2
    genThree OC_JSR, RT_HEAPALLOC
    genThree OC_JSR, RT_PUSHEAX
    rts
.endproc

.proc predSucc
    pha
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1

    pla
    cmp #IC_PRE
    bne :+
    genThree OC_JSR, RT_PRED
    rts
:   genThree OC_JSR, RT_SUCC
    rts
.endproc

.proc ppfOper
    genThree OC_JSR, RT_POPEAX

    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_LOW
    ldz #1
    jsr linkAddressLookup

    genTwoImmediate OC_LDA_IMMEDIATE, 0

    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_HIGH
    ldz #1
    jsr linkAddressLookup

    genTwoImmediate OC_LDX_IMMEDIATE, 0
    genTwoImmediate OC_LDY_ZEROPAGE, ZP_SREGL
    genThree OC_JSR, RT_PUSHSTACKFRAMEHEADER
    ; Push the stack frame pointer onto the CPU stack.
    ; This is popped back off by the ASF and JRP instructions.
    genOne OC_PHA
    genOne OC_TXA
    genOne OC_PHA
    rts
.endproc

.proc scvOper
    genThree OC_JSR, RT_POPEAX
    genTwoAbsolute OC_LDY_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_CONVERTSTRING
    genThree OC_JSR, RT_PUSHEAX
    rts
.endproc

.proc sspOper
    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_LOW
    ldz #1
    jsr linkAddressLookup

    genTwoImmediate OC_LDA_IMMEDIATE, 0
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L

    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_HIGH
    ldz #1
    jsr linkAddressLookup

    genTwoImmediate OC_LDA_IMMEDIATE, 0
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1H
    genTwoImmediate OC_LDY_IMMEDIATE, 0
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_SPL
    genTwoImmediate OC_STA_ZPINDIRECT, ZP_PTR1L
    genOne OC_INY
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_SPH
    genTwoImmediate OC_STA_ZPINDIRECT, ZP_PTR1L

    rts
.endproc

.proc sstOper
    lda operand1
    cmp #IC_ILS
    beq L1              ; Branch if null string

    ; Add the string literal

    ; Copy the template to the label
    ldx #0
:   lda strLbl,x
    beq :+
    sta label,x
    inx
    bne :-

    ; Add the length of strLbl to label's address
:   stx intOp2
    lda #0
    sta intOp2+1
    lda #<label
    sta intOp1
    lda #>label
    sta intOp1+1
    jsr addInt16
    lda intOp1
    pha
    lda intOp1+1
    pha
    
    ; Add the codeOffset to the label
    lda codeOffset
    sta intOp1
    lda codeOffset+1
    sta intOp1+1
    plx
    pla
    jsr writeInt16

    ; Save the string literal
    lda #<label
    ldx #>label
    jsr addStringLiteral

    ; Fill in the address of the string literal
    lda #<label
    ldx #>label
    ldy #LINKADDR_LOW
    ldz #1
    jsr linkAddressLookup
    lda #<label
    ldx #>label
    ldy #LINKADDR_HIGH
    ldz #3
    jsr linkAddressLookup

L1: genTwoImmediate OC_LDA_IMMEDIATE, 0
    genTwoImmediate OC_LDX_IMMEDIATE, 0
    genThree OC_JSR, RT_STRINGINIT

    rts
.endproc
