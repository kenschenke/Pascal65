;
; readOperand.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; readOperand routines

.include "icode.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "cbm_kernal.inc"

.export readOperand1, readOperand2, readOperand3
.export operand1, operand2, operand3, strbuf, labelScope, scopeLabel

.import readIcodeByte

.bss

operand1: .res 5
operand2: .res 5
operand3: .res 5
strbuf: .res MAX_LINE_LENGTH+1
; A label is local to its icode file, except an entry ("name.N", the only
; labels with a period). The files are read into one object, so a label
; from a unit's file gets this scope, its number from 1 (genUnits), as a
; first byte of $80 plus the scope (scopeLabel). It is 0 in the
; program's, whose labels are unchanged.
labelScope: .res 1
scopeTmp: .res 1
savedPtr4: .res 2

.code

.proc readOperand1
    lda #<operand1
    ldx #>operand1
    jmp readOperand
.endproc

.proc readOperand2
    lda #<operand2
    ldx #>operand2
    jmp readOperand
.endproc

.proc readOperand3
    lda #<operand3
    ldx #>operand3
    ; Fall through to readOperand
.endproc

.proc readOperand
    sta ptr1
    stx ptr1+1

    jsr readIcodeByte
    ldy #0
    sta (ptr1),y

    cmp #IC_RET
    bne :+
    rts
:   cmp #IC_LBL
    beq readLabel
    cmp #IC_FLT
    beq readString
    cmp #IC_STR
    beq readString
    cmp #IC_VDR
    beq read4
    cmp #IC_VDW
    beq read4
    cmp #IC_VVR
    beq read4
    cmp #IC_VVW
    beq read4
    cmp #IC_CHR
    beq read1
    cmp #IC_IBU
    beq read1
    cmp #IC_IBS
    beq read1
    cmp #IC_BOO
    beq read1
    cmp #IC_IWU
    beq read2
    cmp #IC_IWS
    beq read2
    cmp #IC_ILU
    beq read4
    cmp #IC_ILS
    beq read4

readLabel:
    ldx #0
:   jsr readIcodeByte
    sta strbuf,x
    beq :+
    inx
    bne :-
:   lda #<strbuf
    ldx #>strbuf
    ldy labelScope
    jmp scopeLabel

readString:
    lda #0
    sta tmp2
    ; Read the string length
    jsr readIcodeByte
    sta tmp1
    ; Read the string characters
:   lda tmp1
    beq :+
    jsr readIcodeByte
    ldx tmp2
    sta strbuf,x
    inc tmp2
    dec tmp1
    bra :-
:   lda #0
    ldx tmp2
    sta strbuf,x
    rts

read1:
    lda #1
    bra readBytes

read2:
    lda #2
    bra readBytes

read3:
    lda #3
    bra readBytes

read4:
    lda #4
    ; Fall through to readBytes

readBytes:
    sta tmp1
    ldy #1
    sty tmp2
:   jsr readIcodeByte
    ldy tmp2
    sta (ptr1),y
    inc tmp2
    dec tmp1
    bne :-
    rts
.endproc

; This routine gives the null-terminated label at A/X the scope in Y
; (labelScope): unless the scope is 0, the label is empty or it is an
; entry (it has a period), it is moved up a byte and $80 plus the scope
; put in front of it. No icode label has a byte of $80 or more. The
; buffer must have room for one more byte.
.proc scopeLabel
    cpy #0
    bne :+
    rts
:   sty scopeTmp
    ldy ptr4
    sty savedPtr4
    ldy ptr4+1
    sty savedPtr4+1
    sta ptr4
    stx ptr4+1

    ; Its length, unless it is empty or has a period
    ldy #0
:   lda (ptr4),y
    beq :+
    cmp #'.'
    beq DN
    iny
    bra :-
:   cpy #0
    beq DN

    ; Move it up a byte, the terminating zero first
    tya
    tax
    inx
:   lda (ptr4),y
    iny
    sta (ptr4),y
    dey
    dey
    dex
    bne :-

    ldy #0
    lda scopeTmp
    ora #$80
    sta (ptr4),y

DN: lda savedPtr4
    sta ptr4
    lda savedPtr4+1
    sta ptr4+1
    rts
.endproc
