;
; dumpDataSegment.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpHex routine

.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

MAX_COUNT = 20

.export dumpDataSegment

.import readOperand, dumpChar, dumpHexByte, operandValue

.ifndef __DEBUG__
.import dumpLabelXXXXX
.endif

.bss

; Segment length
seglen: .res 2
count: .res 1
dataType: .res 1
intBuf: .res 10
fieldPtr: .res 2            ; used when printing field type
firstField: .res 1          ; non zero for the field field in a record

.data

lblHeapOffset: .asciiz "   heap offset: "
lblLowBound: .asciiz "   low bound: "
lblHighBound: .asciiz "   high bound: "
lblElemSize: .asciiz "   elem size: "
lblElemType: .asciiz "   elem type: "
lblElemLabel: .asciiz "   elem label: "
lblLiterals: .asciiz "   literals: "
lblNumLiterals: .asciiz "   num literals: "
lblRecSize: .asciiz "   rec size: "
lblFields: .asciiz "   fields:"
lblOffset: .asciiz "      offset: "

; Record field types

lblRecord: .asciiz ", RECORD"
lblString: .asciiz ", STRING"
lblFile: .asciiz ", FILE"
lblArray: .asciiz ", ARRAY"

fieldTypes:
    .byte 0, 0                                      ; 0
    .byte 0, 0                                      ; 1
    .byte .lobyte(lblRecord), .hibyte(lblRecord)    ; 2
    .byte .lobyte(lblString), .hibyte(lblString)    ; 3
    .byte .lobyte(lblFile), .hibyte(lblFile)        ; 4
    .byte .lobyte(lblArray), .hibyte(lblArray)      ; 5

.code

.proc dumpDataSegment
    jsr readOperand         ; the data type
    lda operandValue
    sta dataType            ; keep the data type
    
    jsr readOperand         ; the label

    ; Read the operand data type
    jsr CHRIN
    ; Ignore it - it should be IC_IWU

    ; Read the segment length
    jsr CHRIN
    sta seglen
    jsr CHRIN
    sta seglen+1

    lda dataType
    cmp #ARRAYDECL_ARRAY
    bne :+
    jmp dumpArrayDecl
:   cmp #ARRAYDECL_RECORD
    bne :+
    jmp dumpRecordDecl
:   cmp #ARRAYDECL_STRING
    bne :+
    jmp dumpStringLiterals
:   cmp #ARRAYDECL_REAL
    bne L1
    jmp dumpStringLiterals

    ; Start a new line
L1: lda #13
    jsr dumpChar

    ; Indent
    lda #' '
    jsr dumpChar
    lda #' '
    jsr dumpChar
    lda #' '
    jsr dumpChar

    ; Write no more than MAX_COUNT bytes per screen line
    lda #0
    sta count

L2: lda seglen
    ora seglen+1
    beq L3

    lda count
    cmp #MAX_COUNT
    beq L1

    jsr CHRIN
    jsr dumpHexByte
    lda #' '
    jsr dumpChar

    lda seglen
    sec
    sbc #1
    sta seglen
    lda seglen+1
    sbc #0
    sta seglen+1

    inc count
    bra L2

L3: rts
.endproc

.proc dumpArrayDecl
    ; Skip a line
    lda #13
    jsr dumpChar

    ; Heap offset
    lda #0
    sta count
:   ldx count
    lda lblHeapOffset,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt16
    lda #13
    jsr dumpChar

    ; Low bound
    lda #0
    sta count
:   ldx count
    lda lblLowBound,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt16
    lda #13
    jsr dumpChar

    ; High bound
    lda #0
    sta count
:   ldx count
    lda lblHighBound,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt16
    lda #13
    jsr dumpChar

    ; Element size
    lda #0
    sta count
:   ldx count
    lda lblElemSize,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt16
    lda #13
    jsr dumpChar

    ; Element type
    lda #0
    sta count
