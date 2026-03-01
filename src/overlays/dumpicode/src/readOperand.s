.include "icode.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export readOperand

.import dumpMnemonic, dumpHexByte, dumpHex, dumpChar, instruction

.bss

operandType: .res 1
operandValue: .res 4
strlen: .res 1

.ifndef __DEBUG__
lblIndex: .res 1
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
.proc dumpLabelXXXXX
    ; First, consume all the characters in the label
:   jsr CHRIN
    bne :-

    ; Second, dump 5 x's
    lda #5
    sta lblIndex
:   lda #'x'
    jsr dumpChar
    dec lblIndex
    bne :-

    rts
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
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; pha
    ; jsr CLRCHN
    ; pla
    ; brk
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
