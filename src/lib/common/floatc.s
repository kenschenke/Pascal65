; Routines to support floating point in C

.include "float.inc"

.import FPBASE, popa, popax, popeax, FPADD, FPSUB, FPMULT, FPDIV, FPOUT, leftpad, printz, FPBUF, FPINP
.import floatEq, floatGt, floatGte, floatLt, floatLte, intOp1, floatToInt16, int16ToFloat
.importzp sreg, ptr1, ptr2

.export _floatAdd, _floatSub, _floatMult, _floatDiv, _floatPrint, _strToFloat, _floatToStr
.export _floatEq, _floatGt, _floatGte, _floatLt, _floatLte, _floatToInt16, _int16ToFloat

; FLOAT floatAdd(FLOAT num1, FLOAT num2)
.proc _floatAdd
    jsr storeTwo
    jsr FPADD
    jmp loadFPACC
.endproc

; FLOAT floatSub(FLOAT num1, FLOAT num2)
.proc _floatSub
    jsr storeTwo
    jsr FPSUB
    jmp loadFPACC
.endproc

; FLOAT floatMult(FLOAT num1, FLOAT num2)
.proc _floatMult
    jsr storeTwo
    jsr FPMULT
    jmp loadFPACC
.endproc

; FLOAT floatDiv(FLOAT num1, FLOAT num2)
.proc _floatDiv
    jsr storeTwo
    jsr FPDIV
    jmp loadFPACC
.endproc

; char floatEq(FLOAT num1, FLOAT num2)
.proc _floatEq
    jsr storeTwo
    jsr floatEq
    ldx #0
    rts
.endproc

; char floatGt(FLOAT num1, FLOAT num2)
.proc _floatGt
    jsr storeTwo
    jsr floatGt
    ldx #0
    rts
.endproc

; char floatGte(FLOAT num1, FLOAT num2)
.proc _floatGte
    jsr storeTwo
    jsr floatGte
    ldx #0
    rts
.endproc

; char floatLt(FLOAT num1, FLOAT num2)
.proc _floatLt
    jsr storeTwo
    jsr floatLt
    ldx #0
    rts
.endproc

; char floatLte(FLOAT num1, FLOAT num2)
.proc _floatLte
    jsr storeTwo
    jsr floatLte
    ldx #0
    rts
.endproc

; void floatPrint(FLOAT num, char precision, char width)
.proc _floatPrint
    pha
    jsr popa
    sta FPBASE + PREC
    jsr popeax
    jsr storeFPACC
    jsr FPOUT
    tax
    pla
    jsr leftpad
    lda #<FPBUF
    ldx #>FPBUF
    jmp printz
.endproc

; FLOAT strToFloat(const char *str)
.proc _strToFloat
    sta ptr1
    stx ptr1 + 1
    ldx #0
    ldy #0
L1:
    lda (ptr1),y
    sta FPBUF,x
    beq L2
    inx
    iny
    jmp L1
L2:
    jsr FPINP
    jmp loadFPACC
.endproc

; void floatToStr(FLOAT num, char *buffer, char precision)
.proc _floatToStr
    sta FPBASE + PREC
    jsr popax
    pha
    txa
    pha
    jsr popeax
    jsr storeFPACC
    jsr FPOUT
    pla
    sta ptr2 + 1
    pla
    sta ptr2
    lda #<FPBUF
    sta ptr1
    lda #>FPBUF
    sta ptr1 + 1
    ldx #0
    ldy #0
L1:
    lda (ptr1),y
    sta (ptr2),y
    beq L2
    inx
    inx
    jmp L1
L2:
    rts
.endproc

; int floatToInt16(FLOAT num)
.proc _floatToInt16
    jsr storeFPACC
    jsr floatToInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

; FLOAT int16ToFloat(int num)
.proc _int16ToFloat
    sta intOp1
    stx intOp1 + 1
    jsr int16ToFloat
    jmp loadFPACC
.endproc

; Store two FLOAT parameters in FPACC and FPOP
.proc storeTwo
    jsr storeFPOP
    jsr popeax
    jsr storeFPACC
    rts
.endproc

; Load a float from FPACC into the registers for return to C
.proc loadFPACC
    lda FPBASE + FPMSW
    sta sreg
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPLSW
    ldx FPBASE + FPNSW
    rts
.endproc

; Store a float from the C parameter stack in FPACC
.proc storeFPACC
    sta FPBASE + FPLSW
    stx FPBASE + FPNSW
    lda sreg
    sta FPBASE + FPMSW
    lda sreg + 1
    sta FPBASE + FPACCE
    lda #0
    sta FPBASE + FPLSWE
    rts
.endproc

; Store a float from the C parameter stack in FPOP
.proc storeFPOP
    sta FPBASE + FOPLSW
    stx FPBASE + FOPNSW
    lda sreg
    sta FPBASE + FOPMSW
    lda sreg + 1
    sta FPBASE + FOPEXP
    lda #0
    sta FPBASE + FOLSWE
    rts
.endproc
