; This routine negates the number in A/X/sreg

; The data type in passed in Y

.include "runtime.inc"
.include "types.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp negate

; end of exports
.byte $00, $00, $00

; imports

floatNeg: jmp $0000
invertInt8: jmp $0000
invertInt16: jmp $0000
invertInt32: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc negate
    cpy #TYPE_REAL
    beq @Real

    sta intOp1
    stx intOp1 + 1
    lda sreg
    sta intOp2
    lda sreg + 1
    sta intOp2 + 1

    cpy #TYPE_SHORTINT
    beq @Short
    cpy #TYPE_INTEGER
    beq @Int
    cpy #TYPE_LONGINT
    beq @Long
    rts

@Short:
    jsr invertInt8
    jmp @Reload

@Int:
    jsr invertInt16
    jmp @Reload

@Long:
    jsr invertInt32
    ; Fall through

@Reload:
    lda intOp2
    sta sreg
    lda intOp2 + 1
    sta sreg + 1
    lda intOp1
    ldx intOp1 + 1
    rts

@Real:
    jmp floatNeg
.endproc
