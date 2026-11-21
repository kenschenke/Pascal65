;
; workdisk.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Checks, makes and refreshes a work disk (plans/workdisks.md, workdisk.inc).
;
; A work disk has the marker, p65work, and its own copy of runtimeN, which
; a dynamic program loads from the disk it runs from. wdCreate also copies
; the system disk's themes.dat, so the disk has its own theme. The IDE
; never formats a disk: wdCreate takes one with no files on it.

.include "cbm_kernal.inc"
.include "c64.inc"
.include "asm.inc"
.include "asmlib.inc"
.include "workdisk.inc"

.export wdCheck, wdCreate, wdRefresh, setName

.import openCmd, readStatus, closeAll, openFile, statusCode, nameBuf
.import copyFile, copyFrom, copyTo, copyName, copyType
.include "wdio.inc"

MARKER_MAX = 32             ; The bytes of the marker read

.bss

unit: .res 1
code: .res 1
first: .res 1               ; Set while the directory's header is read
quote: .res 1               ; Set once a line has a quote
marker: .res MARKER_MAX
markerLen: .res 1

.data

markerName: .asciiz WD_MARKER
runtimeName: .asciiz .sprintf("runtime%d", RT_ABI_VERSION)
themesName: .asciiz "themes.dat"
dirName: .byte "$"
dirName2:
; What wdCreate scratches if it fails
scratchCmd: .byte "s0:", WD_MARKER, ","
    .byte .sprintf("runtime%d", RT_ABI_VERSION), ",themes.dat"
scratchCmd2:
markerData: .byte WD_MAGIC0, WD_MAGIC1, WD_VERSION, WD_RELEASE, 0
markerData2:

.code

; Puts the name in A/X, a comma, the type in Y, a comma and "r" (carry
; clear) or "w" (carry set) in nameBuf. Y is the length.
.proc setName
    sta ptr
    stx ptr+1
    sty type
    lda #'r'
    bcc :+
    lda #'w'
:   sta mode
    ldx #0
:   lda $ffff,x
ptr = * - 2
    beq :+
    sta nameBuf,x
    inx
    bne :-
:   lda #','
    sta nameBuf,x
    inx
    lda type
    sta nameBuf,x
    inx
    lda #','
    sta nameBuf,x
    inx
    lda mode
    sta nameBuf,x
    inx
    txa
    tay
    rts
.pushseg
.bss
type: .res 1
mode: .res 1
.popseg
.endproc

; Is the unit in A a work disk? Returns WD_OK if it is, or why it isn't
; (workdisk.inc): WD_BLANK if it has no files, WD_NOTBLANK if it has
; files and no marker.
.proc wdCheck
    sta unit
    cmp sysDevice
    bne :+
    lda #WD_SYSDISK
    rts
:   lda #LFN_CMD
    ldx unit
    jsr openCmd
    bcc :+
    lda #WD_NODEVICE
    rts
:   ldx #LFN_CMD
    jsr readStatus
    cmp #$74
    bne :+
    lda #WD_NOTREADY
    bra DN

:   jsr readMarker
    bcs :+                  ; There is no marker
    jsr checkMarker
    bra DN
:   bne DN                  ; It couldn't be read
    jsr countFiles
DN: sta code
    jsr closeAll
    lda code
    rts
.endproc

; Reads the marker from unit into marker, markerLen bytes. The command
; channel is open. The carry is set if there is no marker, with A WD_OK,
; or if it couldn't be read, with the WD_* code in A, and Z set as A.
.proc readMarker
    lda #<markerName
    ldx #>markerName
    ldy #'s'
    clc
    jsr setName
    lda #LFN_IN
    ldx unit
    jsr openFile
    bcs IO
    ldx #LFN_CMD
    jsr readStatus
    cmp #$62
    beq NO
    cmp #$64                ; Not a SEQ file
    beq BM
    jsr statusCode
    bne ER
    ldx #LFN_IN
    jsr CHKIN
    bcs IO
    lda #0
    sta markerLen
    sta STATUS
L1: jsr CHRIN
    ldy markerLen
    sta marker,y
    inc markerLen
    lda STATUS
    bne :+
    lda markerLen
    cmp #MARKER_MAX
    bne L1
    bra DN
:   cmp #$40
    bne IO
DN:
    jsr CLRCHN
    lda #LFN_IN
    jsr CLOSE
    clc
    rts

NO: lda #LFN_IN
    jsr CLOSE
    lda #WD_OK
    sec
    rts
BM: lda #WD_BADMARKER
    bra ER
IO: lda #WD_IOERROR
ER: pha
    jsr CLRCHN
    lda #LFN_IN
    jsr CLOSE
    pla
    sec
    rts
.endproc

; Returns WD_OK if marker is one this release reads, or WD_BADMARKER: the
; magic, a version from 1 and the release's terminator at least.
.proc checkMarker
    lda markerLen
    cmp #4
    bcc BM
    lda marker
    cmp #WD_MAGIC0
    bne BM
    lda marker+1
    cmp #WD_MAGIC1
    bne BM
    lda marker+2
    beq BM
    lda #WD_OK
    rts
BM: lda #WD_BADMARKER
    rts
.endproc

; Reads the directory of unit, whose command channel is open. Returns
; WD_BLANK if it lists no files and WD_NOTBLANK if it does, or the WD_*
; code of a read error.
;
; The directory is read as a BASIC listing (secondary address 0): two
; bytes of load address, then lines of a link, a line number and text
; ending in a zero, then a link of zero. The first line is the disk's
; name and the last the blocks free. A file's line has its name in
; quotes, as the disk's does, and the blocks free has none.
.proc countFiles
    lda #LFN_IN
    ldx unit
    ldy #0
    jsr SETLFS
    lda #dirName2-dirName
    ldx #<dirName
    ldy #>dirName
    jsr SETNAM
    jsr OPEN
    bcs IO
    ldx #LFN_CMD
    jsr readStatus
    jsr statusCode
    bne ER
    ldx #LFN_IN
    jsr CHKIN
    bcs IO
    lda #0
    sta STATUS
    jsr getByte             ; The load address
    jsr getByte
    bcs IO
    lda #1
    sta first

