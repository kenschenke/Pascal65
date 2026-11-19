.include "icode.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export readOperand, operandValue

.ifndef __DEBUG__
.export dumpLabelXXXXX, dumpLabelFrom
.endif

.import dumpMnemonic, dumpHexByte, dumpHex, dumpChar, instruction

.bss

operandType: .res 1
operandValue: .res 4
strlen: .res 1

.ifndef __DEBUG__
LBLMAX = 31
lblIndex: .res 1
hasDot: .res 1
lblBuf: .res LBLMAX+1
.endif

.code

.proc readOperand
    lda #' '
    jsr dumpChar

    jsr CHRIN
    sta operandType
    jsr dumpMnemonic
    lda #' '
    jsr dumpChar

    lda operandType
    cmp #IC_LBL
    bne :+
.ifdef __DEBUG__
    jsr dumpLabel
.else
    jmp dumpLabelXXXXX
.endif
    rts

:   cmp #IC_FLT
    bne :+
    jsr dumpString
    rts

:   cmp #IC_STR
    bne :+
    jsr dumpString
    rts

:   cmp #IC_VDR
    bne :+
    jsr dumpVar
    rts
:   cmp #IC_VDW
    bne :+
    jsr dumpVar
    rts
:   cmp #IC_VVR
    bne :+
    jsr dumpVar
    rts
:   cmp #IC_VVW
    bne :+
    jsr dumpVar
    rts
:   cmp #IC_RET
    bne :+
    rts
:   cmp #IC_CHR
    beq dumpc
    cmp #IC_IBU
    beq dump1
    cmp #IC_IBS
    beq dump1
    cmp #IC_BOO
    beq dump1
    cmp #IC_IWU
    beq dump2
    cmp #IC_IWS
    beq dump2
    cmp #IC_ILU
    beq dump4
    cmp #IC_ILS
    beq dump4

dumpc:
    jsr CHRIN
    beq :+
    jsr dumpChar
:   rts
    
dump1:
    lda #1
    jsr dumpNumber
    rts

dump2:
    lda #2
    jsr dumpNumber
    rts

dump4:
    lda #4
    jsr dumpNumber
    rts
.endproc

.proc dumpLabel
L1: jsr CHRIN
    beq L2

    jsr dumpChar
    bra L1

L2: rts
.endproc

.ifndef __DEBUG__
; This routine dumps a label read from the file: in full if it names a
; module's entry ("name.N", icodeExports.s in icodeasm), otherwise as
; five x's, since the other labels are made from heap addresses.
.proc dumpLabelXXXXX
    jsr CHRIN
    ; Fall through
.endproc

; As dumpLabelXXXXX, with the label's first character, already read, in A.
; A label with no characters dumps nothing.
.proc dumpLabelFrom
    ldx #0
    stx hasDot
L1: cpx #LBLMAX
    bcs :+
    sta lblBuf,x
    inx
:   cmp #0
    beq L2
    cmp #'.'
    bne :+
    sta hasDot
:   phx
    jsr CHRIN
    plx
    bra L1

L2: lda #0
    sta lblBuf+LBLMAX
    cpx #1
    beq DN                  ; no characters
    lda hasDot
    beq XX
    ldx #0
:   lda lblBuf,x
    beq DN
    phx
    jsr dumpChar
    plx
    inx
    bra :-

XX: lda #5
    sta lblIndex
:   lda #'x'
    jsr dumpChar
    dec lblIndex
    bne :-
DN: rts
.endproc
.endif

.proc dumpVar
    jsr CHRIN
    ldx #0
    ldy #0
    ldz #0
    jsr dumpHex

    lda #' '
    jsr dumpChar
    jsr CHRIN
    ldx #0
    ldy #0
    ldz #0
    jsr dumpHex

    lda #' '
    jsr dumpChar
    jsr CHRIN
    ldx #0
    ldy #0
    ldz #0
    jsr dumpHex

    rts
.endproc

.proc dumpString
    ; Read the string length
    jsr CHRIN
    beq L2
    sta strlen

    ; Read the string
L1: jsr CHRIN
    jsr dumpChar
    dec strlen
    bne L1

L2: rts
.endproc

.proc dumpNumber
    sta tmp1            ; value length in tmp1

    lda #0
    tax
L1: sta operandValue,x
    inx
    cpx #4
    bne L1

    lda #0
    sta tmp2
L2: jsr CHRIN
    ldx tmp2
    sta operandValue,x
    inc tmp2
    dec tmp1
    bne L2

.ifndef __DEBUG__
    lda instruction
    cmp #IC_DIA
    bne :+
    ; Array initialization.
    lda #0
    tax
    tay
    taz
    stq operandValue
:   cmp #IC_DIR
    bne :+
    ; Record initialization
    lda #0
    tax
    tay
    taz
    stq operandValue
:
.endif

    ldq operandValue
    jsr dumpHex

    rts
.endproc
