;
; frames.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The icode file's frames table (icode.inc, icodeFrames.s in icodeasm):
; each unit or library with level 1 slots, in the order the startup
; pushes them, with its slot count. A variable operand's offset is
; relative to its frame's first slot. Code generation writes the offset
; with a LINKADDR_FRAME relocation against the import "name.frame", which
; the linker defines as the frame's first slot. It keeps the table in a
; membuf, as the object file lists it (linker.inc), and copies it there.

.include "icode.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export readIcodeFrames, writeFrames, freeFrames, initFrames
.export frameReloc, isUnitModule, beginUnitFrames, endUnitFrames

.import readIcodeByte, readStatus, modName

.data

strFrame: .asciiz ".frame"

.bss

frames: .res 4              ; the membuf, or zero
frameCount: .res 1
isUnitModule: .res 1        ; non-zero while a unit's own file is read
prgFrames: .res 4           ; the program's, while a unit's are read
prgFrameCount: .res 1
prgFramesLen: .res 2
framesLen: .res 2           ; bytes in frames
left: .res 1
byte: .res 1
nameLen: .res 1
label: .res OBJ_NAME_MAX+1  ; "name.frame", null-terminated

.code

; This routine reads the frames table, which follows the imports table,
; into the membuf. The carry is set if it is bad: a name too long or the
; end of the file.
.proc readIcodeFrames
    jsr allocMemBuf
    stq frames
    lda #0
    sta framesLen
    sta framesLen+1

    jsr readIcodeByte
    sta frameCount
    sta left
L1: lda left
    beq DN
    dec left

    ; The name, then the slot count
    jsr readIcodeByte
    cmp #OBJ_NAME_MAX-.strlen(".frame")+1
    bcs BD
    sta nameLen
    jsr putByte
:   lda nameLen
    beq :+
    jsr readIcodeByte
    jsr putByte
    dec nameLen
    bra :-
:   jsr readIcodeByte
    jsr putByte
    jsr readIcodeByte
    jsr putByte
    bra L1

DN: lda readStatus
    and #$40
    bne BD
    clc
    rts

BD: sec
    rts
.endproc

; This routine writes a LINKADDR_FRAME relocation for the byte Z bytes
; past codeOffset, against the first slot of the frame numbered in A (from
; 1, in the frames table), or 0 for a unit's own (modName). Z must be kept
; for linkAddressLookup.
.proc frameReloc
    phz
    cmp #0
    bne :+
    ldx #0
OW: lda modName,x
    beq L3
    sta label,x
    inx
    bra OW
:
    pha
    ldq frames
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Skip the frames before it
    pla
    sta left
L1: dec left
    beq L2
    jsr getByte                 ; the name's length
    clc
    adc #2                      ; and the slot count
    sta nameLen
:   jsr getByte
    dec nameLen
    bne :-
    bra L1

    ; Its name, then ".frame"
L2: jsr getByte
    sta nameLen
    ldx #0
:   cpx nameLen
    beq :+
    phx
    jsr getByte
    plx
    sta label,x
    inx
    bra :-
L3:
:   ldy #0
:   lda strFrame,y
    sta label,x
    beq :+
    inx
    iny
    bra :-

:   lda #<label
    ldx #>label
    ldy #LINKADDR_FRAME
    plz
    jmp linkAddressLookup
.endproc

; This routine writes the byte in A to the membuf
.proc putByte
    sta byte
    ldq frames
    stq ptr1
    jsr ptr2ToByte
    lda #1
    ldx #0
    jsr writeToMemBuf
    inc framesLen
    bne :+
    inc framesLen+1
:   rts
.endproc

; This routine reads the next byte of the membuf into A
.proc getByte
    ldq frames
    stq ptr1
    jsr ptr2ToByte
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda byte
    rts
.endproc

; This routine points ptr2 at byte
.proc ptr2ToByte
    lda #<byte
    sta ptr2
    lda #>byte
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    rts
.endproc

; This routine writes the object file's frames to the current output:
; their count, then each one, as the membuf holds them.
.proc writeFrames
    lda frameCount
    jsr CHROUT
    ldq frames
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos
L1: lda framesLen
    ora framesLen+1
    bne :+
    rts
:   jsr getByte
    jsr CHROUT
    lda framesLen
    bne :+
    dec framesLen+1
:   dec framesLen
    bra L1
.endproc

; This routine frees the membuf, if there is one
.proc freeFrames
    ldq frames
    jsr isQZero
    beq DN
    jsr freeMemBuf
    jmp initFrames
DN: rts
.endproc

; This routine clears the membuf pointer. Code generation calls it before
; anything else, since an overlay's BSS isn't cleared.
.proc initFrames
    lda #0
    sta isUnitModule
    tax
    tay
    taz
    stq frames
    rts
.endproc

; This routine keeps the program's frames aside, for the object file,
; while a unit's own icode file is read. The unit's frames table numbers
; the frames its operands name, and frame 0 is the unit's own.
.proc beginUnitFrames
    ldq frames
    stq prgFrames
    lda frameCount
    sta prgFrameCount
    lda framesLen
    sta prgFramesLen
    lda framesLen+1
    sta prgFramesLen+1
    lda #1
    sta isUnitModule
    lda #0
    tax
    tay
    taz
    stq frames
    rts
.endproc

; This routine frees the unit's frames and puts back the program's
.proc endUnitFrames
    ldq frames
    jsr isQZero
    beq :+
    jsr freeMemBuf
:   ldq prgFrames
    stq frames
    lda prgFrameCount
    sta frameCount
    lda prgFramesLen
    sta framesLen
    lda prgFramesLen+1
    sta framesLen+1
    lda #0
    sta isUnitModule
    rts
.endproc