L1: jsr getByte             ; The link
    sta code
    jsr getByte
    bcs IO
    ora code
    beq BL                  ; The end
    jsr getByte             ; The line number
    jsr getByte
    bcs IO
    lda #0
    sta quote
L2: jsr getByte             ; The text
    bcs IO
    beq L3
    cmp #'"'
    bne L2
    sta quote
    bra L2
L3: lda first
    beq :+
    lda #0
    sta first
    bra L1
:   lda quote
    beq L1
    lda #WD_NOTBLANK
    bra ER

BL: lda #WD_BLANK
    bra ER
IO: lda #WD_IOERROR
ER: pha
    jsr CLRCHN
    lda #LFN_IN
    jsr CLOSE
    pla
    rts
.endproc

; Reads a byte of the directory into A, with the flags set for it. The
; carry is set if the read failed or the listing ended too soon.
.proc getByte
    jsr CHRIN
    pha
    lda STATUS
    beq OK
    and #$bf                ; The end of the file is the last byte
    bne ER
    pla
    pha
    bne ER                  ; Only the end's zero link can be last
OK: pla
    clc
    rts
ER: pla
    sec
    rts
.endproc

; Makes a work disk of the blank disk in the unit in A. Returns WD_OK, or
; WD_NOTBLANK if the disk has files, the WD_* code of wdCheck if it isn't
; a disk, WD_NORUNTIME if runtimeN isn't on the system disk or WD_IOERROR
; if a copy or write failed. A failed write scratches what was written.
.proc wdCreate
    jsr wdCheck             ; Sets unit
    cmp #WD_BLANK
    beq L1
    cmp #WD_OK
    beq NB
    cmp #WD_NOTBLANK
    beq NB
    cmp #WD_BADMARKER
    bne DN
NB: lda #WD_NOTBLANK
DN: rts

L1: lda #<runtimeName
    ldx #>runtimeName
    ldy #'p'
    jsr copyFromSys
    bne FL
    lda #<themesName
    ldx #>themesName
    ldy #'s'
    jsr copyFromSys
    beq :+
    cmp #WD_NORUNTIME       ; A system disk with no themes.dat
    bne FL
:   jsr writeMarker
    bne FL
    rts

FL: sta code
    jsr scratchAll
    lda code
    rts
.endproc

; Copies the file named in A/X, of type Y, from the system disk to unit.
; Returns copyFile's code.
.proc copyFromSys
    sta copyName
    stx copyName+1
    sty copyType
    lda sysDevice
    sta copyFrom
    lda unit
    sta copyTo
    jmp copyFile
.endproc

; Writes the marker to unit. Returns a WD_* code, Z set for WD_OK.
.proc writeMarker
    lda #LFN_CMD
    ldx unit
    jsr openCmd
    bcs ND
    lda #<markerName
    ldx #>markerName
    ldy #'s'
    sec
    jsr setName
    lda #LFN_OUT
    ldx unit
    jsr openFile
    bcs IO
    ldx #LFN_CMD
    jsr readStatus
    jsr statusCode
    bne ER
    ldx #LFN_OUT
    jsr CHKOUT
    bcs IO
    ldx #0
:   lda markerData,x
    jsr CHROUT
    inx
    cpx #markerData2-markerData
    bne :-
    jsr CLRCHN
    lda #LFN_OUT
    jsr CLOSE
    ldx #LFN_CMD
    jsr readStatus
    jsr statusCode
    bra ER

ND: lda #WD_NODEVICE
    rts
IO: lda #WD_IOERROR
ER: sta code
    jsr closeAll
    lda code
    rts
.endproc

; Scratches the files wdCreate writes from unit. The result is ignored.
.proc scratchAll
    lda #LFN_CMD
    ldx unit
    ldy #15
    jsr SETLFS
    lda #scratchCmd2-scratchCmd
    ldx #<scratchCmd
    ldy #>scratchCmd
    jsr SETNAM
    jsr OPEN                ; The command goes with the open
    bcs :+
    ldx #LFN_CMD
    jsr readStatus
:   jmp closeAll
.endproc

; Copies runtimeN from the system disk to the work disk if the work disk
; has no file of that name. Its contents aren't compared: N changes with
; them. Returns WD_OK (also in single-disk mode, where there is nothing to
; do), WD_NORUNTIME, or another WD_* code if the copy failed.
.proc wdRefresh
    lda workDevice
    sta unit
    cmp sysDevice
    beq OK
    lda #LFN_CMD
    ldx unit
    jsr openCmd
    bcs ND
    lda #<runtimeName
    ldx #>runtimeName
    ldy #'p'
    clc
    jsr setName
    lda #LFN_IN
    ldx unit
    jsr openFile
    bcs IO
    ldx #LFN_CMD
    jsr readStatus
    sta code
    jsr closeAll
    lda code
    beq OK                  ; It's there
    cmp #$62
    beq CP
    jmp statusCode

CP: lda #<runtimeName
    ldx #>runtimeName
    ldy #'p'
    jmp copyFromSys

OK: lda #WD_OK
    rts
ND: lda #WD_NODEVICE
    rts
IO: jsr closeAll
    lda #WD_IOERROR
    rts
.endproc
