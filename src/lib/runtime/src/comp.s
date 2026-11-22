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
.import compOper, cmpVals, cmpKinds     ; irqcall.s
.import popeax, heapFree, strCompareN, arrayLength

.code

.proc comp
    sty compOper
    pha
    jsr isStringKind        ; Is <operand-1> a string?
    beq @String
    txa
    jsr isStringKind        ; Is <operand-2> a string?
    beq @String
    pla
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

@String:
    pla
    jmp compString
.endproc

; This routine sets the Z flag if the type in A is a string kind: a string
; literal, a String variable, a string object or an array of Char. A Char
; isn't one: two Chars compare as numbers. The type checker only lets a
; Char be compared with a string as a one-character string.
.proc isStringKind
    cmp #TYPE_STRING_LITERAL
    beq @Done
    cmp #TYPE_STRING_VAR
    beq @Done
    cmp #TYPE_STRING_OBJ
    beq @Done
    cmp #TYPE_ARRAY
@Done:
    rts
.endproc

; This routine compares two strings. The types of <operand-1> and
; <operand-2> are in A and X, and each operand is a string kind or a Char.
; Each becomes a pointer to its first character and a length (strOperand),
; so nothing is copied, and strCompareN compares them. A string object is
; freed after the comparison. The Boolean result is pushed.
.proc compString
    sta cmpKinds
    stx cmpKinds + 1
    jsr popeax              ; <operand-2>
    sta cmpVals + 2
    stx cmpVals + 3
    jsr popeax              ; <operand-1>
    sta cmpVals
    stx cmpVals + 1

    ldx #1
    jsr strOperand          ; <operand-2>
    sta tmp2
    lda ptr1
    sta ptr4
    lda ptr1 + 1
    sta ptr4 + 1
    ldx #0
    jsr strOperand          ; <operand-1>
    sta tmp1
    lda ptr1
    sta ptr3
    lda ptr1 + 1
    sta ptr3 + 1
    jsr strCompareN

    ; The result is $ff, 0 or 1. Each operator is true for one result or
    ; false for one: LT ($ff), LTE (not 1), GT (1), GTE (not $ff), EQ (0)
    ; and NE (not 0).
    sta tmp2                ; The result
    lda compOper
    ldy #$ff
    cmp #EXPR_LT
    beq @Is
    cmp #EXPR_GTE
    beq @Not
    ldy #1
    cmp #EXPR_GT
    beq @Is
    cmp #EXPR_LTE
    beq @Not
    ldy #0
    cmp #EXPR_EQ
    beq @Is
@Not:                       ; EXPR_NE falls through, with 0
    cpy tmp2
    beq @False
    bne @True
@Is:
    cpy tmp2
    bne @False
@True:
    lda #1
    bne @Free
@False:
    lda #0

@Free:
    pha
    ldx #0
    jsr freeObj             ; <operand-1>
    ldx #1
    jsr freeObj             ; <operand-2>
    pla
    ldx #0
    stx sreg
    stx sreg + 1
    jmp pusheax
.endproc

; This routine frees operand X (0 or 1) of a string comparison if it is a
; string object, a temporary nothing else holds.
.proc freeObj
    lda cmpKinds,x
    cmp #TYPE_STRING_OBJ
    bne @Done
    txa
    asl a
    tax
    lda cmpVals,x
    pha
    lda cmpVals + 1,x
    tax
    pla
    jmp heapFree
@Done:
    rts
.endproc

; This routine makes operand X (0 or 1) of a string comparison a pointer
; to its first character, in ptr1, and its length, in A:
;    String variable or object: the block after its length byte
;    String literal: its characters, up to the zero (at most 255)
;    Array of Char: the block after its 6-byte header (arrayLength)
;    Char: the value's own low byte in cmpVals, length 1
.proc strOperand
    ldy cmpKinds,x
    txa
    asl a
    tax                     ; The operand's offset in cmpVals
    lda cmpVals,x
    sta ptr1
    lda cmpVals + 1,x
    sta ptr1 + 1
    cpy #TYPE_STRING_VAR
    beq @Var
    cpy #TYPE_STRING_OBJ
    beq @Var
    cpy #TYPE_STRING_LITERAL
    beq @Lit
    cpy #TYPE_ARRAY
    beq @Arr

    ; A Char
    txa
    clc
    adc #<cmpVals
    sta ptr1
    lda #>cmpVals
    adc #0
    sta ptr1 + 1
    lda #1
    rts

@Var:
    ldy #0
    lda (ptr1),y            ; The length
    inc ptr1                ; Past the length byte
    bne :+
    inc ptr1 + 1
:   rts

@Lit:
    ldy #0
:   lda (ptr1),y
    beq :+
    iny
    bne :-
:   tya
    rts

@Arr:
    lda ptr1
    ldx ptr1 + 1
    jsr arrayLength         ; Leaves ptr1 at the block
    pha
    lda ptr1
    clc
    adc #6                  ; Past the header
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    pla
    rts
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