:   ldx count
    lda lblElemType,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt8
    lda #13
    jsr dumpChar

    ; Element label
    lda #0
    sta count
:   ldx count
    lda lblElemLabel,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:
.ifdef __DEBUG__
    jsr dumpString
.else
    jsr CHRIN
    beq :+
    jsr dumpLabelXXXXX
:
.endif
    lda #13
    jsr dumpChar

    ; Literals
    lda #0
    sta count
:   ldx count
    lda lblLiterals,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:
.ifdef __DEBUG__
    jsr dumpString
.else
    jsr CHRIN
    beq :+
    jsr dumpLabelXXXXX
:
.endif
    lda #13
    jsr dumpChar

    ; Number of literals
    lda #0
    sta count
:   ldx count
    lda lblNumLiterals,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt16

    rts
.endproc

.proc dumpRecordDecl
    ; Skip a line
    lda #13
    jsr dumpChar

    lda #1
    sta firstField

    ; Heap offset
    lda #0
    sta count
:   ldx count
    lda lblHeapOffset,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt16
    lda #13
    jsr dumpChar

    ; Record size
    lda #0
    sta count
:   ldx count
    lda lblRecSize,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt16

    ; Loop through the record fields
L1: jsr CHRIN
    bne :+
    jmp DN

:   pha                 ; save the field type

    lda #13
    jsr dumpChar
    lda firstField
    beq L2

    ; Fields label
    lda #0
    sta count
:   ldx count
    lda lblFields,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   lda #13
    jsr dumpChar
    lda #0
    sta firstField

    ; Offset label
L2: lda #0
    sta count
:   ldx count
    lda lblOffset,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   jsr dumpInt16

    ; Field type
    pla                 ; field type
    asl a               ; multiply by two
    tax
    lda fieldTypes,x
    sta fieldPtr
    lda fieldTypes+1,x
    sta fieldPtr+1
    lda #0
    sta count
:   lda fieldPtr
    sta ptr1
    lda fieldPtr+1
    sta ptr1+1
    ldy count
    lda (ptr1),y
    beq :+
    jsr dumpChar
    inc count
    bne :-

    ; Declaration label
:   jsr CHRIN
    bne :+
    jmp L1
:   pha                 ; Save the first character of the label
    lda #','
    jsr dumpChar
    lda #' '
    jsr dumpChar
    pla
.ifdef __DEBUG__
:   jsr dumpChar
    jsr CHRIN
    bne :-
.else
    jsr CHRIN
    beq :+
    jsr dumpLabelXXXXX
:
.endif
    jmp L1

DN: rts
.endproc

.proc dumpStringLiterals
    ; Skip a line
    jsr indentString

    ; Keep reading until seglen is zero
L1: lda seglen
    ora seglen+1
    bne :+
    rts

    ; Decrement seglen
:   lda seglen
    sec
    sbc #1
    sta seglen
    lda seglen+1
    sbc #0
    sta seglen+1

    jsr CHRIN
    bne L2

    lda seglen
    ora seglen+1
    bne :+
    rts
:   jsr indentString
    bra L1

L2: jsr dumpChar
    bra L1
.endproc

.proc indentString
    lda #13
    jsr dumpChar
    lda #' '
    jsr dumpChar
    lda #' '
    jsr dumpChar
    lda #' '
    jsr dumpChar
    rts
.endproc

.proc dumpInt8
    jsr CHRIN
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #0
    sta count
:   ldx count
    lda intBuf,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   rts
.endproc

.proc dumpInt16
    jsr CHRIN
    sta intOp1
    jsr CHRIN
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #0
    sta count
:   ldx count
    lda intBuf,x
    beq :+
    jsr dumpChar
    inc count
    bne :-
:   rts
.endproc

.proc dumpString
L1: jsr CHRIN
    beq L2
    jsr dumpChar
    bra L1
L2: rts
.endproc
