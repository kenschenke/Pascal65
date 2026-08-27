;
; dataSegment.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; data segment code

.include "icode.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export initDataSegment, freeDataSegment, saveDataSegment, writeDataSegment

.import strbuf, operand1, incCodeOffset

.bss

; Membuf
dataSegment: .res 4
buffer: .res 8
segmentMemBuf: .res 4
segmentType: .res 1
segmentLabel: .res 20

.code

.proc initDataSegment
    lda #0
    tax
    tay
    taz
    stq dataSegment
    rts
.endproc

.proc freeDataSegment
    ldq dataSegment
    jsr isQZero
    bne :+
    rts

    ; Rewind the membuf
:   ldq dataSegment
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the memory buffer
L1: ldq dataSegment
    jsr isMemBufAtEnd
    bne :+
    ldq dataSegment
    jsr freeMemBuf
    rts

    ; Read the segment data type
:   ldq dataSegment
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf

    ; Read the segment label
L2: ldq dataSegment
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buffer
    bne L2

    ; Read the data segment's contents membuf
    ldq dataSegment
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #4
    ldx #0
    jsr readFromMemBuf
    ldq buffer
    jsr freeMemBuf
    bra L1
.endproc

; The membuf containing the data segment is passed in Q.
; The label for the data segment is in strbuf and the
; data type is in operand1.
.proc saveDataSegment
    jsr pushQ

    ldq dataSegment
    jsr isQZero
    bne :+
    jsr allocMemBuf
    stq dataSegment

    ; Write the data segment type (operand1)
:   ldq dataSegment
    stq ptr1
    lda #<operand1
    clc
    adc #1
    sta ptr2
    lda #>operand1
    adc #0
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf

    ; Write the data segment label (null-terminated)
    ldq dataSegment
    stq ptr1
    lda #<strbuf
    sta ptr2
    lda #>strbuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldx #0
:   lda strbuf,x
    beq :+
    inx
    bne :-
:   inx
    txa
    ldx #0
    jsr writeToMemBuf

    ; Write the data segment contents (a membuf)
    jsr popQ
    stq buffer
    ldq dataSegment
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #4
    ldx #0
    jsr writeToMemBuf

    rts
.endproc

; This routine writes the data segment to the object file. Data segments
; are stored in a memory buffer by calls to saveDataSegment. This routine
; walks through those data segments and saves them out. If the data is
; for an array or record, the data is modified to convert labels into
; actual addresses. All other segments are written unmodified.
.proc writeDataSegment
    ldq dataSegment
    jsr isQZero
    bne :+
    rts

:   ldq dataSegment
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the data segments
L1: ldq dataSegment
    jsr isMemBufAtEnd
    bne L2
    rts

    ; Read the data type
L2: ldq dataSegment
    stq ptr1
    lda #<segmentType
    sta ptr2
    lda #>segmentType
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf

    ; Read the segment label
    lda #0
    sta buffer+1            ; use buffer+1 as an index into segmentLabel
L3: ldq dataSegment
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buffer
    beq L4
    ldx buffer+1
    sta segmentLabel,x
    inc buffer+1
    bra L3

    ; Null-terminate the label
L4: lda #0
    ldx buffer+1
    sta segmentLabel,x

    ; Read the membuf for the segment
    ldq dataSegment
    stq ptr1
    lda #<segmentMemBuf
    sta ptr2
    lda #>segmentMemBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #4
    ldx #0
    jsr readFromMemBuf

    ; Rewind the segment membuf
    ldq segmentMemBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Record the location of this data segment with its label.
    lda #<segmentLabel
    ldx #>segmentLabel
    jsr linkAddressSet

    ; Is the segment type an array?
    lda segmentType
    cmp #ARRAYDECL_ARRAY
    bne :+
    jsr writeArraySegment
    jmp L1
    ; Is the segment type a record?
:   cmp #ARRAYDECL_RECORD
    bne :+
    jsr writeRecordSegment
    jmp L1
    ; Just copy all other segment types without modification
