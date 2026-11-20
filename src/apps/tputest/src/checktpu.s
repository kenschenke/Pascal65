;
; checktpu.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; checkTpu checks a unit's TPU (tpu.inc) against the bytes it describes,
; which its dump can't show: the source's CRC against the source file,
; the interface's CRC against the interface section, and the icode
; section's length against the bytes after it, to the end of the file. It
; keeps each test's interface CRC and checks the pairs crcPairs lists:
; a test whose interface must have the same CRC as an earlier test's, or a
; different one.

.include "c64.inc"
.include "tpu.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export checkTpu, clearCrcs

.import testFail, printLine, unitName, sourceFn

FILE_IN = 2
MAX_TESTS = 32

.data

strTpuSuffix: .asciiz ".tpu,s,r"
strSeqRead: .asciiz ",s,r"
strBadMagic: .byte "Not a TPU", 13, 0
strSrcCrc: .byte "Wrong source CRC", 13, 0
strIntCrc: .byte "Wrong interface CRC", 13, 0
strIntShort: .byte "Interface section too short", 13, 0
strCodLen: .byte "Wrong icode section length", 13, 0
strCodMagic: .byte "Icode section isn't icode", 13, 0
strSame: .byte "Interface CRC changed", 13, 0
strDiffer: .byte "Interface CRC didn't change", 13, 0

; Pairs of tests, then 1 if their interfaces' CRCs must be the same or 0
; if they must differ, ending with 0. The second test runs first. Tests 3
; to 5 are one unit: 4 changes only its implementation, and 5 its
; interface, keeping its lines.
crcPairs:
    .byte 4, 3, 1
    .byte 5, 3, 0
    .byte 0

.bss

testNum: .res 1
fnBuf: .res 32
fnLen: .res 1
crc: .res 2
srcCrc: .res 2
ifCrc: .res 2
left: .res 2
count: .res 1
crcKnown: .res MAX_TESTS + 1    ; non-zero for each test that has run
crcLo: .res MAX_TESTS + 1       ; its interface CRC
crcHi: .res MAX_TESTS + 1

.code

; This routine forgets every test's interface CRC
.proc clearCrcs
    ldx #MAX_TESTS
    lda #0
:   sta crcKnown,x
    dex
    bpl :-
    rts
.endproc

; This routine checks unitName's TPU, written by the test numbered in A,
; and fails the test if it is wrong
.proc checkTpu
    sta testNum

    ; <unit>.tpu
    ldy #0
:   lda unitName,y
    beq :+
    sta fnBuf,y
    iny
    bra :-
:   ldx #0
:   lda strTpuSuffix,x
    sta fnBuf,y
    beq :+
    inx
    iny
    bra :-
:   sty fnLen
    jsr openIn

    ; The magic and versions, then the CRCs
    jsr CHRIN
    cmp #TPU_MAGIC0
    bne BM
    jsr CHRIN
    cmp #TPU_MAGIC1
    beq :+
BM: lda #<strBadMagic
    ldx #>strBadMagic
    jmp fail
:   jsr CHRIN                   ; TPU_VERSION, ICODE_VERSION and the flags
    jsr CHRIN
    jsr CHRIN
    jsr CHRIN
    sta srcCrc
    jsr CHRIN
    sta srcCrc+1
    jsr CHRIN
    sta ifCrc
    jsr CHRIN
    sta ifCrc+1

    ; The used units are skipped
    jsr CHRIN
    sta count
L1: lda count
    beq IN
    dec count
    jsr CHRIN                   ; the name, then its CRC
    clc
    adc #2
    tax
:   phx
    jsr CHRIN
    plx
    dex
    bne :-
    bra L1

    ; The interface section's CRC
IN: jsr CHRIN
    sta left
    jsr CHRIN
    sta left+1
    jsr startCrc
L2: lda left
    ora left+1
    beq IC
    lda STATUS
    and #$40
    beq :+
    lda #<strIntShort
    ldx #>strIntShort
    jmp fail
