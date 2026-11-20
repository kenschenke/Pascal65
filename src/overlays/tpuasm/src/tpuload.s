;
; tpuload.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; tpuLoadX (tpuLoad, tpu.inc) loads a unit from its TPU (tpu.inc) in place
; of parsing its source: its interface, as a library's header is loaded
; (hdrReadOpen), and what the interface doesn't give. The units the TPU
; lists are added to the units list, so they are loaded or parsed in
; turn. The icode header's slot count is the unit's whole count: the
; interface holds only the interface's variables, which come first
; (setDeclOffsets.s), and setUnitOffsets.s uses the count for the rest.

.include "c64.inc"
.include "ast.inc"
.include "tpu.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export tpuLoadX

.import hdrReadOpen

FILE_IN = 2

.data

strTpuSuffix: .asciiz ".tpu"
strSeqRead: .asciiz ",s,r"

.bss

loadUnit: .res 4            ; the unit being loaded
listHead: .res 4            ; the units list
lastUnit: .res 4
rootAddr: .res 4
ifCrc: .res 2
slots: .res 2
count: .res 1
nameLen: .res 1
nameBuf: .res 24
fnBuf: .res 24
fnLen: .res 1
tpuDevice: .res 1           ; the disk the TPU is on (locateFile)

.code

; This routine loads the unit in Q from its TPU, if it has one. The units
; list (4 bytes) is on the runtime stack. Returns the carry set with the
; unit's root declaration in Q, or the carry clear if the unit has no TPU
; or it is not of this TPU and icode version. The caller stores the root.
.proc tpuLoadX
    stq loadUnit
    jsr popQ
    stq listHead

    ; <name>.tpu
    ldq loadUnit
    stq ptr1
    ldz #unit::name
    ldx #0
:   nop
    lda (ptr1),z
    beq :+
    sta fnBuf,x
    inz
    inx
    bra :-
:   ldy #0
:   lda strTpuSuffix,y
    sta fnBuf,x
    beq :+
    inx
    iny
    bra :-
:   stx fnLen
    lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    jsr locateFile                ; the work disk, then the system disk
    sta tpuDevice
    bne :+
    clc
    rts

:   jsr openIn
    jsr CHRIN
    cmp #TPU_MAGIC0
    bne BD
    jsr CHRIN
    cmp #TPU_MAGIC1
    bne BD
    jsr CHRIN
    cmp #TPU_VERSION
    bne BD
    jsr CHRIN
    cmp #ICODE_VERSION
    beq :+
BD: jsr closeIn
    clc
    rts

:   jsr CHRIN                   ; the flags
    jsr CHRIN                   ; the source's CRC
    jsr CHRIN
    jsr CHRIN                   ; the interface's
    sta ifCrc
    jsr CHRIN
    sta ifCrc+1

    ; The units it uses, each added to the list if it isn't there
    jsr CHRIN
    sta count
L1: lda count
    beq IN
    dec count
    jsr CHRIN
    sta nameLen
    ldx #0
:   cpx nameLen
    beq :+
    phx
    jsr CHRIN
    plx
    sta nameBuf,x
    inx
    bra :-
:   lda #0
    sta nameBuf,x
    jsr CHRIN                   ; its CRC
    jsr CHRIN
    jsr addUsed
    bra L1

    ; The interface section: its length, then a header
IN: jsr CHRIN
    jsr CHRIN
    jsr hdrReadOpen
    bcc BD
    stq rootAddr

    ; The icode section: its length, then the icode header, to its slots
    jsr CHRIN
    jsr CHRIN
    ldx #ICODE_HDR_SLOTS
:   phx
    jsr CHRIN
    plx
    dex
    bne :-
    jsr CHRIN
    sta slots
    jsr CHRIN
    sta slots+1
    jsr closeIn

    ldq loadUnit
    stq ptr1
    ldz #unit::fromTpu
    lda #1
    nop
    sta (ptr1),z
    ldz #unit::tpuSlots
    lda slots
    nop
    sta (ptr1),z
    inz
    lda slots+1
    nop
    sta (ptr1),z
    ldz #unit::ifCrc
    lda ifCrc
    nop
    sta (ptr1),z
    inz
    lda ifCrc+1
    nop
    sta (ptr1),z
    ldq rootAddr
    sec
    rts
.endproc

; This routine adds the unit named in nameBuf to the end of the units
; list, unless it is in it
.proc addUsed
    ldq listHead
L1: stq lastUnit
    stq ptr1
    ldz #unit::name
    ldx #0
:   nop
    lda (ptr1),z
    cmp nameBuf,x
    bne NX
    cmp #0
    beq DN                      ; it's there
    inz
    inx
    bra :-
NX: ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L1

    lda #<nameBuf
    ldx #>nameBuf
    jsr unitCreate
    stq rootAddr                ; for a moment
    ldq lastUnit
    stq ptr1
    ldz #unit::next
    ldx #0
:   lda rootAddr,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
DN: rts
.endproc

.proc openIn
    ldx fnLen
    ldy #0
:   lda strSeqRead,y
    sta fnBuf,x
    beq :+
    inx
    iny
    bra :-
:   stx fnLen
    ldx tpuDevice
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
    jsr CLRCHN
    lda #FILE_IN
    jmp CLOSE
.endproc
