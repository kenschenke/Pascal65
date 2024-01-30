; Routines to convert between signed 16-bit integers and floating point.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp floatToInt16
jmp copyFPACCtoFPOP
jmp swapFPACCandFPOP

; end of exports
.byte $00, $00, $00

; imports

readInt16: jmp $0000
FPOUT: jmp $0000
FPINP: jmp $0000
MOVIND: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

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

.proc copyFPACCtoFPOP
    lda #FPLSW          ; Origin is FPACC
    sta FPBASE + FMPNT
    lda #FOPLSW         ; Destination is FPOP
    sta FPBASE + TOPNT
    ldx #4              ; Copy 4 bytes
    jmp MOVIND
.endproc

.proc swapFPACCandFPOP
    ; Copy FPOP to the work area
    lda #FOPLSW
    sta FPBASE + FMPNT
    lda #WORK0
    sta FPBASE + TOPNT
    ldx #4
    jsr MOVIND
    ; Copy FPACC to FPOP
    jsr copyFPACCtoFPOP
    ; Copy the work area to FPACC
    lda #WORK0
    sta FPBASE + FMPNT
    lda #FPLSW
    sta FPBASE + TOPNT
    ldx #4
    jmp MOVIND
.endproc

; Returns a pointer to FPBUF in A/X
.proc getFPBUF
    lda #<FPBUF
    ldx #>FPBUF
    rts
.endproc
