;
; comp.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine performs a comparison between two values:
; <operand-1> and <operand-2> which are on the runtime stack.
; <operand-2> is on the top of the stack. When the routine
; exits the boolean result of the comparison will be left
; on the stack.
;
; If either operand is real, the comparison is done as real numbers.
; Otherwise, if either operand is signed the comparison is done as
; signed. If both operands are unsigned only then is the comparison
; done as unsigned. For any integer comparisons, it is done as 32-bit.
;
; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - comparison operation (from expr.inc)

.include "runtime.inc"
.include "expr.inc"
.include "types.inc"

.export comp

.import prepOperands32, prepOperandsReal, pusheax, geUint32, gtUint32, leUint32, ltUint32
.import leUint32, ltUint32, eqInt32, leInt32, ltInt32, geInt32, gtInt32
.import floatEq, floatGt, floatGte, floatLt, floatLte

.bss

compOper: .res 1

.code

.proc comp
    sty compOper
    cmp #TYPE_REAL          ; Is <operand-1> real?
    beq @Real
    cpx #TYPE_REAL          ; Is <operand-2> real?
    beq @Real
    jsr isUnsigned
    beq @Unsigned

    ; One or both operands are signed.
    ldy #TYPE_LONGINT
    jsr prepOperands32
    jmp compSigned

@Unsigned:
    ; Both operands are unsigned.
    ldy #TYPE_CARDINAL
    jsr prepOperands32
    jmp compUnsigned

@Real:
    ; One or both operands is real. Make sure both operands
    ; are real then do the comparison.
    ldy #TYPE_REAL
    jsr prepOperandsReal
    jmp compReal
.endproc

.proc compUnsigned
    lda compOper
    cmp #EXPR_LT
    beq @LT
    cmp #EXPR_LTE
    beq @LTE
    cmp #EXPR_GT
    beq @GT
    cmp #EXPR_GTE
    beq @GTE
    cmp #EXPR_EQ
    beq @EQ
    bne @NE

@LT:
    jsr ltUint32
    jmp @Done

@LTE:
    jsr leUint32
    jmp @Done

@GT:
    jsr gtUint32
    jmp @Done

@GTE:
    jsr geUint32
    jmp @Done

@EQ:
    jsr eqInt32
    jmp @Done

@NE:
    jsr eqInt32
    eor #1

@Done:
    ldx #0
    stx sreg
    stx sreg + 1
    jmp pusheax
.endproc

.proc compSigned
    lda compOper
    cmp #EXPR_LT
    beq @LT
    cmp #EXPR_LTE
    beq @LTE
    cmp #EXPR_GT
    beq @GT
    cmp #EXPR_GTE
    beq @GTE
    cmp #EXPR_EQ
    beq @EQ
    bne @NE

@LT:
    jsr ltInt32
    jmp @Done

@LTE:
    jsr leInt32
    jmp @Done

@GT:
    jsr gtInt32
    jmp @Done

@GTE:
    jsr geInt32
    jmp @Done

@EQ:
    jsr eqInt32
    jmp @Done

@NE:
    jsr eqInt32
    eor #1

@Done:
    ldx #0
    stx sreg
    stx sreg + 1
    jmp pusheax
.endproc

.proc compReal
    lda compOper
    cmp #EXPR_LT
    beq @LT
    cmp #EXPR_LTE
    beq @LTE
    cmp #EXPR_GT
    beq @GT
    cmp #EXPR_GTE
    beq @GTE
    cmp #EXPR_EQ
    beq @EQ
    bne @NE

@LT:
    jsr floatLt
    jmp @Done

@LTE:
    jsr floatLte
    jmp @Done

@GT:
    jsr floatGt
    jmp @Done

@GTE:
    jsr floatGte
    jmp @Done

@EQ:
    jsr floatEq
    jmp @Done

@NE:
    jsr floatEq
    eor #1

@Done:
    ldx #0
    stx sreg
    stx sreg + 1
    jmp pusheax
.endproc

; This routine checks to see if both operands are unsigned
; integers. If so, the Z flag is 0.
.proc isUnsigned
    pha                     ; Save <operand-1> type on stack
    txa                     ; Copy <operand-2> type to A
    jsr isOperandUnsigned
    bne @Done
    pla                     ; Pop <operand-1> type off stack
    jmp isOperandUnsigned
@Done:
    pla                     ; Pop <operand-1> type off stack
    rts
.endproc

; This routine checks to see if the operand in A is an
; unsigned integer data type. If so, the Z flag is 0.
.proc isOperandUnsigned
    cmp #TYPE_CHARACTER
    beq @Done
    cmp #TYPE_BYTE
    beq @Done
    cmp #TYPE_WORD
    beq @Done
    cmp #TYPE_CARDINAL
@Done:
    rts
.endproc
