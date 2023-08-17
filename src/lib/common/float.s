; Routines to convert between signed 16-bit integers and floating point.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp ptr1, ptr2, intPtr
.export FPBASE, FPBUF
.endif
.import readInt16, FPOUT, writeInt16, FPINP, MOVIND

.export floatToInt16, int16ToFloat, copyFPACCtoFPOP

.ifndef RUNTIME
.bss

FPBASE: .res 44
FPBUF: .res FPBUFSZ
.endif

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
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    cmp #'.'
    beq L2
    sta (intPtr),y
    iny
    jmp L1
L2:
    lda #0
    sta (intPtr),y
    jmp readInt16
.endproc

; Converts number in intOp1 to FPACC.
.proc int16ToFloat
    lda #0
    jsr writeInt16
    lda #<FPBUF
    sta ptr2
    lda #>FPBUF
    sta ptr2 + 1
    ldy #0
L1:
    lda (intPtr),y
    beq L2
    sta (ptr2),y
    iny
    jmp L1
L2:
    sta (ptr2),y
    jmp FPINP
.endproc

.proc copyFPACCtoFPOP
    lda #FPLSW          ; Origin is FPACC
    sta FPBASE + FMPNT
    lda #FOPLSW         ; Destination is FPOP
    sta FPBASE + TOPNT
    ldx #4              ; Copy 4 bytes
    jmp MOVIND
.endproc
