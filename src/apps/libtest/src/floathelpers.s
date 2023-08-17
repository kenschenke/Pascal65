.include "float.inc"

.import popax, FPBASE, FPBUF, FPINP, FPOUT, floatEq, floatGt, floatGte, floatLt, floatLte, MOVIND, FPSUB, CALCPTR, FPADD, FPMULT, FPDIV
.importzp ptr1, ptr2

.export _floatStrTest, _saveOps

.bss

buf: .res 4

.code

; floatStrTest(const char *input, char *buffer, unsigned char precision)
.proc _floatStrTest
    sta FPBASE + PREC
    jsr popax
    sta buf
    stx buf + 1
    jsr popax
    sta ptr1
    stx ptr1 + 1
    lda #<FPBUF
    sta ptr2
    lda #>FPBUF
    sta ptr2 + 1
    ldy #0
L1:
    lda (ptr1),y
    sta (ptr2),y
    beq L2
    iny
    jmp L1
L2:
    jsr FPINP
    jsr FPOUT
    lda #<FPBUF
    sta ptr1
    lda #>FPBUF
    sta ptr1 + 1
    lda buf
    sta ptr2
    lda buf + 1
    sta ptr2 + 1
    ldy #0
L3:
    lda (ptr1),y
    sta (ptr2),y
    beq L4
    iny
    jmp L3
L4:
    rts
.endproc

; Copies from ptr1 to ptr2
.proc strcpy
    ldy #0
L1:
    lda (ptr1),y
    sta (ptr2),y
    beq L2
    iny
    jmp L1
L2:
    rts
.endproc

; Copies from ptr1 to ptr2
; Number of bytes to copy in X
.proc copybuf
    ldy #0
L1:
    lda (ptr1),y
    sta (ptr2),y
    iny
    dex
    bne L1
    rts
.endproc

; void saveOps(const char *Op1, const char *Op2)
.proc _saveOps
    sta ptr1        ; Store the Op2 pointer in ptr1
    stx ptr1 + 1
    jsr popax       ; Pull the Op1 pointer from the call stack
    pha             ; Push LB onto CPU stack
    txa             ; Copy X to A
    pha             ; Push HB onto CPU stack
    lda #<FPBUF     ; Copy FPBUF pointer to ptr2
    sta ptr2
    lda #>FPBUF
    sta ptr2 + 1
    jsr strcpy      ; Copy Op2 to FPBUF
    jsr FPINP       ; Parse FPBUF into FPACC
    ldy #FPLSW      ; Calculate pointer to FPACC
    jsr CALCPTR
    sta ptr1        ; Store FPACC pointer in ptr1
    stx ptr1 + 1
    lda #<buf       ; Store buf pointer in ptr2
    sta ptr2
    lda #>buf
    sta ptr2 + 1
    ldx #4          ; Copy FPACC to buf
    jsr copybuf
    pla             ; Pull Op1 HB from CPU stack
    sta ptr1 + 1
    pla             ; Pull Op1 LB from CPU stack
    sta ptr1
    lda #<FPBUF     ; Store FPBUF pointer in ptr2
    sta ptr2
    lda #>FPBUF
    sta ptr2 + 1
    jsr strcpy      ; Copy Op1 to FPBUF
    jsr FPINP       ; Parse Op1 into FPACC
    lda #<buf       ; Store buf pointer in ptr1
    sta ptr1
    lda #>buf
    sta ptr1 + 1
    ldy #FOPLSW     ; Calculate pointer to FPOP
    jsr CALCPTR
    sta ptr2        ; Store FPOP pointer in ptr2
    stx ptr2 + 1
    ldx #4
    jmp copybuf     ; Copy buf to FPOP
.endproc

.proc _floatEq
    jsr floatEq
    ldx #0
    rts
.endproc

.proc _floatGt
    jsr floatGt
    ldx #0
    rts
.endproc

.proc _floatGte
    jsr floatGte
    ldx #0
    rts
.endproc

.proc _floatLt
    jsr floatLt
    ldx #0
    rts
.endproc

.proc _floatLte
    jsr floatLte
    ldx #0
    rts
.endproc

; void floatAdd(const char *result)
.proc _floatAdd
    pha
    txa
    pha
    jsr FPADD
    lda #$02
    sta FPBASE + PREC
    jsr FPOUT
    lda #<FPBUF
    sta ptr1
    lda #>FPBUF
    sta ptr1 + 1
    pla
    sta ptr2 + 1
    pla
    sta ptr2
    jmp strcpy
.endproc

; void floatDiv(const char *result)
.proc _floatDiv
    pha
    txa
    pha
    jsr FPDIV
    lda #$02
    sta FPBASE + PREC
    jsr FPOUT
    lda #<FPBUF
    sta ptr1
    lda #>FPBUF
    sta ptr1 + 1
    pla
    sta ptr2 + 1
    pla
    sta ptr2
    jmp strcpy
.endproc

; void floatMult(const char *result)
.proc _floatMult
    pha
    txa
    pha
    jsr FPMULT
    lda #$02
    sta FPBASE + PREC
    jsr FPOUT
    lda #<FPBUF
    sta ptr1
    lda #>FPBUF
    sta ptr1 + 1
    pla
    sta ptr2 + 1
    pla
    sta ptr2
    jmp strcpy
.endproc

; void floatSub(const char *result)
.proc _floatSub
    pha
    txa
    pha
    jsr FPSUB
    lda #$02
    sta FPBASE + PREC
    jsr FPOUT
    lda #<FPBUF
    sta ptr1
    lda #>FPBUF
    sta ptr1 + 1
    pla
    sta ptr2 + 1
    pla
    sta ptr2
    jmp strcpy
.endproc
