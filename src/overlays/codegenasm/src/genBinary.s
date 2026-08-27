;
; genBinary.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; genBinary routine

.include "asm.inc"
.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"

.export genBinary

.import genOneInstruction, genTwoInstruction, genThreeAddr
.import operand1, operand2, strbuf

.proc genBinary

    cmp #IC_MOD
    bne :+
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_MOD
    rts

:   cmp #IC_DIV
    bne :+
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_DIVIDE
    rts

:   cmp #IC_SET
    bne :+
    jsr setOper
    rts

:   cmp #IC_CCT
    bne :+
    jsr cctOper
    rts

:   cmp #IC_EQU
    bne :+
    lda #EXPR_EQ
    jsr genComp
    rts
:   cmp #IC_NEQ
    bne :+
    lda #EXPR_NE
    jsr genComp
    rts
:   cmp #IC_LST
    bne :+
    lda #EXPR_LT
    jsr genComp
    rts
:   cmp #IC_LSE
    bne :+
    lda #EXPR_LTE
    jsr genComp
    rts
:   cmp #IC_GRT
    bne :+
    lda #EXPR_GT
    jsr genComp
    rts
:   cmp #IC_GTE
    bne :+
    lda #EXPR_GTE
    jsr genComp
    rts

:   cmp #IC_POF
    bne :+
    ; Restore the nesting level
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_LIBSTACKCLEANUP
    rts

:   cmp #IC_PUF
    bne :+
    jsr pufOper
    rts

:   cmp #IC_SFH
    bne :+
    jsr sfhOper
    rts

:   cmp #IC_CVI
    bne :+
    jsr cviOper
    rts

:   cmp #IC_DCF
    bne :+
    jsr dcfOper
    rts

:   cmp #IC_DCC
    bne :+
    jsr dccOper

:   rts
.endproc

.proc cviOper
    genThree OC_JSR, RT_POPTOINTOP1AND2
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_CONVERTINT
    genThree OC_JSR, RT_PUSHFROMINTOP1AND2
    rts
.endproc

.proc dccOper
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
    genTwoAbsolute OC_LDY_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_CLONEDECL
    rts
.endproc

.proc dcfOper
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
    genTwoAbsolute OC_LDY_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_FREEDECL
    rts
.endproc

.proc genComp
    pha

    lda operand1+1
    cmp #TYPE_ENUMERATION
    beq enum1
    cmp #TYPE_ENUMERATION_VALUE
    bne L1

enum1:
    lda #TYPE_WORD
    sta operand1+1

L1: lda operand2+1
    cmp #TYPE_ENUMERATION
    beq enum2
    cmp #TYPE_ENUMERATION_VALUE
    bne L2

enum2:
    lda #TYPE_WORD
    sta operand2+1

L2: genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand2+1

    lda #OC_LDY_IMMEDIATE
    plx
    jsr genTwoInstruction
    genThree OC_JSR, RT_COMP
    rts
.endproc

.proc cctOper
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR2L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR2H
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDX_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_CONCATSTRING
    genThree OC_JSR, RT_PUSHEAX
    rts
.endproc

.proc pufOper
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
    genTwoAbsolute OC_LDY_IMMEDIATE, operand1+1
    genThree OC_JSR, RT_PUSHSTACKFRAMEHEADER

    ; Push the stack frame pointer onto the CPU stack.
    ; This is popped back off by the ASF and JRP instructions.
    genOne OC_PHA
    genOne OC_TXA
    genOne OC_PHA
    rts
.endproc

.proc sfhOper
    lda operand1+1
    cmp #FH_FILENUM
    bne :+
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_SREGL
    bra L1
:   genTwoAbsolute OC_LDA_IMMEDIATE, operand1+1

L1: genTwoAbsolute OC_LDX_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_SETFH

    lda operand1+1
    cmp #FH_STRING
    bne :+
    genThree OC_JSR, RT_RESETSTRBUFFER
:   rts
.endproc

.proc setOper
    lda operand1+1
    cmp #TYPE_STRING_VAR
    beq :+

    genThree OC_JSR, RT_POPEAX      ; pop the variable info off the stack
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genTwoAbsolute OC_LDX_IMMEDIATE, operand1+1
    genTwoAbsolute OC_LDA_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_ASSIGN
    rts

:   genThree OC_JSR, RT_POPEAX      ; pop the variable info off the stack
    genTwoImmediate OC_STA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_STX_ZEROPAGE, ZP_PTR1H
    genThree OC_JSR, RT_POPEAX      ; pop the rvalue off the stack
    genTwoImmediate OC_STA_ZEROPAGE, ZP_TMP1
    genTwoImmediate OC_STX_ZEROPAGE, ZP_TMP2
    genTwoAbsolute OC_LDA_IMMEDIATE, operand2+1
    genThree OC_JSR, RT_PUSHAX      ; push the rvalue type onto the stack
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_PTR1L
    genTwoImmediate OC_LDX_ZEROPAGE, ZP_PTR1H
    genThree OC_JSR, RT_PUSHAX      ; push the lvalue address onto the stack
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_TMP1
    genTwoImmediate OC_LDX_ZEROPAGE, ZP_TMP2
    genThree OC_JSR, RT_ASSIGNSTRING
    rts
.endproc
