;
; dialog.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The startup dialog (plans/workdisks.md). At a cold start, before the
; editor overlay is loaded, the IDE calls wdStartup, which looks for a
; work disk and shows the dialog only if it can't tell what to use. The
; file screen's W shows it too (EDITOR_LOOP_WORKDISK). The dialog blocks
; until the user picks single-disk mode, a work disk to use or a blank
; disk to make one of, and sets workDevice.
;
; The dialog prints with CHROUT, after setting the KERNAL's 80 by 25
; screen, and keeps its lines to 40 columns. Keys are read from the
; keyboard queue ($D610), as the editor reads them: ASCII.

.include "cbm_kernal.inc"
.include "c64.inc"
.include "asmlib.inc"
.include "workdisk.inc"

.export wdDialog, wdStartup

.import wdCheck, wdCreate, wdRefresh
.ifdef __WORKDISKTEST__
.import wdTestNextKey, wdTestLogCode
.endif

KEYBUF = $d610

; Keys as the keyboard sends them (ASCII)
KEY_RETURN = $0d
KEY_ESC = $1b
KEY_DEL = $14
KEY_D = $64
KEY_SHIFT_D = $44

CH_CLRSCR = 147
UNIT_MARK = 1               ; printStr prints the unit in its place

MSG_ROW = 11                ; The row of the message, below the menu
MSG_NONE = WD_OK            ; No message
MSG_CHECKING = 10
MSG_MAKING = 11

.bss

dlgUnit: .res 1             ; The unit the menu offers
msgIdx: .res 1              ; The message shown (msgTable)
count: .res 1               ; readNumber's digits typed
value: .res 1               ; and their value
tens: .res 1
probe: .res 1               ; wdStartup: the unit checked
found: .res 1               ; the first work disk's unit
numFound: .res 1            ; the work disks found
answered: .res 1            ; the first unit that answered, or 0

.data

screenText:
    .byte "Pascal65 work disk", 13, 13
    .byte "Keep your work on a work disk, apart", 13
    .byte "from this system disk.", 13, 13
    .byte " 1  Single disk: work on this disk", 13
    .byte " 2  Use the work disk on device ", UNIT_MARK, 13
    .byte " 3  Make the blank disk on device ", UNIT_MARK, 13
    .byte "    a work disk", 13
    .byte " D  Change the device", 13, 0

; Indexed by WD_* code, then the busy messages
msgTable:
    .addr 0, mBlank, mNotBlank, mBadMarker, mNoDevice, mNotReady
    .addr mSysDisk, mIoError, mNoRuntime, mBadUnit, mChecking, mMaking
.assert * - msgTable = (MSG_MAKING + 1) * 2, error, "msgTable"

mBlank: .byte "Device ", UNIT_MARK, ": not a work disk", 0
mNotBlank: .byte "Device ", UNIT_MARK, ": not blank", 0
mBadMarker: .byte "Device ", UNIT_MARK, ": bad work disk marker", 0
mNoDevice: .byte "Device ", UNIT_MARK, ": nothing answers", 0
mNotReady: .byte "Device ", UNIT_MARK, ": no disk in the drive", 0
mSysDisk: .byte "Device ", UNIT_MARK, ": the system disk", 0
mIoError: .byte "Device ", UNIT_MARK, ": disk error (full/protected?)", 0
mNoRuntime: .asciiz "The system disk has no runtime file"
mBadUnit: .asciiz "Devices are 8 to 30"
mChecking: .byte "Checking device ", UNIT_MARK, "...", 0
mMaking: .byte "Making a work disk on device ", UNIT_MARK, "...", 0
unitPrompt: .asciiz "Device (8 to 30): "

.code

