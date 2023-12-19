; Placeholder for integer operations

.ifdef RUNTIME
.include "runtime.inc"
.else
.export intOp1, intOp2, intOp32
.importzp tmp1, tmp2
.endif

.import signExtend8To32, signExtend8To16, signExtend16To32, swapInt32, swapInt16
.export setup16BitOperands, setup32BitOperands

.ifndef RUNTIME
.bss

; Operands for 16-bit integer operations
; These must always be adjacent in memory
intOp1: .res 2
intOp2: .res 2
intOp32: .res 4
.endif

.code

; This routine normalizes the integers in intOp1, intOp2, and intOp32
; to perform a 32-bit operation.  The operands are sign-extended to 32-bit.
; Size of the first operand in A and the second in X.
; 1 = 8-bit, 2 = 16-bit, 4 = 32-bit
.proc setup32BitOperands
    pha
    txa
    pha
    jsr swapInt32
    pla
    jsr normalizeOp32
    jsr swapInt32
    pla
    jmp normalizeOp32
.endproc

.proc normalizeOp32
    cmp #4
    beq L32
    cmp #2
    beq L16
    ; 8-bit
    jsr signExtend8To32
    rts
L16:
    ; 16-bit
    jmp signExtend16To32
L32:
    rts
.endproc

; This routine normalizes the integers in intOp1, intOp2, and intOp32
; to perform a 16-bit operation.  The operands are sign-extended to 16-bit.
; Size of the first operand in A and the second in X.
; 1 = 8-bit, 2 = 16-bit
.proc setup16BitOperands
    pha
    txa
    pha
    jsr swapInt16
    pla
    jsr normalizeOp16
    jsr swapInt16
    pla
    jmp normalizeOp16
.endproc

.proc normalizeOp16
    cmp #2
    beq L16
    ; 8-bit
    jmp signExtend8To16
L16:
    rts
.endproc
