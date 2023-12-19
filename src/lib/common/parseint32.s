.import intOp1, intOp2, readInt32
.importzp ptr1, intPtr, sreg

.export _parseInt32

; This routine parses a 132-bit integer from a string.
; The caller passes a pointer to a NULL-terminated string
; and the integer is returned in A/X/sreg.
; long parseInt32(char *buffer)
.proc _parseInt32
    sta ptr1
    stx ptr1 + 1

    ldy #0
L1:
    lda (ptr1),y
    sta (intPtr),y
    beq L2
    iny
    jmp L1
L2:
    jsr readInt32
    lda intOp2
    sta sreg
    lda intOp2 + 1
    sta sreg + 1
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc
