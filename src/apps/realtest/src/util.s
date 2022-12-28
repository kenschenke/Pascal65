; Utility routines for floating point

.include "float.inc"

.import popax, FPBASE, pushax
.importzp ptr1, ptr2

.export ROTATL, ROTL, ROTR, ROTATR, ADDER, COMPLM, CLRMEM, MOVIND, CALCPTR

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
; adder(void *num1, void *num2, char bytes)
;    num1 points to first number
;    num2 points to second number
;    bytes is the number of bytes to add
; output:
;    the sum is stored in the first number
.proc ADDER
    pha
    jsr popax
    sta ptr2
    stx ptr2 + 1
    jsr popax
    sta ptr1
    stx ptr1 + 1
    pla
    tax
    clc
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
;    A: low byte of memory address
;    X: high byte of memory address
;    Y: number of byte to clear
.proc CLRMEM
    sta ptr1
    stx ptr1 + 1
    tya
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
; movind(void *dest, void *orig, char len)
.proc MOVIND
    pha
    jsr popax
    sta ptr1
    stx ptr1 + 1
    jsr popax
    sta ptr2
    stx ptr2 + 1
    pla
    tax
    ldy #0
MOVIN1:
    lda (ptr1),y
    sta (ptr2),y
    iny
    dex
    bne MOVIN1
    rts
.endproc

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
    sta ADDR1
    lda ADDR2
    adc #0
    tax
    lda ADDR1
    rts
.endproc
