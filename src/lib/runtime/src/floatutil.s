; Utility routines for floating point operations.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley


.include "float.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp ptr1, ptr2
.endif

.export ROTATL, ROTL, ROTR, ROTATR, ADDER, COMPLM, CLRMEM, MOVIND, MOVIN, CALCPTR

.bss

ADDR1: .res 1
ADDR2: .res 1
ADDR3: .res 1

.code

; Rotate a block of memory to the left, in increasing order.
; Input:
;    X: offset of memory address
;    Y: number of bytes to rotate
ROTATL:
    clc
ROTL:
    rol FPBASE,x
    dey
    bne MORRTL
    rts
MORRTL:
    inx
    jmp ROTL

; Rotate a block of memory to the right, in increasing order.
; Input:
;    X: offset of memory address
;    Y: number of bytes to rotate
ROTATR:
    clc
ROTR:
    ror FPBASE,x
    dey
    bne MORRTR
    rts
MORRTR:
    dex
    jmp ROTR

; Add two multi-byte numbers
;    FMPNT is FPBASE offset of source
;    TOPNT is FPBASE offset of destination
;    X register contains number of bytes to add
; output:
;    the sum is stored in the first number
.proc ADDER
    txa
    pha
    ldy FPBASE + FMPNT
    jsr CALCPTR
    sta ptr2
    stx ptr2 + 1
    ldy FPBASE + TOPNT
    jsr CALCPTR
    sta ptr1
    stx ptr1 + 1
    pla
    tax
    ldy #0
ADDR1:
    lda (ptr1),y
    adc (ptr2),y
    sta (ptr1),y
    iny
    dex
    bne ADDR1
    rts
.endproc

; Calculate the two's complement of a value
; Input:
;    X: offset of memory address
;    Y: number of bytes in value
.proc COMPLM
    sec
COMPL:
    lda #$ff
    eor FPBASE,x
    adc #0
    sta FPBASE,x
    inx
    dey
    bne COMPL
    rts
.endproc

; Clear a block of memory
; Input:
;    TOPNT is FPBASE offset of memory to clear
;    X: number of byte to clear
.proc CLRMEM
    txa
    pha
    ldy FPBASE + TOPNT
    jsr CALCPTR
    sta ptr1
    stx ptr1 + 1
    pla
    tax
    lda #0
    tay
CLRM1:
    sta (ptr1),y
    iny
    dex
    bne CLRM1
    rts
.endproc

; Copy a block of memory
;    FMPNT is FPBASE offset of source
;    TOPNT is FPBASE offset of destination
;    X register contains number of bytes to copy
MOVIND:
    txa
    pha
    ldy FPBASE + FMPNT
    jsr CALCPTR
    sta ptr1
    stx ptr1 + 1
    ldy FPBASE + TOPNT
    jsr CALCPTR
    sta ptr2
    stx ptr2 + 1
    pla
    tax
MOVIN:
    ldy #0
MOVIN1:
    lda (ptr1),y
    sta (ptr2),y
    iny
    dex
    bne MOVIN1
    rts

; Calculate a memory address from FPBASE.
;    Inputs:
;       Y: number of bytes added to FPBASE
;    Outputs:
;       A: low byte of address
;       X: high byte of address
.proc CALCPTR
    sty ADDR3
    lda #<FPBASE
    sta ADDR1
    lda #>FPBASE
    sta ADDR2
    clc
    lda ADDR1
    adc ADDR3
    pha
    lda ADDR2
    adc #0
    tax
    pla
    rts
.endproc
