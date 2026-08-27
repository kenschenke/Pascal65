;
; icodeFile.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "c64.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export icodeFileOpen, icodeFileClose, icodeWriteInstruction, writeOperand
.export icodeFileEraseX

.import operand1, operand2, operand3

.data

tempFn: .byte "zztmpicode,s,w"
tempFn2:

tempFnShort: .asciiz "zztmpicode"

.code

; This routine opens the temporary file to store the intermediate code.
; On exit, the file is the current output file.
.proc icodeFileOpen
    ; First, check to see if the temporary file already exists
    lda #<tempFnShort
    ldx #>tempFnShort
    ldy #0
    ldz #0
    jsr doesFileExist
    beq L1

    ; It does exist. Erase it first.
    jsr icodeFileEraseX

    ; Call SETLFS
L1: ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ; Call SETNAM
    ldx #<tempFn
    ldy #>tempFn
    lda #tempFn2-tempFn
    jsr SETNAM
    ; Open the file and set output channel
    jsr OPEN
    ldx #1
    jsr CHKOUT
    rts
.endproc

.proc icodeFileClose
    lda #1
    jsr CLOSE
    jsr CLRCHN
    rts
.endproc

.proc icodeFileEraseX
    lda #<tempFnShort
    ldx #>tempFnShort
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile
    rts
.endproc

; This routine writes an instruction.
; The instruction is passed in A.
; The operand(s) must already be populated.
;
; The upper nibble determines how many operands the
; instruction takes: 0, 1, 2, or 3.
;    0000 xxxx - no bits are set for instructions that take no operands
;    0010 xxxx - bit 5 is set for instructions that take one operand
;    0100 xxxx - bit 6 is set for instructions that take two operands
;    1000 xxxx - bit 7 is set for instructions that take three operands
.proc icodeWriteInstruction
    bit #IC_MASK_TRINARY
    beq :+
    jsr writeThreeOper
    rts

:   bit #IC_MASK_BINARY
    beq :+
    jsr writeTwoOper
    rts

:   bit #IC_MASK_UNARY
    beq :+
    jsr writeOneOper
    rts

:   jsr writeNoOper
    rts
.endproc

; This routine writes an icode instruction that takes no operands.
.proc writeNoOper
    jsr CHROUT
    rts
.endproc

; This routine writes an icode instruction that takes one operand.
.proc writeOneOper
    jsr CHROUT
    lda #<operand1
    ldx #>operand1
    jsr writeOperand
    rts
.endproc

; This routine writes an icode instruction that takes two operands.
.proc writeTwoOper
    jsr CHROUT

    lda #<operand1
    ldx #>operand1
    jsr writeOperand

    lda #<operand2
    ldx #>operand2
    jsr writeOperand

    rts
.endproc

; This routine writes an icode instruction that takes three operands.
.proc writeThreeOper
    jsr CHROUT

    lda #<operand1
    ldx #>operand1
    jsr writeOperand

    lda #<operand2
    ldx #>operand2
    jsr writeOperand

    lda #<operand3
    ldx #>operand3
    jsr writeOperand

    rts
.endproc

; This routine writes an operand to the icode stream.
; The address to the operand is passed in A/X.
; The first byte of the operand is the operand type.
; The remaining 1-4 bytes for the value of the operand.
.proc writeOperand
    ; Operand pointer in ptr1
    sta ptr1
    stx ptr1+1

    ; Write the instruction code
    ldy #0
    lda (ptr1),y
    pha
    jsr CHROUT

    ; Figure out how many bytes are in the operand value
    pla
    cmp #IC_VDR
    beq IV
    cmp #IC_VDW
    beq IV
    cmp #IC_VVR
    beq IV
    cmp #IC_VVW
    beq IV
    cmp #IC_LBL
    beq IL
    cmp #IC_STR
    beq IS
    cmp #IC_FLT
    beq IS
    cmp #IC_RET
    beq DN
    cmp #IC_CHR
    beq V1
    cmp #IC_IBU
    beq V1
    cmp #IC_IBS
    beq V1
    cmp #IC_BOO
    beq V1
    cmp #IC_IWU
    beq V2
    cmp #IC_IWS
    beq V2
    cmp #IC_ILU
    beq V4
    cmp #IC_ILS
    beq V4
    rts

    ; Variable reference
IV: lda #3
    jmp writeOperandValue

    ; Label
IL: jmp writeOperandLabel

    ; String
IS: jmp writeOperandString

    ; 1 byte value
V1: lda #1
    jmp writeOperandValue

    ; 2 byte value
V2: lda #2
    jmp writeOperandValue

    ; 4 byte value
V4: lda #4
    jmp writeOperandValue

DN: rts
.endproc

; This routine writes the value for the operand.
; The length of the value is passed in A.
.proc writeOperandValue
    sta tmp1
    lda #1
    sta tmp2
L1: ldy tmp2
    lda (ptr1),y
    jsr CHROUT
    inc tmp2
    dec tmp1
    bne L1
    rts
.endproc

; This routine writes an operand label.
; The label pointer is in the first two bytes of the operand.
; The pointer to the operand is expected in ptr1.
; The label, including its null-terminator is written out.
.proc writeOperandLabel
    ldy #0
    sty tmp1
    iny
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2+1
L1: ldy tmp1
    lda (ptr2),y
    beq L2
    jsr CHROUT
    inc tmp1
    bne L1
L2: jsr CHROUT
    rts
.endproc

; This routine writes an operand string.
; The pointer to the operand is expected in ptr1.
; The length of the string is written, followed by the string.
.proc writeOperandString
    ldy #1
    ldx #0
L1: lda (ptr1),y
    sta ptr2,x
    iny
    inx
    cpx #4
    bne L1

    ldq ptr2
    jsr isQZero
    bne :+
    ; String pointer is NULL
    lda #0
    jsr CHROUT
    rts

    ; Count the string length
    ldz #0
:   nop
    lda (ptr2),z
    beq :+
    inz
    bne :-
:   tza
    jsr CHROUT

; Write the string
    lda #0
    sta tmp1
L2: ldz tmp1
    nop
    lda (ptr2),z
    beq :+
    jsr CHROUT
    inc tmp1
    bne L2

:   rts
.endproc
