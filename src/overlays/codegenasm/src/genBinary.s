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
.import pendingPops

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
    jsr pofOper
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
    ; The two types follow the JSR
    genThree OC_JSR, RT_CONVERTINLINE
    lda operand1+1
    jsr genOneInstruction
    lda operand2+1
    jmp genOneInstruction
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

L2: ; The two types and the comparison follow the JSR
    genThree OC_JSR, RT_COMPINLINE
    lda operand1+1
    jsr genOneInstruction
    lda operand2+1
    jsr genOneInstruction
    pla
    jmp genOneInstruction
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
    ; callRoutine stores the return address
    lda operand1+1
    cmp #2
    bne :+
    genThree OC_JSR, RT_PUSHFRAMECALL2
    rts
:   genTwoAbsolute OC_LDY_IMMEDIATE, operand1+1
    ; This leaves the stack frame pointer on the CPU stack. It is
    ; popped back off by callRoutine.
    genThree OC_JSR, RT_PUSHFRAMECALL
    rts
.endproc

; Pops the parameters (the POPs before this) and removes the stack frame,
; leaving a function's value. popFrameN takes the number of parameters,
; plus $80 for a function, from the byte after the JSR.
.proc pofOper
    genThree OC_JSR, RT_POPFRAMEN
    lda operand1+1
    beq :+
    lda #$80
:   ora pendingPops
    jsr genOneInstruction
    lda #0
    sta pendingPops
    rts
.endproc

.proc sfhOper
    ; ReadStr: the string object is on the stack. setStringInput
    ; copies it to the input buffer and sets the input file handle.
    lda operand1+1
    cmp #FH_STRING
    bne :+
    lda operand2+1
    beq :+                  ; Branch if output (WriteStr)
    genThree OC_JSR, RT_POPEAX
    genThree OC_JSR, RT_SETSTRINGINPUT
    rts

:   lda operand1+1
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

    ; The variable's type and the value's follow the JSR
    genThree OC_JSR, RT_ASSIGNINLINE
    lda operand1+1
    jsr genOneInstruction
    lda operand2+1
    jmp genOneInstruction

    ; The value's type follows the JSR
:   genThree OC_JSR, RT_ASSIGNSTRINLINE
    lda operand2+1
    jmp genOneInstruction
    rts
.endproc
