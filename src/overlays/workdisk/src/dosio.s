;
; dosio.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The overlay's own file and command channel routines. asmlib's DOS
; commands are for the work disk and open and close the command channel
; for each one. These take the unit, keep a command channel open while
; files are open on it and read its status after each open.
;
; A command channel's close closes every file open on its unit, so each
; is opened before the unit's files and closed after them.

.include "cbm_kernal.inc"
.include "c64.inc"
.include "workdisk.inc"

.export openCmd, readStatus, closeAll, openFile, statusCode
.export nameBuf

.include "wdio.inc"

.bss

cmdLfn: .res 1
status: .res 1
left: .res 1
nameLen: .res 1
nameBuf: .res 24            ; A file name, its type and its mode

.code

; Opens the command channel of the unit in X as logical file A, sending
; no command. The carry is set if nothing answers on the unit; the file
; is then closed.
.proc openCmd
    sta cmdLfn
    ldy #15
    jsr SETLFS
    lda #0
    tax
    tay
    jsr SETNAM
    jsr OPEN
    bcs ER
    lda #0
    sta STATUS
    ldx cmdLfn              ; The KERNAL sends nothing until it talks
    jsr CHKIN
    bcs ER
    lda STATUS
    bmi ER                  ; Device not present
    jsr CLRCHN
    clc
    rts
ER: jsr CLRCHN
    lda cmdLfn
    jsr CLOSE
    sec
    rts
.endproc

; Reads the status of the command channel open as logical file X. The
; status is in A as two BCD digits, such as $62 for 62 (file not found).
; If it can't be read, A is $ff.
.proc readStatus
    lda #0                  ; The KERNAL reads nothing while it's set
    sta STATUS
    jsr CHKIN
    bcs ER
    jsr CHRIN               ; The first digit
    asl a
    asl a
    asl a
    asl a
    sta status
    jsr CHRIN               ; The second
    and #$0f
    ora status
    sta status
    lda #40                 ; The rest of the line
    sta left
:   lda STATUS
    bne DN
    jsr CHRIN
    cmp #13
    beq DN
    dec left
    bne :-
DN: jsr CLRCHN
    lda STATUS
    and #$80
    bne ER
    lda status
    rts
ER: jsr CLRCHN
    lda #$ff
    rts
.endproc

; Turns the status in A into a WD_* code: 00 is WD_OK, 74 (drive not
; ready) WD_NOTREADY and anything else WD_IOERROR. The Z flag is set for
; WD_OK.
.proc statusCode
    cmp #0
    beq DN
    cmp #$74
    beq NR
    lda #WD_IOERROR
    rts
NR: lda #WD_NOTREADY
DN: rts
.endproc

; Opens a file on the unit in X as logical file A, with the secondary
; address A too. The name is in nameBuf, Y bytes long. The carry is set
; if the KERNAL couldn't open it.
.proc openFile
    sty nameLen
    tay                     ; Secondary address = logical file
    jsr SETLFS
    lda nameLen
    ldx #<nameBuf
    ldy #>nameBuf
    jsr SETNAM
    jmp OPEN
.endproc

; Closes every file the overlay opens, its files before its command
; channels, and puts the input and output back
.proc closeAll
    jsr CLRCHN
    lda #LFN_IN
    jsr CLOSE
    lda #LFN_OUT
    jsr CLOSE
    lda #LFN_CMD2
    jsr CLOSE
    lda #LFN_CMD
    jmp CLOSE
.endproc
