; This routine is used by write and writeln to write a value.
; It expects the value to be at the top of the runtime stack
;
; Inputs:
;    A - data type
;    X - value width (for left padding)

.include "runtime.inc"
.include "types.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp writeValue

; end of exports
.byte $00, $00, $00

; imports

popeax: jmp $0000
popToIntOp1: jmp $0000
popToIntOp1And2: jmp $0000
writeBool: jmp $0000
writeChar: jmp $0000
writeUint8: jmp $0000
writeInt8: jmp $0000
writeUint16: jmp $0000
writeInt16: jmp $0000
writeUint32: jmp $0000
writeInt32: jmp $0000
printz: jmp $0000
writeString: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

width: .res 1

.proc writeValue
    stx width           ; save width

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
    cmp #TYPE_STRING_VAR
    beq STR
    cmp #TYPE_STRING_OBJ
    beq STR

BOOL:
    jsr popeax
    ldx width
    jmp writeBool

CHAR:
    jsr popeax
    ldx width
    jmp writeChar

STR:
    jsr popeax
    ldy width
    jmp writeString

UINT8:
    jsr popToIntOp1
    lda width
    jsr writeUint8
    clc
    bcc writeIntBuf

SINT8:
    jsr popToIntOp1
    lda width
    jsr writeInt8
    clc
    bcc writeIntBuf

UINT16:
    jsr popToIntOp1
    lda width
    jsr writeUint16
    clc
    bcc writeIntBuf

SINT16:
    jsr popToIntOp1
    lda width
    jsr writeInt16
    clc
    bcc writeIntBuf

UINT32:
    jsr popToIntOp1And2
    lda width
    jsr writeUint32
    clc
    bcc writeIntBuf

SINT32:
    jsr popToIntOp1And2
    lda width
    jsr writeInt32
    clc
    bcc writeIntBuf

writeIntBuf:
    lda intPtr
    ldx intPtr + 1
    jmp printz
.endproc

