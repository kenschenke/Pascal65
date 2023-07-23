; Runtime Stack

.include "float.inc"

.import popeax, pusheax, incsp4, intOp1, intOp2, FPBASE
.importzp sreg, ptr1, tmp1, tmp2

.export rtStackCleanup, rtStackInit, popAddrStack, pushIntStack, calcStackOffset, storeIntStack
.export pushAddrStack, readIntStack, popToIntOp1, popToIntOp2, pushFromIntOp1, fpbase, pushRealStack
.export storeRealStack, popToReal, readRealStack, readByteStack, pushByteStack, storeByteStack

.zeropage

fpbase: .res 2

.code

; Calculate stack offset
; value offset in X, A is preserved
; address returned in ptr1
.proc calcStackOffset
    pha
    lda fpbase
    sta ptr1
    lda fpbase + 1
    sta ptr1 + 1
    ; Subtract 12 for the stack frame header
    sec
    lda ptr1
    sbc #12
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    ; Multiply offset by 4
    lda #0
    sta tmp2
    txa
    asl a
    rol tmp2
    asl a
    rol tmp2
    sta tmp1
    ; Subtract tmp1/tmp2 from ptr1
    sec
    lda ptr1
    sbc tmp1
    sta ptr1
    lda ptr1 + 1
    sbc tmp2
    sta ptr1 + 1
    ; Subtract 4 from offset (bottom of value on stack)
    sec
    lda ptr1
    sbc #4
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    pla
    rts
.endproc

; Clean up the stack frame header
.proc rtStackCleanup
    jsr incsp4
    jsr incsp4
    jsr incsp4
    rts
.endproc

; Initialize the runtime stack
.proc rtStackInit
    ; Initialize the program's stack frame at the bottom
    lda #0
    tax
    jsr pushIntStack    ; Function return value
    jsr pushIntStack    ; Static link
    jsr pushIntStack    ; Dynamic link
    rts
.endproc

.proc popAddrStack
    jsr popeax
    sta ptr1
    stx ptr1 + 1
    rts
.endproc

; Push the byte in A to the runtime stack
.proc pushByteStack
    ldx #0
    stx sreg
    stx sreg + 1
    jmp pusheax
.endproc

; Push the integer in A/X to the runtime stack
; A and X are not destroyed
.proc pushIntStack
    pha
    lda #0
    sta sreg
    sta sreg + 1
    pla
    jmp pusheax
.endproc

; Push the real in FPACC to the runtime stack
.proc pushRealStack
    ldx FPBASE + FPNSW
    lda FPBASE + FPMSW
    sta sreg
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPLSW
    jsr pusheax
    rts
.endproc

; Store the real at the top of the stack into the addr in ptr1
.proc storeRealStack
    jsr popeax
    ldy #3
    pha
    lda sreg + 1
    sta (ptr1),y
    dey
    lda sreg
    sta (ptr1),y
    dey
    txa
    sta (ptr1),y
    dey
    pla
    sta (ptr1),y
    rts
.endproc

; Pushes the address in ptr1 to the stack
.proc pushAddrStack
    lda #0
    sta sreg
    sta sreg + 1
    lda ptr1
    ldx ptr1 + 1
    jmp pusheax
.endproc

; Read the integer from the address in ptr1
; Returned in A/X
.proc readIntStack
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    rts
.endproc

; Read the byte from the address in ptr1
; Returned in A
.proc readByteStack
    ldy #0
    lda (ptr1),y
    rts
.endproc

; Store the integer at the top of the stack
; to the address in ptr1
.proc storeIntStack
    jsr popeax
    ldy #1
    pha
    txa
    sta (ptr1),y
    dey
    pla
    sta (ptr1),y
    rts
.endproc

; Store the byte at the top of the stack
; to the address in ptr1
.proc storeByteStack
    jsr popeax
    ldy #0
    sta (ptr1),y
    rts
.endproc

; Pops the integer at the top of the runtime stack
; and stores in intOp1
.proc popToIntOp1
     jsr popeax
     sta intOp1
     stx intOp1 + 1
     rts
.endproc

; Pops the integer at the top of the runtime stack
; and stores in intOp2
.proc popToIntOp2
     jsr popeax
     sta intOp2
     stx intOp2 + 1
     rts
.endproc

; Pushes intOp1 onto the runtime stack
.proc pushFromIntOp1
    lda #0
    sta sreg
    sta sreg + 1
    lda intOp1
    ldx intOp1 + 1
    jsr pusheax
    rts
.endproc

; Pops the real at the top of the runtime stack
; and stores in the FPACC
.proc popToReal
    jsr popeax
    sta FPBASE + FPLSW
    stx FPBASE + FPNSW
    lda sreg
    sta FPBASE + FPMSW
    lda sreg + 1
    sta FPBASE + FPACCE
    rts
.endproc

; Read the real from the address and leave in A/X/sreg
.proc readRealStack
    ldy #3
    lda (ptr1),y
    sta sreg + 1
    dey
    lda (ptr1),y
    sta sreg
    dey
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    rts
.endproc

