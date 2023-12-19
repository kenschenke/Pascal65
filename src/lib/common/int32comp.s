.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1, intOp2, intOp32
.endif

.export eqInt32, leInt32, ltInt32, geInt32, gtInt32

; Compare intOp1/intOp2 and intOp32 for equality.
; .A contains 1 if equal, 0 otherwise
.proc eqInt32
    ldx #3
L1:
    lda intOp1,x
    cmp intOp32,x
    bne L2
    dex
    bpl L1
    lda #1
    rts
L2:
    lda #0
    rts
.endproc

; Compare if intOp1/intOp2 less than or equal to intOp32.
; .A contains 1 if intOp1/intOp2 <= intOp32, 0 otherwise.
.proc leInt32
    jsr eqInt32
    bne L1
    jmp ltInt32
L1:
    lda #1
    rts
.endproc

; Compare if intOp1/intOp2 is less than intOp32
; .A contains 1 if intOp1/intOp2 < intOp32, 0 otherwise.
.proc ltInt32
    lda intOp1
    cmp intOp32
    lda intOp1 + 1
    sbc intOp32 + 1
    lda intOp2
    sbc intOp32 + 2
    lda intOp2 + 1
    sbc intOp32 + 3
    bvc L1
    eor #$80
L1:
    bpl L2
    lda #1
    rts
L2:
    lda #0
    rts
.endproc

; Compare if intOp1/intOp2 is greather than intOp32
; .A contains 1 if intOp1/intOp2 > intOp32, 0 otherwise.
.proc gtInt32
    jsr eqInt32
    bne L1
    jmp geInt32
L1:
    lda #0
    rts
.endproc

; Compare if intOp1/intOp2 is greater than or equal to intOp32.
; .A contains 1 if intOp1/intOp2 >= intOp32, 0 otherwise.
.proc geInt32
    lda intOp1
    cmp intOp32
    lda intOp1 + 1
    sbc intOp32 + 1
    lda intOp2
    sbc intOp32 + 2
    lda intOp2 + 1
    sbc intOp32 + 3
    bvc L1
    eor #$80
L1:
    bpl L2
    lda #0
    rts
L2:
    lda #1
    rts
.endproc