; The IDE's start: sets workDevice, showing the dialog only when the
; answer isn't plain. Units WD_FIRST_PROBE to WD_LAST_PROBE are checked,
; apart from the system disk's:
;    - one work disk: it is used (and its runtimeN refreshed), with no
;      dialog. If the refresh fails, the dialog shows why.
;    - none, and nothing answers: single-disk mode, with no dialog.
;    - otherwise (two work disks, or a disk that isn't one): the dialog,
;      offering the first unit that answered.
; The IDE's file screen (W) shows the dialog itself, to change the disk.
; Returns WD_OK with the carry clear.
.proc wdStartup
    lda #0
    sta found
    sta numFound
    sta answered
    lda #WD_FIRST_PROBE
    sta probe
L1: lda probe
    cmp sysDevice
    beq NX
    jsr wdCheck
    cmp #WD_NODEVICE
    beq NX
    tax
    lda answered            ; The first unit that answered
    bne :+
    lda probe
    sta answered
:   txa
    bne NX                  ; Not a work disk
    inc numFound
    lda found
    bne NX
    lda probe
    sta found
NX: inc probe
    lda probe
    cmp #WD_LAST_PROBE+1
    bne L1

    lda #MSG_NONE
    sta msgIdx
    lda numFound
    cmp #1
    beq US
    bcs DA                  ; More than one
    lda answered
    bne DA                  ; A disk that isn't a work disk
    lda sysDevice           ; Nothing answered: single-disk mode
    sta workDevice
    bra OK

US: lda found
    sta workDevice
    jsr wdRefresh
    bne RF
OK: lda #WD_OK
    clc
    rts

RF: pha                     ; No work disk after all: say why
    lda sysDevice
    sta workDevice
    pla
    jsr setMsg
    lda found
    bra dialogAt
DA: lda answered
    bra dialogAt
.endproc

; Shows the dialog until the user picks a disk. Sets workDevice: the
; system device for single-disk mode, or the unit of a work disk, which
; has a current runtimeN. It offers the work disk's unit, or
; WD_DEFAULT_UNIT in single-disk mode. Returns WD_OK with the carry clear.
.proc wdDialog
    lda #MSG_NONE
    sta msgIdx
    lda workDevice
    cmp sysDevice
    bne dialogAt
    lda #WD_DEFAULT_UNIT
    ; Fall through
.endproc

; The dialog, offering the unit in A, with the message in msgIdx. The
; IDE may have changed the screen, so it is put back to 80 by 25 first.
.proc dialogAt
    sta dlgUnit
    lda #KEY_ESC
    jsr CHROUT
    lda #'8'
    jsr CHROUT
    jsr clearKeyBuf
L1: jsr draw
L2: jsr getKey
    cmp #'1'
    beq SD
    cmp #'2'
    beq US
    cmp #'3'
    beq MK
    cmp #KEY_D
    beq UN
    cmp #KEY_SHIFT_D
    beq UN
    bra L2

SD: lda sysDevice
    sta workDevice
    bra DN
US: jsr useDisk
    bcs L1
    bra DN
MK: jsr makeDisk
    bcs L1
    bra DN
UN: jsr changeUnit
    bra L1

DN: lda #CH_CLRSCR
    jsr CHROUT
    lda #WD_OK
    clc
    rts
.endproc

; Uses the work disk on dlgUnit. The carry is clear if it is one, with
; workDevice set and runtimeN refreshed, and set with the message if not.
.proc useDisk
    lda #MSG_CHECKING
    jsr busy
    lda dlgUnit
    jsr wdCheck
    bne ER
    lda dlgUnit
    sta workDevice
    jsr wdRefresh
    bne RF
    clc
    rts

RF: pha                     ; No work disk after all
    lda sysDevice
    sta workDevice
    pla
    jmp setMsg

    ; A disk with no marker isn't a work disk, with files or without
ER: cmp #WD_NOTBLANK
    bne :+
    jsr setMsg
    lda #WD_BLANK
    sta msgIdx
    rts                     ; setMsg set the carry
:   jmp setMsg
.endproc

; Makes a work disk of the blank disk on dlgUnit. The carry is clear if
; it did, with workDevice set, and set with the message if not.
.proc makeDisk
    lda #MSG_MAKING
    jsr busy
    lda dlgUnit
    jsr wdCreate
    bne ER
    lda dlgUnit
    sta workDevice
    clc
    rts
ER: jmp setMsg
.endproc

; Asks for a unit and makes it dlgUnit. Esc or no digits leaves it.
.proc changeUnit
    lda #MSG_NONE
    sta msgIdx
    jsr draw                ; Leaves the cursor on the message row
    lda #<unitPrompt
    ldx #>unitPrompt
    jsr printStr
    jsr readNumber
    bcs DN
    cmp #WD_FIRST_UNIT
    bcc BU
    cmp #WD_LAST_UNIT+1
    bcs BU
    sta dlgUnit
DN: rts
BU: lda #WD_BADUNIT
    jmp setMsg
.endproc

; Reads up to two digits, ended by Return. Returns their value in A with
; the carry clear, or the carry set for Esc or Return with no digits.
.proc readNumber
    lda #0
    sta count
    sta value
L1: jsr getKey
    cmp #KEY_RETURN
    beq EN
    cmp #KEY_ESC
    beq CN
    cmp #KEY_DEL
    beq BS
    cmp #'0'
    bcc L1
    cmp #'9'+1
    bcs L1
    ldx count
    cpx #2
    beq L1
    jsr CHROUT
    and #$0f
    pha
    lda value               ; value * 10 + the digit
    asl a
    sta tens
    asl a
    asl a
    clc
    adc tens
    sta value
    pla
    clc
    adc value
    sta value
    inc count
    bra L1

BS: ldx count
    beq L1
    jsr CHROUT
    dec count
    lda value               ; value / 10
    ldx #0
:   cmp #10
    bcc :+
    sbc #10
    inx
    bra :-
:   stx value
    bra L1

EN: lda count
    beq CN
    lda value
    clc
    rts
CN: sec
    rts
.endproc

; Shows the message in A, then the menu with no message
.proc busy
    sta msgIdx
    jsr draw
    lda #MSG_NONE
    sta msgIdx
    rts
.endproc

; Shows the WD_* code in A as the message (the test build logs it). The
; carry is set.
.proc setMsg
.ifdef __WORKDISKTEST__
    jsr wdTestLogCode
.endif
    sta msgIdx
    sec
    rts
.endproc

; Clears the screen and prints the menu and the message. The cursor is
; left on the message row.
.proc draw
    lda #CH_CLRSCR
    jsr CHROUT
    lda #<screenText
    ldx #>screenText
    jsr printStr
    ldx #MSG_ROW
    ldy #0
    clc
    jsr PLOT
    lda msgIdx
    beq DN
    asl a
    tay
    lda msgTable,y
    ldx msgTable+1,y
    jmp printStr
DN: rts
.endproc

; Prints the zero-terminated string in A/X, with dlgUnit in place of
; each UNIT_MARK
.proc printStr
    sta ptr
    stx ptr+1
    ldy #0
L1: lda $ffff,y
ptr = * - 2
    beq DN
    cmp #UNIT_MARK
    bne :+
    phy
    jsr printUnit
    ply
    bra NX
:   jsr CHROUT
NX: iny
    bne L1
DN: rts
.endproc

; Prints dlgUnit in decimal
.proc printUnit
    lda dlgUnit
    ldx #0
:   cmp #10
    bcc :+
    sbc #10
    inx
    bra :-
:   pha
    txa
    beq :+
    ora #'0'
    jsr CHROUT
:   pla
    ora #'0'
    jmp CHROUT
.endproc

.proc clearKeyBuf
    lda #0
:   ldx KEYBUF
    beq :+
    sta KEYBUF
    bra :-
:   rts
.endproc

; Waits for a key and returns it in A
.proc getKey
.ifdef __WORKDISKTEST__
    jmp wdTestNextKey       ; The test's key script (wdtest.s)
.endif
:   ldx KEYBUF
    beq :-
    lda #0
    sta KEYBUF
    txa
    rts
.endproc
