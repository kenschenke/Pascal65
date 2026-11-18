.include "c64.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export dumpIcode, memBuf, dumpNewline, dumpChar, printz

.import readInstruction, dumpHex

.data

tempFn: .byte "zztmpicode,s,r"
tempFn2:

strHdr: .asciiz "HDR "
strPrg: .asciiz "PRG "
strUnit: .asciiz "UNIT "
strBadHdr: .asciiz "BAD HEADER"

.bss

memBuf: .res 4
buf: .res 1
hdrByte: .res 1
hdrCount: .res 1

.code

.proc dumpIcode
    jsr allocMemBuf
    stq memBuf

    ; Open the icode file
    ; Call SETLFS
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ; Call SETNAM
    ldx #<tempFn
    ldy #>tempFn
    lda #tempFn2-tempFn
    jsr SETNAM
    ; Open the file and set input channel
    jsr OPEN
    ldx #1
    jsr CHKIN

    jsr dumpHeader
    bcs L3

    ; Loop, reading instructions from the icode
L1: lda STATUS
    cmp #$40
    beq L3
    jsr CHRIN

    ; If __DEBUG__ is defined, leave IC_LIN instructions in the dump
    ; for debugging purposes.
.ifndef __DEBUG__
    ; If the instruction is IC_LIN, skip it (and the next three bytes)
    cmp #IC_LIN
    bne L2
    jsr CHRIN
    jsr CHRIN
    jsr CHRIN
    bra L1
.endif

L2: jsr readInstruction
    jsr dumpNewline
    bra L1

    ; Close the icode file
L3: lda #1
    jsr CLOSE
    jsr CLRCHN

    ldq memBuf
    rts
.endproc

; This routine dumps the icode file's header (icode.inc) as one line:
;    HDR PRG|UNIT name mode stacksize
; with the mode and stack size in hex. If the file isn't icode of this
; version it dumps BAD HEADER and returns with the carry set.
.proc dumpHeader
    jsr CHRIN
    cmp #ICODE_MAGIC0
    bne BD
    jsr CHRIN
    cmp #ICODE_MAGIC1
    bne BD
    jsr CHRIN
    cmp #ICODE_VERSION
    bne BD

    lda #<strHdr
    ldx #>strHdr
    jsr printz
    jsr CHRIN
    cmp #ICODE_KIND_UNIT
    beq :+
    lda #<strPrg
    ldx #>strPrg
    bra :++
:   lda #<strUnit
    ldx #>strUnit
:   jsr printz

    ; The mode and the stack size, read before the name that follows them
    jsr CHRIN
    sta hdrByte
    jsr CHRIN
    pha
    jsr CHRIN
    tax
    pla
    phx
    pha

    ; The name
    jsr CHRIN
    sta hdrCount
:   lda hdrCount
    beq :+
    jsr CHRIN
    jsr dumpChar
    dec hdrCount
    bra :-
:   lda #' '
    jsr dumpChar

    lda hdrByte
    ldx #0
    ldy #0
    ldz #0
    jsr dumpHex
    lda #' '
    jsr dumpChar
    pla
    plx
    ldy #0
    ldz #0
    jsr dumpHex
    jsr dumpNewline
    clc
    rts

BD: lda #<strBadHdr
    ldx #>strBadHdr
    jsr printz
    jsr dumpNewline
    sec
    rts
.endproc

.proc dumpNewline
    lda #13
    ; Fall through to dumpChar
.endproc

.proc dumpChar
    sta buf
    ldq memBuf
    stq ptr1
    lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf
    rts
.endproc

.proc printz
    sta ptr2
    stx ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ldq ptr1
    jsr pushQ
    ldq memBuf
    stq ptr1
    
    ldy #0
:   lda (ptr2),y
    beq :+
    iny
    bne :-
:   tya
    ldx #0
    jsr writeToMemBuf
    jsr popQ
    stq ptr1
    rts
.endproc
