; Routines to convert between signed 16-bit integers and floating point.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"

.import readInt16, intBuf, FPOUT, writeInt16, FPINP
.importzp ptr1, ptr2

.export FPBASE, FPBUF, floatToInt16, int16ToFloat

.bss

FPBASE: .res 44
FPBUF: .res FPBUFSZ

.code

; Converts number in FPACC to signed 16-bit integer.
; Integer is stored in intOp1
.proc floatToInt16
    lda #$01            ; Load A with 1
    sta FPBASE + PREC   ; Set output precision to 1
    jsr FPOUT           ; Convert to string
    lda #<FPBUF
    sta ptr1
    lda #>FPBUF
    sta ptr1 + 1
    lda #<intBuf
    sta ptr2
    lda #>intBuf
    sta ptr2 + 1
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    cmp #'.'
    beq L2
    sta (ptr2),y
    iny
    jmp L1
L2:
    lda #0
    sta (ptr2),y
    jmp readInt16
.endproc

; Converts number in intOp1 to FPACC.
.proc int16ToFloat
    lda #0
    jsr writeInt16
    lda #<intBuf
    sta ptr1
    lda #>intBuf
    sta ptr1 + 1
    lda #<FPBUF
    sta ptr2
    lda #>FPBUF
    sta ptr2 + 1
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    sta (ptr2),y
    iny
    jmp L1
L2:
    sta (ptr2),y
    jmp FPINP
.endproc