:   jsr copySegmentData
    jmp L1
.endproc

.proc writeArraySegment
    ldx #1
    jsr CHKOUT

    lda #8
    jsr readSegmentBytes

    ldx #0
:   lda buffer,x
    jsr CHROUT
    inx
    cpx #8
    bne :-
    lda #8
    jsr incCodeOffset

    ; Array element type
    lda #1
    jsr readSegmentBytes
    lda buffer
    sta segmentType

    ; Element declaration block
    jsr readSegmentLabel
    lda segmentLabel
    beq :+
    lda #<segmentLabel
    ldx #>segmentLabel
    ldy #LINKADDR_BOTH
    ldz #4
    jsr linkAddressLookup

    ; Literals
:   jsr readSegmentLabel
    lda segmentLabel
    beq :+
    lda #<segmentLabel
    ldx #>segmentLabel
    ldy #LINKADDR_BOTH
    ldz #0
    jsr linkAddressLookup

    ; Write literals pointer
:   lda #0
    jsr CHROUT
    jsr CHROUT
    lda #2
    jsr incCodeOffset

    ; Number of literals
    lda #2
    jsr readSegmentBytes
    lda buffer
    jsr CHROUT
    lda buffer+1
    jsr CHROUT
    lda #2
    jsr incCodeOffset

    ; Element declaration block
    lda #0
    jsr CHROUT
    jsr CHROUT
    lda #2
    jsr incCodeOffset

    ; Element type
    lda segmentType
    jsr CHROUT
    lda #1
    jsr incCodeOffset

    rts
.endproc

.proc writeRecordSegment
    ldx #1
    jsr CHKOUT

    ; Record header
    lda #4
    jsr readSegmentBytes

    ldx #0
:   lda buffer,x
    jsr CHROUT
    inx
    cpx #4
    bne :-
    lda #4
    jsr incCodeOffset

    ; Loop through record fields
L1: lda #1
    jsr readSegmentBytes
    lda buffer
    beq DN

    jsr CHROUT
    lda #1
    jsr incCodeOffset

    ; Offset
    lda #2
    jsr readSegmentBytes

    ; Field declaration pointer
    lda #0
    jsr CHROUT
    jsr CHROUT

    ; Offset
    lda buffer
    jsr CHROUT
    lda buffer+1
    jsr CHROUT

    ; Declaration label
    jsr readSegmentLabel
    lda segmentLabel
    beq L2
    lda #<segmentLabel
    ldx #>segmentLabel
    ldy #LINKADDR_BOTH
    ldz #0
    jsr linkAddressLookup

L2: lda #4
    jsr incCodeOffset
    bra L1

DN: lda #0
    jsr CHROUT
    lda #1
    jsr incCodeOffset
    rts
.endproc

.proc copySegmentData
    ldq segmentMemBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the segment's membuf, copying the data to the object file.
L1: ldq segmentMemBuf
    jsr isMemBufAtEnd
    bne L2
    rts

    ; Read a byte from the membuf
L2: ldq segmentMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf

    ; Write the byte to the object file
    ldx #1
    jsr CHKOUT
    lda buffer
    jsr CHROUT

    lda #1
    jsr incCodeOffset

    bra L1
.endproc

; Bytes to read passed in A.
; Bytes read into buffer
.proc readSegmentBytes
    pha
    ldq segmentMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    pla
    ldx #0
    jmp readFromMemBuf
.endproc

; This routine reads a label from the data segment.
; The label is read into segmentLabel and null-terminated.
; Buffer is not preserved.
.proc readSegmentLabel
    lda #0
    sta buffer+1

L1: lda #1
    jsr readSegmentBytes
    lda buffer
    beq L2
    ldx buffer+1
    sta segmentLabel,x
    inc buffer+1
    bra L1

    ; Null-terminate the buffer
L2: ldx buffer+1
    sta segmentLabel,x
    rts
.endproc
