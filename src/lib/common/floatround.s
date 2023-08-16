; Routine to round a floating point number to a given precision.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"
.ifdef RUNTIME
.include "runtime.inc"
.else
.import FPBASE
.endif

.import MOVIND, FPADD, FPSUB, FPMULT, COMPLM

.export PRECRD

; This routine rounds FPACC per the caller's precision.
; It does this by calculating 0.51 / 10^precision then
; adding (for positive) or subtracting (for negative)
; to FPACC.
.proc PRECRD
    lda FPBASE + PREC   ; Load precision in A
    pha                 ; Store it on the stack
    lda #FPLSW          ; Pointer to FPACC LS byte
    sta FPBASE + FMPNT  ; Store in FMPNT
    lda #TPLSW          ; Pointer to temporary storage LS byte
    sta FPBASE + TOPNT  ; Store in TOPNT
    ldx #$04            ; Number of bytes to move
    jsr MOVIND          ; move FPACC to temporary storage
    lda #0              ; Store 0.51 in FPACC
    sta FPBASE + FPLSWE
    sta FPBASE + FPACCE
    lda #$af
    sta FPBASE + FPLSW
    lda #$47
    sta FPBASE + FPNSW
    lda #$41
    sta FPBASE + FPMSW
L1:
    lda FPBASE + PREC
    beq L2
    lda #0              ; Store 0.1 in FPOP
    sta FPBASE + FOLSWE
    lda #$64
    sta FPBASE + FOPLSW
    lda #$66
    sta FPBASE + FOPNSW
    sta FPBASE + FOPMSW
    lda #$fd
    sta FPBASE + FOPEXP
    jsr FPMULT          ; Multiply FPACC by 0.1
    dec FPBASE + PREC   ; Decrement precision
    jmp L1              ; Go back for another
L2:
    pla                 ; Pull precision back off stack
    sta FPBASE + PREC   ; Put it back in PREC
    lda #FPLSW          ; Pointer to FPACC LS byte
    sta FPBASE + FMPNT  ; Store in FMPNT
    lda #FOPLSW         ; Poiinter to FPOP LS byte
    sta FPBASE + TOPNT  ; Store in TOPNT
    ldx #$04            ; Move four bytes
    jsr MOVIND          ; Move FPACC to FPOP
    lda #TPLSW          ; Pointer to temporary storage
    sta FPBASE + FMPNT  ; Store in FMPNT
    lda #FPLSW          ; Pointer to FPACC LS byte
    sta FPBASE + TOPNT  ; Store in TOPNT
    ldx #$04            ; Move four bytes
    jsr MOVIND          ; Move temporary storage to FPACC
    lda FPBASE + FPMSW  ; Load FPACC MS byte
    bmi L3              ; If FPACC is negative, FPOP needs to be as well
    jmp FPADD           ; Add FPOP to FPACC
L3:
    ldx #FOPLSW         ; Negate (two's complement) FPOP
    ldy #$03
    jsr COMPLM
    jmp FPADD           ; Add FPOP to FPACC
.endproc