:   jsr CHRIN
    jsr crcByte
    lda left
    bne :+
    dec left+1
:   dec left
    bra L2
IC: lda crc
    cmp ifCrc
    bne :+
    lda crc+1
    cmp ifCrc+1
    beq :++
:   lda #<strIntCrc
    ldx #>strIntCrc
    jmp fail

    ; The icode section's length is the rest of the file, which starts
    ; as icode does
:   jsr CHRIN
    sta left
    jsr CHRIN
    sta left+1
    jsr CHRIN
    cmp #ICODE_MAGIC0
    beq L3
    lda #<strCodMagic
    ldx #>strCodMagic
    jmp fail
L3: lda left
    ora left+1
    beq BL
    lda left
    bne :+
    dec left+1
:   dec left
    lda STATUS
    and #$40
    bne :+
    jsr CHRIN
    bra L3
:   lda left
    ora left+1
    beq :+
BL: lda #<strCodLen
    ldx #>strCodLen
    jmp fail
:   jsr closeIn

    ; The source's CRC
    ldy #0
:   lda sourceFn,y
    beq :+
    sta fnBuf,y
    iny
    bra :-
:   ldx #0
:   lda strSeqRead,x
    sta fnBuf,y
    beq :+
    inx
    iny
    bra :-
:   sty fnLen
    jsr openIn
    jsr startCrc
:   jsr CHRIN
    jsr crcByte
    lda STATUS
    and #$40
    beq :-
    jsr closeIn
    lda crc
    cmp srcCrc
    bne :+
    lda crc+1
    cmp srcCrc+1
    beq :++
:   lda #<strSrcCrc
    ldx #>strSrcCrc
    jmp printFail

    ; Keep the interface's CRC, then check the pairs
:   ldx testNum
    cpx #MAX_TESTS+1
    bcs DN
    lda ifCrc
    sta crcLo,x
    lda ifCrc+1
    sta crcHi,x
    lda #1
    sta crcKnown,x
    jmp checkPairs
DN: rts
.endproc

; This routine checks each pair in crcPairs whose first test is testNum
; and whose second has run
.proc checkPairs
    ldy #0
L1: lda crcPairs,y
    bne :+
    rts
:   cmp testNum
    bne NX
    ldx crcPairs+1,y
    lda crcKnown,x
    beq NX
    lda crcLo,x
    cmp ifCrc
    bne DF
    lda crcHi,x
    cmp ifCrc+1
    bne DF
    lda crcPairs+2,y            ; the same
    bne NX
    lda #<strDiffer
    ldx #>strDiffer
    jmp printFail
DF: lda crcPairs+2,y            ; different
    beq NX
    lda #<strSame
    ldx #>strSame
    jmp printFail
NX: iny
    iny
    iny
    bra L1
.endproc

; This routine opens fnBuf as the input
.proc openIn
    ldx workDevice
    lda #FILE_IN
    tay
    jsr SETLFS
    lda fnLen
    ldx #<fnBuf
    ldy #>fnBuf
    jsr SETNAM
    jsr OPEN
    ldx #FILE_IN
    jmp CHKIN
.endproc

.proc closeIn
    lda #FILE_IN
    jsr CLOSE
    jmp CLRCHN
.endproc

; This routine closes the input, then prints the message at A/X and fails
; the test
.proc fail
    pha
    phx
    jsr closeIn
    plx
    pla
    ; Fall through to printFail
.endproc

.proc printFail
    pha
    lda #13
    jsr CHROUT
    pla
    jsr printLine
    jmp testFail
.endproc

.proc startCrc
    lda #$ff
    sta crc
    sta crc+1
    rts
.endproc

; This routine adds the byte in A to the CRC (CRC-16/CCITT, $1021)
.proc crcByte
    eor crc+1
    sta crc+1
    ldx #8
L1: asl crc
    rol crc+1
    bcc :+
    lda crc+1
    eor #$10
    sta crc+1
    lda crc
    eor #$21
    sta crc
:   dex
    bne L1
    rts
.endproc
