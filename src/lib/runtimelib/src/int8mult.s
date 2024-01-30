.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp multInt8

; end of exports
.byte $00, $00, $00

; imports

absInt8: jmp $0000
invertInt8: jmp $0000
ltInt8: jmp $0000
swapInt8: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.macro reloadIntOps
    lda tmp1
    sta intOp1
    lda tmp3
    sta intOp2
.endmacro

; tmp2 - op2 is negative
; tmp3 - LB result
;
; This routine multiplies two signed 8-bit integers stored in intOp1 and intOp2.
; The result is stored in intOp1.  It does not check for overflow.
;
; It orders the operands so the larger of the absolute values is in intOp1.
;
; Then it looks at intOp2 and, if negative, changes it to the absolute value.
;
; Then it loops and adds intOp1 to itself until intOp2 is zero.
;
; Finally, if intOp2 was negative, it inverts the sign on the result.

.proc multInt8
    ; Store intOp1 in tmp1
    lda intOp1
    sta tmp1
    ; Store intOp2 in tmp3
    lda intOp2
    sta tmp3
    ; If intOp1 is zero result is zero
    lda intOp1
    bne L0
    beq Done
L0:
    ; If intOp2 is zero, store zero in result
    lda intOp2
    bne L1
    lda #0
    sta intOp1
    beq Done
    ; Take the absolute value of intOp1
L1:
    jsr absInt8
    ; Store it in intOp2
    lda intOp1
    sta intOp2
    ; Take the absolute value of intOp2
    lda tmp3
    sta intOp1
    jsr absInt8
    ; Is intOp1 < intOp2
    jsr ltInt8
    beq L2         ; swap them
    reloadIntOps
    clc
    bcc L3
L2:
    ; Swap intOp1 and intOp2
    reloadIntOps
    jsr swapInt8
L3:
    ; Is intOp2 negative?
    lda #0
    sta tmp2
    lda intOp2
    and #$80
    beq L4              ; not negative
    lda #1
    sta tmp2
    ; Invert intOp2
    jsr swapInt8
    jsr invertInt8
    jsr swapInt8

L4:
    lda #0
    sta tmp3

    ; Loop until intOp2 is zero, adding intOp1 to result
L5:
    clc
    lda tmp3
    adc intOp1
    sta tmp3
    ; Subtract one from intOp2
    sec
    lda intOp2
    sbc #1
    sta intOp2
    ; Is intOp2 zero?
    lda intOp2
    bne L5

    ; Store the result in intOp1
    lda tmp3
    sta intOp1

    ; Do we need to negatate the result?
    lda tmp2
    beq Done
    jsr invertInt8     ; Yes

Done:
    rts
.endproc
