;
; math.s
; Ken Schenke (kenschenke@gmail.com)
;
; Math helpers
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

; Routines to assist in math operations

.include "float.inc"
.include "types.inc"
.include "runtime.inc"

.export prepOperands8, prepOperands16, prepOperands32, prepOperandsReal

.import swapFPACCandFPOP, copyFPACCtoFPOP, convertType
.import pusheax, swapInt8, swapInt16, swapInt32

.bss

oper1Type: .res 1
oper2Type: .res 1
resultType: .res 1

.code

.proc prepOperands8
    sta oper1Type
    stx oper2Type
    sty resultType
    jsr rtPopToIntOp1
    lda oper2Type
    ldx resultType
    jsr convertType
    jsr swapInt8
    jsr rtPopToIntOp1
    lda oper1Type
    ldx resultType
    jsr convertType
    rts
.endproc

.proc prepOperands16
    sta oper1Type
    stx oper2Type
    sty resultType
    jsr rtPopToIntOp1
    lda oper2Type
    ldx resultType
    jsr convertType
    jsr swapInt16
    jsr rtPopToIntOp1
    lda oper1Type
    ldx resultType
    jsr convertType
    rts
.endproc

.proc prepOperands32
    sta oper1Type
    stx oper2Type
    sty resultType
    jsr rtPopToIntOp1And2
    lda oper2Type
    ldx resultType
    jsr convertType
    jsr swapInt32
    jsr rtPopToIntOp1And2
    lda oper1Type
    ldx resultType
    jsr convertType
    rts
.endproc

.proc prepOperandsReal
    sta oper1Type
    stx oper2Type
    sty resultType
    lda oper2Type           ; Look at the second operand's type
    cmp #TYPE_REAL          ; Is it real?
    beq L1                  ; If so, skip converting
    jsr rtPopToIntOp1And2     ; Pop the top value off the stack
    lda oper2Type
    ldx resultType
    jsr convertType         ; Convert it to real
    clc
    bcc L2
L1:
    jsr rtPopEax            ; Pop <operand-2> off the stack
                            ; It didn't need to be converted
L2:
    ; <operand-2> in A/X/sreg needs to be saved to the CPU stack
    pha
    txa
    pha
    lda sreg
    pha
    lda sreg + 1
    pha
    lda oper1Type           ; Look at the first operand's type
    cmp #TYPE_REAL          ; Is it real?
    bne L3                  ; If not, skip to converting it to real
    jsr rtPopToReal         ; Pop <operand-1> off the stack
    clc
    bcc L4                  ; Skip over converting it
L3:
    jsr rtPopToIntOp1And2     ; Pop <operand-1> off the stack
    lda oper1Type
    ldx resultType
    jsr convertType         ; Convert it to real
L4:
    ; <operand-1> is in FPACC.  Copy it to FPOP
    jsr copyFPACCtoFPOP
    ; The <operand-2> is still on the CPU stack.  Copy it back
    ; to A/X/sreg and put it in FPACC.
    pla
    sta FPBASE + FPACCE
    pla
    sta FPBASE + FPMSW
    pla
    sta FPBASE + FPNSW
    pla
    sta FPBASE + FPLSW
    jmp swapFPACCandFPOP
.endproc

