; This routine is used by write and writeln to write a value.
; It expects the value to be at the top of the runtime stack
;
; Inputs:
;    A - data type
;    X - value width (for left padding)

.include "runtime.inc"
.include "types.inc"

.import popeax, popToIntOp1, popToIntOp1And2, writeBool, writeChar
.import writeUint8, writeInt8
.import writeUint16, writeInt16, writeUint32, writeInt32, printz

.export writeValue

.macro popWidth
    tay                 ; Save the value in Y
    pla                 ; Pop the field width off the CPU stack
    tax                 ; Transfer it to X
    tya                 ; Transfer the value back to A
.endmacro

.proc writeValue
    ; Save the width on the CPU stack
    tay                 ; Save the data type in Y
    txa                 ; Move the field width to A
    pha                 ; Push it onto the CPU stack
    tya                 ; Transfer data type back to A

    cmp #TYPE_BOOLEAN
    beq BOOL
    cmp #TYPE_CHARACTER
    beq CHAR
    cmp #TYPE_BYTE
    beq UINT8
    cmp #TYPE_SHORTINT
    beq SINT8
    cmp #TYPE_WORD
    beq UINT16
    cmp #TYPE_INTEGER
    beq SINT16
    cmp #TYPE_CARDINAL
    beq UINT32
    cmp #TYPE_LONGINT
    beq SINT32

BOOL:
    jsr popeax
    popWidth
    jmp writeBool

CHAR:
    jsr popeax
    popWidth
    jmp writeChar

UINT8:
    jsr popToIntOp1
    pla
    jsr writeUint8
    clc
    bcc writeIntBuf

SINT8:
    jsr popToIntOp1
    pla
    jsr writeInt8
    clc
    bcc writeIntBuf

UINT16:
    jsr popToIntOp1
    pla
    jsr writeUint16
    clc
    bcc writeIntBuf

SINT16:
    jsr popToIntOp1
    pla
    jsr writeInt16
    clc
    bcc writeIntBuf

UINT32:
    jsr popToIntOp1And2
    pla
    jsr writeUint32
    clc
    bcc writeIntBuf

SINT32:
    jsr popToIntOp1And2
    pla
    jsr writeInt32
    clc
    bcc writeIntBuf

writeIntBuf:
    lda intPtr
    ldx intPtr + 1
    jmp printz
.endproc

