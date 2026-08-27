;
; processIcodeInstructions.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; processIcodeInstructions routine

.include "asm.inc"
.include "c64.inc"
.include "icode.inc"
.include "codegen.inc"
.include "cbm_kernal.inc"

.export processIcodeInstructions, readIcodeByte

.import readInstruction, instruction
.import genThreeAddr, genOneInstruction, genTwoInstruction, genBinary, genTrinary, genUnary

.bss

readStatus: .res 1

.code

.proc processIcodeInstructions
L1: jsr readIcodeByte
    ; ldx #2
    ; jsr CHKIN
    ; jsr CHRIN
    sta instruction
    ; jsr READST
    ; lda STATUS
    lda readStatus
    and #$40
    beq :+
    rts

:   lda instruction
    jsr readInstruction
    lda instruction

    bit #IC_MASK_TRINARY
    beq :+
    jsr genTrinary
    bra L1

:   bit #IC_MASK_BINARY
    beq :+
    jsr genBinary
    bra L1

:   bit #IC_MASK_UNARY
    beq :+
    jsr genUnary
    bra L1

:   cmp #IC_ONL
    bne :+
    jsr newline
    bra L1

:   cmp #IC_AND
    bne :+
    jsr andOr
    bra L1
:   cmp #IC_ORA
    bne :+
    jsr andOr
    jmp L1

:   cmp #IC_ROU
    bne :+
    jsr roundTrunc
    jmp L1
:   cmp #IC_TRU
    bne :+
    jsr roundTrunc
    jmp L1

:   cmp #IC_POP
    bne :+
    genThree OC_JSR, RT_INCSP4
    jmp L1
:   cmp #IC_DEL
    bne :+
    genThree OC_JSR, RT_POPEAX
    genThree OC_JSR, RT_HEAPFREE
    jmp L1

:   cmp #IC_DEF
    bne :+
    genThree OC_JSR, RT_FILEFREE
    jmp L1

:   cmp #IC_CNL
    bne :+
    genThree OC_JSR, RT_CLEARINPUTBUF
    jmp L1

:   cmp #IC_NOT
    bne :+
    jsr notOper
    jmp L1

:   cmp #IC_SSR
    bne :+
    jsr ssrOper
    jmp L1

:   cmp #IC_SSW
    bne :+
    jsr sswOper
    jmp L1

:   cmp #IC_FSO
    bne :+
    genThree OC_JSR, RT_GETSTRBUFFER
    genThree OC_JSR, RT_PUSHEAX
    jmp L1

:   cmp #IC_JRP
    bne :+
    jsr jrpOper
    jmp L1

:   cmp #IC_RTS
    bne :+
    genThree OC_JMP, RT_RETURNFROMROUTINE

:   jmp L1
.endproc

.proc readIcodeByte
    phx
    ldx #2
    jsr CHKIN
    jsr CHRIN
    plx
    pha
    lda STATUS
    sta readStatus
    pla
    rts
.endproc

.proc andOr
    pha

    genThree OC_JSR, RT_POPTOINTOP1
    genThree OC_JSR, RT_POPTOINTOP2
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_INTOP1L

    pla
    cmp #IC_AND
    bne :+
    lda #OC_AND_ZEROPAGE
    bra L1
:   lda #OC_ORA_ZEROPAGE

L1: ldx #ZP_INTOP2L
    jsr genTwoInstruction

    genThree OC_JSR, RT_PUSHBYTESTACK

    rts
.endproc

.proc newline
    genTwoImmediate OC_LDA_IMMEDIATE, 13     ; carriage return
    genThree OC_JSR, CHROUT

    rts
.endproc

.proc roundTrunc
    pha

    genThree OC_JSR, RT_POPTOREAL

    pla
    cmp #IC_ROU
    bne :+
    genTwoImmediate OC_LDA_IMMEDIATE, 0
    genThree OC_JSR, RT_PRECRD

:   genThree OC_JSR, RT_FLOATTOINT16
    genThree OC_JSR, RT_PUSHFROMINTOP1

    rts
.endproc

.proc notOper
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_AND_IMMEDIATE, 1
    genTwoImmediate OC_EOR_IMMEDIATE, 1
    genThree OC_JSR, RT_PUSHEAX

    rts
.endproc

.proc ssrOper
    genThree OC_JSR, RT_POPEAX
    genThree OC_JSR, RT_STRINGSUBSCRIPTREAD
    genTwoImmediate OC_LDX_IMMEDIATE, 0
    genTwoImmediate OC_STX_ZEROPAGE, ZP_SREGL
    genTwoImmediate OC_STX_ZEROPAGE, ZP_SREGH
    genThree OC_JSR, RT_PUSHEAX

    rts
.endproc

.proc sswOper
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_TMP1
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_LDY_ZEROPAGE, ZP_TMP1
    genThree OC_JSR, RT_STRINGSUBSCRIPTCALC
    genThree OC_JSR, RT_PUSHADDRSTACK

    rts
.endproc

.proc jrpOper
    ; Activate the stack frame
    genOne OC_PLA
    genTwoImmediate OC_STA_ZEROPAGE, ZP_STACKFRAMEH
    genOne OC_PLA
    genTwoImmediate OC_STA_ZEROPAGE, ZP_STACKFRAMEL
    genThree OC_JSR, RT_POPEAX
    genTwoImmediate OC_STA_ZEROPAGE, ZP_TMP1
    genTwoImmediate OC_STX_ZEROPAGE, ZP_TMP2
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_NESTINGLEVEL
    genOne OC_PHA
    genTwoImmediate OC_LDA_ZEROPAGE, ZP_SREGL
    genTwoImmediate OC_STA_ZEROPAGE, ZP_NESTINGLEVEL
    genThree OC_JMP_INDIRECT, ZP_TMP1

    rts
.endproc
