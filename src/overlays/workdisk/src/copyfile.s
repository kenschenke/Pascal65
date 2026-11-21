;
; copyfile.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Copies a file from one unit to another. No DOS command copies between
; units (C: works within one), so it reads a block from one and writes it
; to the other, with both files open. The two units must differ: a DOS
; command or a command channel's close on one unit leaves the other's
; files alone (plans/workdisks.md, phase 0).

.include "cbm_kernal.inc"
.include "c64.inc"
.include "workdisk.inc"

.export copyFile, copyFrom, copyTo, copyName, copyType

.import openCmd, readStatus, closeAll, openFile, statusCode, setName
.include "wdio.inc"

BLOCK_SIZE = 254            ; A disk block's data

.bss

copyFrom: .res 1            ; The unit read
copyTo: .res 1              ; The unit written
copyName: .res 2            ; The file's name, zero-terminated
copyType: .res 1            ; 'p' or 's'
count: .res 1               ; The bytes in buffer
pos: .res 1                 ; The next byte writeBlock writes
eof: .res 1                 ; Non-zero once the last byte is read
code: .res 1
buffer: .res BLOCK_SIZE

.code

; Copies the file named copyName, of type copyType, from unit copyFrom to
; unit copyTo, which must not have a file of that name. Returns a WD_*
; code in A, with Z set for WD_OK. A file that isn't on copyFrom is
; WD_NORUNTIME, which the caller turns into its own code. Every file is
; closed afterwards. A copy that fails may leave part of the file on
; copyTo.
.proc copyFile
    lda #LFN_CMD
    ldx copyFrom
    jsr openCmd
    bcs :+
    lda #LFN_CMD2
    ldx copyTo
    jsr openCmd
    bcc :++
:   jmp ND
:

    ; The file to read
    lda copyName
    ldx copyName+1
    ldy copyType
    clc                     ; Reading
    jsr setName
    lda #LFN_IN
    ldx copyFrom
    jsr openFile
    bcs IO
    ldx #LFN_CMD
    jsr readStatus
    cmp #$62
    bne :+
    lda #WD_NORUNTIME
    bra ER
:   jsr statusCode
    bne ER

    ; The file to write
    lda copyName
    ldx copyName+1
    ldy copyType
    sec                     ; Writing
    jsr setName
    lda #LFN_OUT
    ldx copyTo
    jsr openFile
    bcs IO
    ldx #LFN_CMD2
    jsr readStatus
    jsr statusCode
    bne ER

    lda #0
    sta eof
L1: jsr readBlock
    bcs IO
    jsr writeBlock
    bcs IO
    lda eof
    beq L1

    ; The write's status comes once the file is closed
    jsr CLRCHN
    lda #LFN_IN
    jsr CLOSE
    lda #LFN_OUT
    jsr CLOSE
    ldx #LFN_CMD2
    jsr readStatus
    jsr statusCode
    bne ER
    jsr closeAll
    lda #WD_OK
    rts

ND: lda #WD_NODEVICE
    bra ER
IO: lda #WD_IOERROR
ER: sta code
    jsr closeAll
    lda code
    rts
.endproc

; Reads up to BLOCK_SIZE bytes into buffer. count is the bytes read and
; eof is set at the end of the file. The carry is set on a read error.
.proc readBlock
    ldx #LFN_IN
    jsr CHKIN
    bcs ER
    lda #0
    sta count
    sta STATUS
L1: jsr CHRIN
    ldy count
    sta buffer,y
    inc count
    lda STATUS
    beq :+
    cmp #$40
    bne ER                  ; Anything but the end of the file
    sta eof
    bra DN
:   lda count
    cmp #BLOCK_SIZE
    bne L1
DN: jsr CLRCHN
    clc
    rts
ER: jsr CLRCHN
    sec
    rts
.endproc

; Writes the count bytes in buffer. The carry is set on a write error.
.proc writeBlock
    ldx #LFN_OUT
    jsr CHKOUT
    bcs ER
    lda #0
    sta pos
    sta STATUS
L1: ldy pos
    lda buffer,y
    jsr CHROUT
    lda STATUS
    bne ER
    inc pos
    lda pos
    cmp count
    bne L1
    jsr CLRCHN
    clc
    rts
ER: jsr CLRCHN
    sec
    rts
.endproc
