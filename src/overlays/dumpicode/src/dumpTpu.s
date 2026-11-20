;
; dumpTpu.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpTpu dumps a compiled unit (tpu.inc): its header, the units it uses,
; the size of its interface section and its icode section, then the icode
; as dumpIcode dumps a unit's file:
;
;    TPU version icodeversion flags xxxx interfacecrc
;    USE name interfacecrc         for each unit it uses
;    INT length records            the interface section
;    COD length                    the icode section
;    HDR UNIT ...                  and the rest of the icode
;
; The numbers are in hex. The source's CRC is shown as xxxx, since a test's
; expected dump is in the source; tputest checks it on its own. The
; interface section is a pre-compiled header (hdr.inc). Only its magic and
; record count are read.

.include "c64.inc"
.include "hdr.inc"
.include "tpu.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export dumpTpu, dumpTpuFile

.import dumpStream, dumpTpuStart, dumpChar, dumpNewline, printz, dumpHex
.import memBuf

.data

strTpuSuffix: .asciiz ".tpu,s,r"
strTpu: .asciiz "TPU "
strMask: .asciiz "xxxx "
strUse: .asciiz "USE "
strInt: .asciiz "INT "
strCod: .asciiz "COD "
strBadTpu: .asciiz "BAD TPU"
strBadInt: .asciiz "BAD INTERFACE"

.bss

fnBuf: .res 24
count: .res 1
nameLen: .res 1
left: .res 2

.code

; This routine dumps <name>.tpu, the unit's name at A/X (16 bits,
; null-terminated), into a membuf it returns in Q
.proc dumpTpu
    pha
    phx
    jsr dumpTpuStart
    plx
    pla
    ; Fall through to dumpTpuFile
.endproc

; This routine dumps <name>.tpu, the unit's name at A/X, into memBuf,
; and returns memBuf in Q. A program's dump dumps a unit whose code is
; in its TPU this way (dumpUnits).
.proc dumpTpuFile
    sta ptr2
    stx ptr2+1
    ldy #0
:   lda (ptr2),y
    beq :+
    sta fnBuf,y
    iny
    cpy #12
    bne :-
:   ldx #0
:   lda strTpuSuffix,x
    sta fnBuf,y
    beq :+
    inx
    iny
    bra :-
:   phy
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    pla
    ldx #<fnBuf
    ldy #>fnBuf
    jsr SETNAM
    jsr OPEN
    ldx #1
    jsr CHKIN

    ; The magic, then TPU, the versions and the flags
    jsr CHRIN
    cmp #TPU_MAGIC0
    bne BT
    jsr CHRIN
    cmp #TPU_MAGIC1
    beq :+
BT: lda #<strBadTpu
    ldx #>strBadTpu
    jmp BD
:   lda #<strTpu
    ldx #>strTpu
    jsr printz
    jsr hexIn                   ; TPU_VERSION
    jsr hexIn                   ; ICODE_VERSION
    jsr hexIn                   ; the flags
    lda #<strMask               ; the source's CRC
    ldx #>strMask
    jsr printz
    jsr CHRIN
    jsr CHRIN
    jsr wordIn                  ; the interface's CRC
    jsr dumpNewline

    ; The units it uses
    jsr CHRIN
    sta count
L1: lda count
    beq IN
    dec count
    lda #<strUse
    ldx #>strUse
    jsr printz
    jsr CHRIN
    sta nameLen
:   lda nameLen
    beq :+
    jsr CHRIN
    jsr dumpChar
    dec nameLen
    bra :-
:   lda #' '
    jsr dumpChar
    jsr wordIn
    jsr dumpNewline
    bra L1

    ; The interface section: its length, then a header's magic, version
    ; and record count. The rest is skipped.
IN: jsr CHRIN
    sta left
    jsr CHRIN
    sta left+1
    lda #<strInt
    ldx #>strInt
    jsr printz
    lda left
    ldx left+1
    ldy #0
    ldz #0
    jsr dumpHex
    lda #' '
    jsr dumpChar
    lda left+1                  ; at least the magic, version and count
    bne :+
    lda left
    cmp #5
    bcc BI
:   jsr CHRIN
    cmp #'P'
    bne BI
    jsr CHRIN
    cmp #'H'
    bne BI
    jsr CHRIN
    cmp #HDR_VERSION
    beq :+
BI: lda #<strBadInt
    ldx #>strBadInt
    jmp BD
:   jsr wordIn                  ; the record count
    jsr dumpNewline
    sec
    lda left
    sbc #5
    sta left
    lda left+1
    sbc #0
    sta left+1
L2: lda left
    ora left+1
    beq CD
    jsr CHRIN
    lda left
    bne :+
    dec left+1
:   dec left
    bra L2

    ; The icode section: its length, then the icode
CD: lda #<strCod
    ldx #>strCod
    jsr printz
    jsr CHRIN
    pha
    jsr CHRIN
    tax
    pla
    ldy #0
    ldz #0
    jsr dumpHex
    jsr dumpNewline
    jsr dumpStream
    ldq memBuf
    rts

    ; A bad file: the message at A/X, then close it
BD: jsr printz
    jsr dumpNewline
    lda #1
    jsr CLOSE
    jsr CLRCHN
    ldq memBuf
    rts
.endproc

; This routine reads a byte and dumps it in hex, then a space
.proc hexIn
    jsr CHRIN
    ldx #0
    ldy #0
    ldz #0
    jsr dumpHex
    lda #' '
    jmp dumpChar
.endproc

; This routine reads a word, low byte first, and dumps it in hex
.proc wordIn
    jsr CHRIN
    pha
    jsr CHRIN
    tax
    pla
    ldy #0
    ldz #0
    jmp dumpHex
.endproc
