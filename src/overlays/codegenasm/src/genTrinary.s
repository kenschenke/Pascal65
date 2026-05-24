;
; genTrinary.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; genTrinary routine

.include "asm.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"

.export genTrinary

.import pshOper, outOper, inpOper, strbuf, dataInstruction
.import genOneInstruction, genTwoInstruction, genThreeAddr, operand1
.import genArrayInit, genRecordInit, operand2, operand3

.proc genTrinary
    cmp #IC_ADD
    bne :+
    ldx #.lobyte(RT_ADD)
    ldy #.hibyte(RT_ADD)
    jsr genMath
    rts

:   cmp #IC_SUB
    bne :+
    ldx #.lobyte(RT_SUBTRACT)
    ldy #.hibyte(RT_SUBTRACT)
    jsr genMath
    rts

:   cmp #IC_MUL
    bne :+
    ldx #.lobyte(RT_MULTIPLY)
    ldy #.hibyte(RT_MULTIPLY)
    jsr genMath
    rts

:   cmp #IC_DVI
    bne :+
    ldx #.lobyte(RT_DIVINT)
    ldy #.hibyte(RT_DIVINT)
    jsr genMath
    rts

:   cmp #IC_BWA
    bne :+
    ldx #.lobyte(RT_BITWISEAND)
    ldy #.hibyte(RT_BITWISEAND)
    jsr genMath
    rts

:   cmp #IC_BWO
    bne :+
    ldx #.lobyte(RT_BITWISEOR)
    ldy #.hibyte(RT_BITWISEOR)
    jsr genMath
    rts

:   cmp #IC_BWX
    bne :+
    ldx #.lobyte(RT_BITWISEXOR)
    ldy #.hibyte(RT_BITWISEXOR)
    jsr genMath
    rts

:   cmp #IC_BSL
    bne :+
    ldx #.lobyte(RT_BITWISELSHIFT)
    ldy #.hibyte(RT_BITWISELSHIFT)
    jsr genMath
    rts

:   cmp #IC_BSR
    bne :+
    ldx #.lobyte(RT_BITWISERSHIFT)
    ldy #.hibyte(RT_BITWISERSHIFT)
    jsr genMath
    rts

:   cmp #IC_JSR
    bne :+
    jsr jsrOper
    rts

:   cmp #IC_PRP
    bne :+
    jsr prpOper
    rts

:   cmp #IC_DAT
    bne :+
    jsr dataInstruction

:   rts
.endproc

.proc genMath
    phx
    phy

    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand2+1
    genTwoAbsolute OC_LDY_IMMEDIATE, operand3+1
    ply
    plx
    lda #OC_JSR
    jsr genThreeAddr
    rts
.endproc

.proc jsrOper
    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_BOTH
    ldz #1
    jsr linkAddressLookup
    lda operand3+1
    beq :+
    genThree OC_JSR, 0
    rts

:   genThree OC_JMP, 0
    rts
.endproc

.proc prpOper
    genTwoAbsolute OC_LDA_IMMEDIATE, operand2+1
    genTwoImmediate OC_STA_ZEROPAGE, ZP_SREGL
    genTwoAbsolute OC_LDA_IMMEDIATE, operand3+1
    genTwoImmediate OC_STA_ZEROPAGE, ZP_SREGH

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
    genThree OC_JSR, RT_PUSHEAX
    rts
.endproc
