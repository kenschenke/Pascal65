.include "runtime.inc"
.include "types.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp convertType

; end of exports
.byte $00, $00, $00

; imports

signExtend8To16: jmp $0000
signExtend8To32: jmp $0000
signExtend16To32: jmp $0000
writeUint8: jmp $0000
writeInt8: jmp $0000
writeUint16: jmp $0000
writeInt16: jmp $0000
_strToFloat: jmp $0000
writeInt32: jmp $0000
writeUint32: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Data Type Conversion Chart
;      (X means can convert, - means cannot)
; |------------------------------- To --------------------------------------|
; | From     | Byte | ShortInt | Word | Integer | Cardinal | LongInt | Real |
; |----------|------|----------|------|---------|----------|----------------|
; | Byte     |  X   |    -     |  X   |    X    |    X     |    X    |   X  |
; | ShortInt |  -   |    X     |  -   |    X    |    -     |    X    |   X  |
; | Word     |  -   |    -     |  X   |    -    |    X     |    X    |   X  |
; | Integer  |  -   |    -     |  -   |    X    |    -     |    X    |   X  |
; | Cardinal |  -   |    -     |  -   |    -    |    X     |    -    |   -  |
; | LongInt  |  -   |    -     |  -   |    -    |    -     |    X    |   -  |
; |-------------------------------------------------------------------------|

; Data Type Automatic Converions for Arithmetic
;       (- means cannot be automatically converted)
; |----------------------------------------------------------------------------------|
; |          | Byte     | ShortInt | Word     | Integer  | Cardinal | LongInt | Real |
; |----------|----------|----------|----------|----------|----------|----------------|
; | Byte     | Byte     | Integer  | Word     | Integer  | Cardinal | LongInt | Real |
; | ShortInt | Integer  | ShortInt | LongInt  | Integer  | LongInt  | LongInt | Real |
; | Word     | Word     | LongInt  | Word     | LongInt  | Cardinal | LongInt | Real |
; | Integer  | Integer  | Integer  | LongInt  | Integer  | LongInt  | LongInt | Real |
; | Cardinal | Cardinal | Cardinal | Cardinal | Cardinal | Cardinal |    -    | Real |
; | LongInt  | LongInt  | LongInt  | LongInt  | LongInt  |    -     | LongInt | Real |
; | Real     | Real     | Real     | Real     | Real     | Real     | Real    | Real |
; |----------------------------------------------------------------------------------|

; Converts the type in intOp1/intOp2
; Inputs:
;    A - current data type
;    X - new data type
.proc convertType
    stx tmp1
    cmp tmp1
    beq Done
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
    jmp Done

UINT8:  ; Byte
    jmp convertUINT8

SINT8:  ; ShortInt
    jmp convertSINT8

UINT16:
    jmp convertUINT16

SINT16:
    jmp convertSINT16

UINT32:
    jmp convertUINT32

SINT32:
    jmp convertSINT32

Done:
    rts
.endproc

.proc convertUINT8
    cpx #TYPE_SHORTINT
    beq Done
    cpx #TYPE_WORD
    beq @To16
    cpx #TYPE_INTEGER
    beq @To16
    cpx #TYPE_REAL
    beq @ToReal

    ; 8-bit to 32-bit
    lda #0
    sta intOp2
    sta intOp2 + 1
    ; Fall through

@To16:
    ; 8-bit to 16-bit
    lda #0
    sta intOp1 + 1
    jmp Done

@ToReal:
    ; Byte to Real
    lda #0
    jsr writeUint8
    lda intPtr
    ldx intPtr + 1
    jmp _strToFloat

Done:
    rts
.endproc

.proc convertSINT8
    cpx #TYPE_BYTE
    beq Done
    cpx #TYPE_WORD
    beq Done
    cpx #TYPE_INTEGER
    beq @To16
    cpx #TYPE_REAL
    beq @ToReal

    ; ShortInt to LongInt
    jmp signExtend8To32

    ; ShortInt to Integer
@To16:
    jmp signExtend8To16

@ToReal:
    ; ShortInt to Real
    lda #0
    jsr writeInt8
    lda intPtr
    ldx intPtr + 1
    jmp _strToFloat

Done:
    rts
.endproc

.proc convertUINT16
    cpx #TYPE_SHORTINT
    beq Done
    cpx #TYPE_BYTE
    beq Done
    cpx #TYPE_INTEGER
    beq Done
    cpx #TYPE_REAL
    beq @ToReal

    ; Cardinal and LongInt
    lda #0
    sta intOp2
    sta intOp2 + 1
    jmp Done

@ToReal:
    lda #0
    jsr writeUint16
    lda intPtr
    ldx intPtr + 1
    jmp _strToFloat

Done:
    rts
.endproc

.proc convertSINT16
    cpx #TYPE_BYTE
    beq Done
    cpx #TYPE_SHORTINT
    beq Done
    cpx #TYPE_WORD
    beq Done
    cpx #TYPE_INTEGER
    beq Done
    cpx #TYPE_CARDINAL
    beq Done
    cpx #TYPE_REAL
    beq @ToReal

    ; Long integer
    jmp signExtend16To32

@ToReal:
    lda #0
    jsr writeInt16
    lda intPtr
    ldx intPtr + 1
    jmp _strToFloat

Done:
    rts
.endproc

.proc convertUINT32
    cpx #TYPE_REAL
    beq @ToReal
    rts

@ToReal:
    lda #0
    jsr writeUint32
    lda intPtr
    ldx intPtr + 1
    jmp _strToFloat
.endproc

.proc convertSINT32
    cpx #TYPE_INTEGER
    beq @Int16
    cpx #TYPE_REAL
    beq @ToReal
    rts

@Int16:
    jmp signExtend16To32

@ToReal:
    lda #0
    jsr writeInt32
    lda intPtr
    ldx intPtr + 1
    jmp _strToFloat
.endproc

