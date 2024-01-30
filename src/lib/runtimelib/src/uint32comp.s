.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp geUint32
jmp gtUint32
jmp leUint32
jmp ltUint32

; end of exports
.byte $00, $00, $00

; imports

eqInt32: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Compare if intOp1/intOp2 is greater than or equal to intOp32
; .A contains 1 if intOp1/intOp2 >= intOp32, 0 otherwise
.proc geUint32
    ; Compare the high bytes first
    lda intOp2 + 1
    cmp intOp32 + 3
    bcc L1
    bne L2

    ;Compare the next most-significant bytes
    lda intOp2
    cmp intOp32 + 2
    bcc L1
    bne L2

    ;Compare the next most-significant bytes
    lda intOp1 + 1
    cmp intOp32 + 1
    bcc L1
    bne L2
    
    ; Compare the low bytes
    lda intOp1
    cmp intOp32
    bcs L2

L1:
    lda #0
    rts

L2:
    lda #1
    rts
.endproc

; Compare if intOp1/intOp2 is greater than intOp32
; .A contains 1 if intOp1/intOp2 > intOp32, 0 otherwise
.proc gtUint32
    jsr eqInt32
    bne L1
    jmp geUint32

L1:
    lda #0
    rts
.endproc

; Compare if intOp1/intOp2 is less than or equal to intOp32
; .A contains 1 if intOp1/intOp2 <= intOp32, 0 otherwise.
.proc leUint32
    jsr eqInt32
    bne L1
    jmp ltUint32

L1:
    lda #1
    rts
.endproc

; Compare if intOp1/intOp2 is less than intOp32
; .A contains 1 if intOp1/intOp2 < intOp32, 0 otherwise.
.proc ltUint32
    ; Compare the high bytes first
    lda intOp2 + 1
    cmp intOp32 + 3
    bcc L2
    bne L1

    ; Compare the next most-significant bytes
    lda intOp2
    cmp intOp32 + 2
    bcc L2
    bne L1

    ; Compare the next most-significant bytes
    lda intOp1 + 1
    cmp intOp32 + 1
    bcc L2
    bne L1

    ; Compare the lower bytes
    lda intOp1
    cmp intOp32
    bcc L2

L1:
    lda #0
    rts

L2:
    lda #1
    rts
.endproc
