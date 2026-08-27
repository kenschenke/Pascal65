.include "icode.inc"

.export readInstruction, instruction

.import dumpMnemonic, readOperand, dumpDataSegment

.bss

instruction: .res 1

.code

; Read the instruction and its operand(s) if any.
; Instruction code passed in A.
.proc readInstruction
    sta instruction
    pha
    jsr dumpMnemonic

    pla
    cmp #IC_DAT
    bne :+
    jsr dumpDataSegment
    rts

:   bit #IC_MASK_TRINARY
    beq :+
    jsr readOperand
    jsr readOperand
    jsr readOperand
    rts

:   bit #IC_MASK_BINARY
    beq :+
    jsr readOperand
    jsr readOperand
    rts

:   bit #IC_MASK_UNARY
    beq :+
    jsr readOperand

:   rts
.endproc
