;
; main.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tests the workdisk overlay (src/overlays/workdisk, workdisk.inc). The
; program runs from the system disk on unit 8, which has the overlay,
; runtimeN and themes.dat. Unit 9 starts as a blank disk, which the tests
; make a work disk of and then change, so they run in order and each
; leaves the disk as the next one expects. NODEV is a unit nothing
; answers on.
;
; The overlay is its test build (make WORKDISKTEST=1), so the startup
; dialog's tests can type a key script into it and read the codes it
; showed (wdtest.s in the overlay).
;
; When a check fails the test's name and what differed are printed, then
; RESULT: FAIL.

.include "cbm_kernal.inc"
.include "c64.inc"
.include "zeropage.inc"
.include "asm.inc"
.include "asmlib.inc"
.include "workdisk.inc"
.include "4510macros.inc"
.include "poisonbss.inc"

.import initLib, initWorkdisk
.import testInit, testPass, testFail, testMemCheck, testLeakCheck
.import brkCatch, brkCode

SYSUNIT = 8
WORKUNIT = 9
NODEV = 11

; The test's logical files, apart from the overlay's (2, 3, 14 and 15)
LFN_A = 5                   ; A file on one unit
LFN_B = 6                   ; A file on the other
LFN_CMDA = 12               ; The command channel of LFN_A's unit
LFN_CMDB = 13               ; LFN_B's

CHUNK = 128                 ; compareFiles reads this many at a time

; Fails the test proc that uses it if the carry is set
.macro FAILRTS
    .local ok
    bcc ok
    rts
ok:
.endmacro

; Calls an overlay routine with the unit in A and fails unless it
; returns the code
.macro EXPECT routine, unitNum, code
    lda #unitNum
    jsr routine
    ldx #code
    jsr expectCode
    FAILRTS
.endmacro

; Sends a DOS command to a unit and fails unless its status is the one
; given (BCD, such as $01 for files scratched)
.macro DOSCMD unitNum, cmd, st
    .local str, str2
    .pushseg
    .rodata
str: .byte cmd
str2:
    .popseg
    lda #unitNum
    sta tUnit
    lda #<str
    ldx #>str
    ldy #str2-str
    jsr dosCmd
    ldx #st
    jsr expectStatus
    FAILRTS
.endmacro

; Points A/X at a name and Y at its length, for readFile, writeFile and
; compareFiles
.macro NAME n
    .local str, str2
    .pushseg
    .rodata
str: .byte n
str2:
    .popseg
    lda #<str
    ldx #>str
    ldy #str2-str
.endmacro

.define RTNAME .sprintf("runtime%d", ::RT_ABI_VERSION)

; Runs the startup dialog with a key script and fails unless it returns
; and shows the codes in the log given (see expectLog)
.macro DIALOG keys, log
    lda #<keys
    ldx #>keys
    jsr runDialog
    FAILRTS
    lda #<log
    ldx #>log
    jsr expectLog
    FAILRTS
.endmacro

; Fails unless workDevice is the unit
.macro EXPECTDEV unitNum
    lda workDevice
    ldx #unitNum
    jsr expectDevice
    FAILRTS
.endmacro

.bss

testNum: .res 1
failMsg: .res 2
failExp: .res 1
failAct: .res 1
tUnit: .res 1               ; The unit dosCmd, readFile and writeFile use
tStatus: .res 1
nameLen: .res 1
dataPtr: .res 2             ; writeFile's bytes
dataLen: .res 1
fileLen: .res 1             ; The bytes readFile read
fileBuf: .res 256
eofA: .res 1
eofB: .res 1
lenA: .res 1
lenB: .res 1
bufA: .res CHUNK
bufB: .res CHUNK
ranOut: .res 1              ; Set if the dialog's keys ran out
runMode: .res 1             ; wdTestRun's A: 0 the dialog, 1 wdStartup
logLen: .res 1

.data

strTest: .asciiz "test "
strColon: .asciiz ": "
strExpected: .asciiz " expected $"
strGot: .asciiz ", got $"
strBrk: .asciiz "brk code $"
strRuntime: .byte 13, "runtime error", 13, 0
msgCode: .asciiz "code"
msgStatus: .asciiz "dos status"
msgFileLen: .asciiz "file length"
msgFileByte: .asciiz "file byte"
msgDiffer: .asciiz "the copy differs"
msgOpen: .asciiz "a file didn't open"
msgRanOut: .asciiz "the dialog's keys ran out"
msgNoEnd: .asciiz "the dialog returned"
msgLogCount: .asciiz "codes shown"
msgLogCode: .asciiz "code shown"
msgDevice: .asciiz "work device"

; The marker wdCreate must write
goodMarker: .byte WD_MAGIC0, WD_MAGIC1, WD_VERSION, WD_RELEASE, 0
goodMarker2:
; Markers wdCheck must refuse, and one of a later version it must take
badMagic: .byte 'X', WD_MAGIC1, WD_VERSION, 0
badMagic2:
version0: .byte WD_MAGIC0, WD_MAGIC1, 0, 0
version02:
shortMarker: .byte WD_MAGIC0, WD_MAGIC1, WD_VERSION
shortMarker2:
laterMarker: .byte WD_MAGIC0, WD_MAGIC1, WD_VERSION+1, "9.99", 0, 1, 2, 3
laterMarker2:
abc: .byte "abc"
abc2:

.rodata

; The tests, in order: a name and a proc
tests:
    .addr nmSysDisk, tSysDisk
    .addr nmNoDevice, tNoDevice
    .addr nmBlank, tBlank
    .addr nmRefreshSingle, tRefreshSingle
    .addr nmRefreshNoDev, tRefreshNoDev
    .addr nmNoRuntime, tNoRuntime
    .addr nmCreate, tCreate
    .addr nmCreateAgain, tCreateAgain
    .addr nmRefreshPresent, tRefreshPresent
    .addr nmRefreshMissing, tRefreshMissing
    .addr nmBadMagic, tBadMagic
    .addr nmVersion0, tVersion0
    .addr nmShort, tShort
    .addr nmLater, tLater
    .addr nmPrgMarker, tPrgMarker
    .addr nmNoMarker, tNoMarker
    .addr nmNoThemes, tNoThemes
    .addr nmDlgSingle, tDlgSingle
    .addr nmDlgUse, tDlgUse
    .addr nmDlgUnits, tDlgUnits
    .addr nmDlgNoRuntime, tDlgNoRuntime
    .addr nmDlgNotWork, tDlgNotWork
    .addr nmDlgMake, tDlgMake
    .addr nmDlgEnd, tDlgEnd
    .addr nmStartWork, tStartWork
    .addr nmStartRefresh, tStartRefresh
    .addr nmStartNone, tStartNone
    .addr nmStartBlank, tStartBlank
    .addr nmDlgCurrent, tDlgCurrent
    .addr nmUseSys, tUseSys
    .addr nmUseBadUnit, tUseBadUnit
    .addr nmUseNoDev, tUseNoDev
    .addr nmUseWork, tUseWork
    .addr nmUseNoRuntime, tUseNoRuntime
    .addr nmUseNotWork, tUseNotWork
    .addr 0

nmSysDisk: .asciiz "system disk"
nmNoDevice: .asciiz "no device"
nmBlank: .asciiz "blank"
nmRefreshSingle: .asciiz "refresh single disk"
nmRefreshNoDev: .asciiz "refresh no device"
nmNoRuntime: .asciiz "no runtime"
nmCreate: .asciiz "create"
nmCreateAgain: .asciiz "create again"
nmRefreshPresent: .asciiz "refresh present"
nmRefreshMissing: .asciiz "refresh missing"
nmBadMagic: .asciiz "bad magic"
nmVersion0: .asciiz "version 0"
nmShort: .asciiz "short marker"
nmLater: .asciiz "later version"
nmPrgMarker: .asciiz "prg marker"
nmNoMarker: .asciiz "no marker"
nmNoThemes: .asciiz "no themes"
nmDlgSingle: .asciiz "dialog single disk"
nmDlgUse: .asciiz "dialog use"
nmDlgUnits: .asciiz "dialog units"
nmDlgNoRuntime: .asciiz "dialog no runtime"
nmDlgNotWork: .asciiz "dialog not a work disk"
nmDlgMake: .asciiz "dialog make"
nmDlgEnd: .asciiz "dialog script ends"
nmStartWork: .asciiz "startup finds a work disk"
nmStartRefresh: .asciiz "startup refresh fails"
nmStartNone: .asciiz "startup finds nothing"
nmStartBlank: .asciiz "startup finds a blank disk"
nmDlgCurrent: .asciiz "dialog offers the work disk"
nmUseSys: .asciiz "use the system disk"
nmUseBadUnit: .asciiz "use a bad unit"
nmUseNoDev: .asciiz "use no device"
nmUseWork: .asciiz "use a work disk"
nmUseNoRuntime: .asciiz "use no runtime"
nmUseNotWork: .asciiz "use not a work disk"

; The dialog's key scripts (wdtest.s in the overlay), as the keyboard
; sends them: ASCII
K_CR = $0d
K_ESC = $1b
K_DEL = $14
K_D = $64                   ; d
K_SHIFT_D = $44             ; D
K_X = $78                   ; x, which the dialog ignores

; Keys the dialog ignores, then 1
keysSingle: .byte K_X, '4', '0', K_CR, '1', 0
keysUse: .byte '2', 0
; Unit 11 answers nothing, 8 is the system disk, 7 and 31 aren't units,
; Esc and Return alone leave the unit, Del takes a digit back, and unit 9
; is a work disk already
keysUnits:
    .byte K_D, '1', '1', K_CR, '2'
    .byte K_SHIFT_D, '8', K_CR, '3'
    .byte K_D, '7', K_CR, K_D, '3', '1', K_CR
    .byte K_D, '1', K_ESC, K_D, K_CR
    .byte K_D, '1', '2', K_DEL, K_DEL, '9', K_CR, '3', '2', 0
keysUseSingle: .byte '2', '1', 0
keysUseThenSingle: .byte '2', '3', '1', 0
keysMake: .byte '2', '3', 0
keysNone: .byte K_X, 0
; wdStartup's: none (it must not show the dialog), or an answer to it
keysEmpty: .byte 0
keysOne: .byte '1', 0
keysThree: .byte '3', 0

; The codes the dialog must show: the count, then the codes
logNone: .byte 0
logUnits: .byte 5, WD_NODEVICE, WD_SYSDISK, WD_BADUNIT, WD_BADUNIT
    .byte WD_NOTBLANK
logNoRuntime: .byte 1, WD_NORUNTIME
logNotWork: .byte 2, WD_NOTBLANK, WD_NOTBLANK
logMake: .byte 1, WD_BLANK
logNoDevice: .byte 1, WD_NODEVICE

.segment "ENTRY"

main:
    poisonBss               ; Must run before anything writes BSS

    jsr testInit

    ; Disable BASIC ROM
    lda $01
    and #$f8
    ora #$06
    sta $01

    lda #0
    sta testNum
    jsr initLib
    jsr stackInit           ; The memory checks use the runtime stack
    jsr initMemHeap
    jsr testMemCheck

    ; A runtime error (such as running out of memory) fails the test
    tsx
    stx savedStackPtr
    lda #<runtimeErr
    sta exitHandler
    lda #>runtimeErr
    sta exitHandler+1
    lda #<onBrk             ; Report a BRK with the test
    sta brkCatch
    lda #>onBrk
    sta brkCatch+1

    jsr initWorkdisk

L1: lda testNum
    asl a
    asl a
    tax
    lda tests,x
    ora tests+1,x
    beq L2
    lda tests+2,x
    sta ptr1
    lda tests+3,x
    sta ptr1+1
    lda #0
    sta failExp
    sta failAct
    lda sysDevice           ; Single-disk mode unless the test says
    sta workDevice
    jsr callTest
    bcs FL
    inc testNum
    bra L1

L2: lda #0
    sta brkCatch
    sta brkCatch+1
    jsr testLeakCheck
    bcs :+
    jmp testPass
:   jmp testFail

FL: jsr printFailure
    jmp testFail

.code

.proc callTest
    jmp (ptr1)
.endproc

; Fails unless the code in A is the one in X
.proc expectCode
    sta failAct
    stx failExp
    cpx failAct
    beq OK
    lda #<msgCode
    ldx #>msgCode
    jmp failValue
OK: clc
    rts
.endproc

; Fails unless the DOS status in A is the one in X
.proc expectStatus
    sta failAct
    stx failExp
    cpx failAct
    beq OK
    lda #<msgStatus
    ldx #>msgStatus
    jmp failValue
OK: clc
    rts
.endproc

; Fails with the message in A/X, failExp and failAct
.proc failValue
    sta failMsg
    stx failMsg+1
    sec
    rts
.endproc

; Fails with the message in A/X and no values
.proc failZero
    ldy #0
    sty failExp
    sty failAct
    jmp failValue
.endproc

; Reads the status of the command channel open as logical file X, as two
; BCD digits in A, and puts the input back
.proc readStatus
    lda #0
    sta STATUS
    jsr CHKIN
    jsr CHRIN
    asl a
    asl a
    asl a
    asl a
    sta tStatus
    jsr CHRIN
    and #$0f
    ora tStatus
    sta tStatus
:   lda STATUS
    bne :+
    jsr CHRIN
    cmp #13
    bne :-
:   jsr CLRCHN
    lda tStatus
    rts
.endproc

; Opens the command channel of tUnit as logical file tStatus, with the
; command in A/X, Y bytes (Y 0 for none)
.proc openCmd
    sta ptr2
    stx ptr2+1
    sty nameLen
    lda tStatus
    ldx tUnit
    ldy #15
    jsr SETLFS
    lda nameLen
    ldx ptr2
    ldy ptr2+1
    jsr SETNAM
    jmp OPEN
.endproc

; Sends the command in A/X, Y bytes, to tUnit. A is its status.
.proc dosCmd
    pha
    lda #LFN_CMDA
    sta tStatus
    pla
    jsr openCmd
    ldx #LFN_CMDA
    jsr readStatus
    pha
    lda #LFN_CMDA
    jsr CLOSE
    pla
    rts
.endproc

; Opens the file named in A/X, Y bytes, on tUnit as logical file and
; secondary address tStatus. The command channel must be open.
.proc openNamed
    sta ptr2
    stx ptr2+1
    sty nameLen
    lda tStatus
    ldx tUnit
    tay
    jsr SETLFS
    lda nameLen
    ldx ptr2
    ldy ptr2+1
    jsr SETNAM
    jmp OPEN
.endproc

; Writes dataLen bytes at dataPtr to the file named in A/X (Y bytes, with
; its type and ",w") on tUnit. A is the status after the close.
.proc writeFile
    pha
    phx
    phy
    lda #0
    lda #LFN_CMDA
    sta tStatus
    lda #0
    tax
    tay
    jsr openCmd
    lda #LFN_A
    sta tStatus
    ply
    plx
    pla
    jsr openNamed
    ldx #LFN_CMDA
    jsr readStatus
    bne CL
    ldx #LFN_A
    jsr CHKOUT
    lda dataPtr
    sta ptr3
    lda dataPtr+1
    sta ptr3+1
    lda #0
    sta fileLen
:   ldy fileLen
    cpy dataLen
    beq :+
    lda (ptr3),y
    jsr CHROUT
    inc fileLen
    bra :-
:   jsr CLRCHN
    lda #LFN_A
    jsr CLOSE
    ldx #LFN_CMDA
    jsr readStatus
CL: pha
    jsr CLRCHN
    lda #LFN_A
    jsr CLOSE
    lda #LFN_CMDA
    jsr CLOSE
    pla
    rts
.endproc

; Reads up to 255 bytes of the file named in A/X (Y bytes, with its type
; and ",r") on tUnit into fileBuf, fileLen bytes. A is the status after
; the open: 00, or 62 if there is no such file.
.proc readFile
    pha
    phx
    phy
    lda #0
    sta fileLen
    lda #LFN_CMDA
    sta tStatus
    lda #0
    tax
    tay
    jsr openCmd
    lda #LFN_A
    sta tStatus
    ply
    plx
    pla
    jsr openNamed
    ldx #LFN_CMDA
    jsr readStatus
    bne CL
    ldx #LFN_A
    jsr CHKIN
    lda #0
    sta STATUS
L1: jsr CHRIN
    ldy fileLen
    sta fileBuf,y
    inc fileLen
    lda STATUS
    bne :+
    lda fileLen
    cmp #255
    bne L1
:   lda #0
CL: pha
    jsr CLRCHN
    lda #LFN_A
    jsr CLOSE
    lda #LFN_CMDA
    jsr CLOSE
    pla
    rts
.endproc

; Fails unless fileBuf holds the Y bytes at A/X
.proc expectFile
    sta ptr2
    stx ptr2+1
    sty failExp
    lda fileLen
    sta failAct
    cpy fileLen
    beq :+
    lda #<msgFileLen
    ldx #>msgFileLen
    jmp failValue
:   ldy #0
L1: cpy fileLen
    beq OK
    lda (ptr2),y
    sta failExp
    lda fileBuf,y
    sta failAct
    cmp failExp
    bne NE
    iny
    bra L1
OK: clc
    rts
NE: lda #<msgFileByte
    ldx #>msgFileByte
    jmp failValue
.endproc

; Reads up to CHUNK bytes of logical file X into the buffer at ptr2. A
; is the bytes read; the carry is set at the end of the file.
.proc readChunk
    jsr CHKIN
    lda #0
    sta STATUS
    sta tStatus
L1: jsr CHRIN
    ldy tStatus
    sta (ptr2),y
    inc tStatus
    lda STATUS
    bne EF
    lda tStatus
    cmp #CHUNK
    bne L1
    jsr CLRCHN
    lda tStatus
    clc
    rts
EF: jsr CLRCHN
    lda tStatus
    sec
    rts
.endproc

; Fails unless the file named in A/X (Y bytes, with its type and ",r") is
; the same on the system disk and the work disk
.proc compareFiles
    sta ptr4
    stx ptr4+1
    sty dataLen
    lda #SYSUNIT
    sta tUnit
    lda #0
    lda #LFN_CMDA
    sta tStatus
    lda #0
    tax
    tay
    jsr openCmd
    lda #WORKUNIT
    sta tUnit
    lda #0
    lda #LFN_CMDB
    sta tStatus
    lda #0
    tax
    tay
    jsr openCmd

    lda #SYSUNIT
    sta tUnit
    lda #LFN_A
    sta tStatus
    lda ptr4
    ldx ptr4+1
    ldy dataLen
    jsr openNamed
    ldx #LFN_CMDA
    jsr readStatus
    bne NO
    lda #WORKUNIT
    sta tUnit
    lda #LFN_B
    sta tStatus
    lda ptr4
    ldx ptr4+1
    ldy dataLen
    jsr openNamed
    ldx #LFN_CMDB
    jsr readStatus
    bne NO

L1: lda #<bufA
    sta ptr2
    lda #>bufA
    sta ptr2+1
    ldx #LFN_A
    jsr readChunk
    sta lenA
    lda #0
    rol a
    sta eofA
    lda #<bufB
    sta ptr2
    lda #>bufB
    sta ptr2+1
    ldx #LFN_B
    jsr readChunk
    sta lenB
    lda #0
    rol a
    sta eofB
    lda lenA
    cmp lenB
    bne DF
    lda eofA
    cmp eofB
    bne DF
    ldy #0
:   lda bufA,y
    cmp bufB,y
    bne DF
    iny
    cpy lenA
    bne :-
    lda eofA
    beq L1
    jsr closeCompare
    clc
    rts

NO: jsr closeCompare
    lda #<msgOpen
    ldx #>msgOpen
    jmp failZero
DF: jsr closeCompare
    lda #<msgDiffer
    ldx #>msgDiffer
    jmp failZero
.endproc

.proc closeCompare
    jsr CLRCHN
    lda #LFN_A
    jsr CLOSE
    lda #LFN_B
    jsr CLOSE
    lda #LFN_CMDA
    jsr CLOSE
    lda #LFN_CMDB
    jmp CLOSE
.endproc

; Replaces the marker on the work disk with the Y bytes at A/X, written
; as name n
.macro MARKER data, len, n
    DOSCMD WORKUNIT, "s0:p65work", $01
    lda #<data
    sta dataPtr
    lda #>data
    sta dataPtr+1
    lda #len
    sta dataLen
    lda #WORKUNIT
    sta tUnit
    NAME n
    jsr writeFile
    ldx #0
    jsr expectStatus
    FAILRTS
.endmacro

; The tests. Each returns with the carry set if it failed.

.proc tSysDisk
    EXPECT wdCheck, SYSUNIT, WD_SYSDISK
    rts
.endproc

.proc tNoDevice
    EXPECT wdCheck, NODEV, WD_NODEVICE
    EXPECT wdCreate, NODEV, WD_NODEVICE
    rts
.endproc

.proc tBlank
    EXPECT wdCheck, WORKUNIT, WD_BLANK
    rts
.endproc

; In single-disk mode there is nothing to refresh, and nothing is
; written to unit 9
.proc tRefreshSingle
    jsr wdRefresh
    ldx #WD_OK
    jsr expectCode
    FAILRTS
    lda #WORKUNIT
    sta tUnit
    NAME {RTNAME, ",p,r"}
    jsr readFile
    ldx #$62
    jmp expectStatus
.endproc

.proc tRefreshNoDev
    lda #NODEV
    sta workDevice
    jsr wdRefresh
    ldx #WD_NODEVICE
    jmp expectCode
.endproc

; With no runtimeN on the system disk wdCreate fails and leaves the disk
; blank
.proc tNoRuntime
    DOSCMD SYSUNIT, {"r0:x", RTNAME, "=", RTNAME}, $00
    lda #WORKUNIT
    jsr wdCreate
    pha
    DOSCMD SYSUNIT, {"r0:", RTNAME, "=x", RTNAME}, $00
    pla
    ldx #WD_NORUNTIME
    jsr expectCode
    FAILRTS
    EXPECT wdCheck, WORKUNIT, WD_BLANK
    rts
.endproc

.proc tCreate
    EXPECT wdCreate, WORKUNIT, WD_OK
    NAME {RTNAME, ",p,r"}
    jsr compareFiles
    FAILRTS
    NAME "themes.dat,s,r"
    jsr compareFiles
    FAILRTS
    lda #WORKUNIT
    sta tUnit
    NAME "p65work,s,r"
    jsr readFile
    ldx #0
    jsr expectStatus
    FAILRTS
    lda #<goodMarker
    ldx #>goodMarker
    ldy #goodMarker2-goodMarker
    jsr expectFile
    FAILRTS
    EXPECT wdCheck, WORKUNIT, WD_OK
    rts
.endproc

.proc tCreateAgain
    EXPECT wdCreate, WORKUNIT, WD_NOTBLANK
    rts
.endproc

; A runtimeN already on the work disk isn't replaced, whatever it holds
.proc tRefreshPresent
    DOSCMD WORKUNIT, {"s0:", RTNAME}, $01
    lda #<abc
    sta dataPtr
    lda #>abc
    sta dataPtr+1
    lda #abc2-abc
    sta dataLen
    lda #WORKUNIT
    sta tUnit
    NAME {RTNAME, ",p,w"}
    jsr writeFile
    ldx #0
    jsr expectStatus
    FAILRTS
    lda #WORKUNIT
    sta workDevice
    jsr wdRefresh
    ldx #WD_OK
    jsr expectCode
    FAILRTS
    lda #WORKUNIT
    sta tUnit
    NAME {RTNAME, ",p,r"}
    jsr readFile
    lda #<abc
    ldx #>abc
    ldy #abc2-abc
    jmp expectFile
.endproc

.proc tRefreshMissing
    DOSCMD WORKUNIT, {"s0:", RTNAME}, $01
    lda #WORKUNIT
    sta workDevice
    jsr wdRefresh
    ldx #WD_OK
    jsr expectCode
    FAILRTS
    NAME {RTNAME, ",p,r"}
    jmp compareFiles
.endproc

.proc tBadMagic
    MARKER badMagic, badMagic2-badMagic, "p65work,s,w"
    EXPECT wdCheck, WORKUNIT, WD_BADMARKER
    EXPECT wdCreate, WORKUNIT, WD_NOTBLANK
    rts
.endproc

.proc tVersion0
    MARKER version0, version02-version0, "p65work,s,w"
    EXPECT wdCheck, WORKUNIT, WD_BADMARKER
    rts
.endproc

.proc tShort
    MARKER shortMarker, shortMarker2-shortMarker, "p65work,s,w"
    EXPECT wdCheck, WORKUNIT, WD_BADMARKER
    rts
.endproc

.proc tLater
    MARKER laterMarker, laterMarker2-laterMarker, "p65work,s,w"
    EXPECT wdCheck, WORKUNIT, WD_OK
    rts
.endproc

.proc tPrgMarker
    MARKER goodMarker, goodMarker2-goodMarker, "p65work,p,w"
    EXPECT wdCheck, WORKUNIT, WD_BADMARKER
    rts
.endproc

; Files and no marker: not blank
.proc tNoMarker
    DOSCMD WORKUNIT, "s0:p65work", $01
    EXPECT wdCheck, WORKUNIT, WD_NOTBLANK
    EXPECT wdCreate, WORKUNIT, WD_NOTBLANK
    rts
.endproc

; A system disk with no themes.dat makes a work disk without one
.proc tNoThemes
    DOSCMD WORKUNIT, "s0:*", $01
    EXPECT wdCheck, WORKUNIT, WD_BLANK
    DOSCMD SYSUNIT, "r0:xthemes.dat=themes.dat", $00
    lda #WORKUNIT
    jsr wdCreate
    pha
    DOSCMD SYSUNIT, "r0:themes.dat=xthemes.dat", $00
    pla
    ldx #WD_OK
    jsr expectCode
    FAILRTS
    lda #WORKUNIT
    sta tUnit
    NAME "themes.dat,s,r"
    jsr readFile
    ldx #$62
    jsr expectStatus
    FAILRTS
    NAME {RTNAME, ",p,r"}
    jsr compareFiles
    FAILRTS
    EXPECT wdCheck, WORKUNIT, WD_OK
    rts
.endproc

; The startup dialog's tests. Unit 9 starts as tNoThemes left it, a work
; disk.

; Runs the dialog with the key script in A/X. ranOut and the carry are
; set if the keys ran out before it returned.
.proc startDialog
    ldy #0
    sty runMode
    ; Fall through
.endproc

; Runs the dialog (runMode 0) or wdStartup (runMode 1) with the key
; script in A/X. ranOut and the carry are set if the keys ran out before
; it returned.
.proc startRun
    jsr wdTestSetup
    lda runMode
    jsr wdTestRun
    lda #0
    rol a
    sta ranOut
    lsr a
    rts
.endproc

; Fails if ranOut is set
.proc checkRanOut
    lda ranOut
    bne :+
    clc
    rts
:   lda #<msgRanOut
    ldx #>msgRanOut
    jmp failZero
.endproc

; Runs wdStartup with the key script in A/X. ranOut and the carry are
; set if the keys ran out before it returned.
.proc startStartup
    pha
    lda #1
    sta runMode
    pla
    jmp startRun
.endproc

; Runs wdStartup with the key script in A/X and fails if the keys ran out
.proc runStartup
    jsr startStartup
    jmp checkRanOut
.endproc

; Runs the dialog with the key script in A/X and fails if the keys ran out
.proc runDialog
    jsr startDialog
    jmp checkRanOut
.endproc

; Fails unless the codes the dialog showed are the ones at A/X: the
; count, then the codes
.proc expectLog
    sta ptr3
    stx ptr3+1
    jsr wdTestState
    sta ptr4
    stx ptr4+1
    ldy #0
    lda (ptr3),y
    sta logLen
    sta failExp
    lda (ptr4),y
    sta failAct
    cmp logLen
    bne LN
L1: cpy logLen
    beq OK
    iny
    lda (ptr3),y
    sta failExp
    lda (ptr4),y
    sta failAct
    cmp failExp
    beq L1
    lda #<msgLogCode
    ldx #>msgLogCode
    jmp failValue
OK: clc
    rts
LN: lda #<msgLogCount
    ldx #>msgLogCount
    jmp failValue
.endproc

; Fails unless the device in A is the one in X
.proc expectDevice
    sta failAct
    stx failExp
    cpx failAct
    beq OK
    lda #<msgDevice
    ldx #>msgDevice
    jmp failValue
OK: clc
    rts
.endproc

.proc tDlgSingle
    DIALOG keysSingle, logNone
    EXPECTDEV SYSUNIT
    rts
.endproc

; Using a work disk refreshes its runtimeN
.proc tDlgUse
    DOSCMD WORKUNIT, {"s0:", RTNAME}, $01
    DIALOG keysUse, logNone
    EXPECTDEV WORKUNIT
    NAME {RTNAME, ",p,r"}
    jmp compareFiles
.endproc

.proc tDlgUnits
    DIALOG keysUnits, logUnits
    EXPECTDEV WORKUNIT
    rts
.endproc

; A work disk whose runtimeN can't be refreshed isn't used
.proc tDlgNoRuntime
    DOSCMD WORKUNIT, {"s0:", RTNAME}, $01
    DOSCMD SYSUNIT, {"r0:x", RTNAME, "=", RTNAME}, $00
    lda #<keysUseSingle
    ldx #>keysUseSingle
    jsr startDialog
    DOSCMD SYSUNIT, {"r0:", RTNAME, "=x", RTNAME}, $00
    jsr checkRanOut
    FAILRTS
    lda #<logNoRuntime
    ldx #>logNoRuntime
    jsr expectLog
    FAILRTS
    EXPECTDEV SYSUNIT
    rts
.endproc

; A disk with files and no marker can't be used or made a work disk
.proc tDlgNotWork
    DOSCMD WORKUNIT, "s0:*", $01
    lda #<abc
    sta dataPtr
    lda #>abc
    sta dataPtr+1
    lda #abc2-abc
    sta dataLen
    lda #WORKUNIT
    sta tUnit
    NAME "abc,s,w"
    jsr writeFile
    ldx #0
    jsr expectStatus
    FAILRTS
    DIALOG keysUseThenSingle, logNotWork
    EXPECTDEV SYSUNIT
    rts
.endproc

; A blank disk can't be used, but can be made a work disk
.proc tDlgMake
    DOSCMD WORKUNIT, "s0:*", $01
    DIALOG keysMake, logMake
    EXPECTDEV WORKUNIT
    EXPECT wdCheck, WORKUNIT, WD_OK
    NAME {RTNAME, ",p,r"}
    jmp compareFiles
.endproc

; wdStartup's tests. Units 10 and 11 answer nothing, so only unit 9 can
; be found. A test that must not see the dialog gives it no keys.

; Starts wdStartup with the key script given, and fails if the keys run
; out, or the codes shown or the work device differ
.macro STARTUP keys, log, unitNum
    lda #<keys
    ldx #>keys
    jsr runStartup
    FAILRTS
    lda #<log
    ldx #>log
    jsr expectLog
    FAILRTS
    EXPECTDEV unitNum
.endmacro

; The one work disk is used with no dialog, and its runtimeN refreshed
.proc tStartWork
    DOSCMD WORKUNIT, {"s0:", RTNAME}, $01
    STARTUP keysEmpty, logNone, WORKUNIT
    NAME {RTNAME, ",p,r"}
    jmp compareFiles
.endproc

; A work disk whose runtimeN can't be refreshed shows the dialog, saying
; why
.proc tStartRefresh
    DOSCMD WORKUNIT, {"s0:", RTNAME}, $01
    DOSCMD SYSUNIT, {"r0:x", RTNAME, "=", RTNAME}, $00
    lda #<keysOne
    ldx #>keysOne
    jsr startStartup
    DOSCMD SYSUNIT, {"r0:", RTNAME, "=x", RTNAME}, $00
    jsr checkRanOut
    FAILRTS
    lda #<logNoRuntime
    ldx #>logNoRuntime
    jsr expectLog
    FAILRTS
    EXPECTDEV SYSUNIT
    rts
.endproc

; Nothing answers but the system disk: single-disk mode with no dialog.
; Unit 9 is made blank and taken for the system disk, so it isn't
; checked: if it were, the dialog would show.
.proc tStartNone
    DOSCMD WORKUNIT, "s0:*", $01
    lda #WORKUNIT
    sta sysDevice
    lda #<keysEmpty
    ldx #>keysEmpty
    jsr startStartup
    lda #SYSUNIT
    sta sysDevice
    jsr checkRanOut
    FAILRTS
    EXPECTDEV WORKUNIT      ; The system device it was given
    rts
.endproc

; A blank disk shows the dialog, offering its unit
.proc tStartBlank
    STARTUP keysThree, logNone, WORKUNIT
    EXPECT wdCheck, WORKUNIT, WD_OK
    rts
.endproc

; Opened from the IDE with a work disk, the dialog offers its unit
.proc tDlgCurrent
    lda #NODEV
    sta workDevice
    DIALOG keysUseSingle, logNoDevice
    EXPECTDEV SYSUNIT
    rts
.endproc

; The dialog doesn't return until a disk is picked
.proc tDlgEnd
    lda #<keysNone
    ldx #>keysNone
    jsr startDialog
    bcc :+
    clc
    rts
:   lda #<msgNoEnd
    ldx #>msgNoEnd
    jmp failZero
.endproc

; wdUse's tests: the command-line compiler's unit prefix. Each starts
; with workDevice the work disk's unit, to see wdUse put it back. Unit 9
; is a work disk.

; The system disk's unit is single-disk mode
.proc tUseSys
    lda #WORKUNIT
    sta workDevice
    EXPECT wdUse, SYSUNIT, WD_OK
    EXPECTDEV SYSUNIT
    rts
.endproc

.proc tUseBadUnit
    lda #WORKUNIT
    sta workDevice
    EXPECT wdUse, 7, WD_BADUNIT
    EXPECTDEV SYSUNIT
    EXPECT wdUse, 31, WD_BADUNIT
    EXPECT wdUse, 0, WD_BADUNIT
    EXPECTDEV SYSUNIT
    rts
.endproc

.proc tUseNoDev
    lda #WORKUNIT
    sta workDevice
    EXPECT wdUse, NODEV, WD_NODEVICE
    EXPECTDEV SYSUNIT
    rts
.endproc

; The work disk is used and its runtimeN refreshed
.proc tUseWork
    DOSCMD WORKUNIT, {"s0:", RTNAME}, $01
    EXPECT wdUse, WORKUNIT, WD_OK
    EXPECTDEV WORKUNIT
    NAME {RTNAME, ",p,r"}
    jmp compareFiles
.endproc

; A work disk whose runtimeN can't be refreshed isn't used
.proc tUseNoRuntime
    DOSCMD WORKUNIT, {"s0:", RTNAME}, $01
    DOSCMD SYSUNIT, {"r0:x", RTNAME, "=", RTNAME}, $00
    lda #WORKUNIT
    sta workDevice
    jsr wdUse
    pha
    DOSCMD SYSUNIT, {"r0:", RTNAME, "=x", RTNAME}, $00
    pla
    ldx #WD_NORUNTIME
    jsr expectCode
    FAILRTS
    EXPECTDEV SYSUNIT
    rts
.endproc

; A disk with files and no marker, and a blank disk, aren't work disks
.proc tUseNotWork
    DOSCMD WORKUNIT, "s0:p65work", $01
    lda #WORKUNIT
    sta workDevice
    EXPECT wdUse, WORKUNIT, WD_NOTBLANK
    EXPECTDEV SYSUNIT
    DOSCMD WORKUNIT, "s0:*", $01
    EXPECT wdUse, WORKUNIT, WD_BLANK
    EXPECTDEV SYSUNIT
    rts
.endproc

.proc printFailure
    jsr printTestName
    lda failMsg
    ldx failMsg+1
    jsr printStr
    lda failExp
    ora failAct
    beq NL
    lda #<strExpected
    ldx #>strExpected
    jsr printStr
    lda failExp
    jsr printHex
    lda #<strGot
    ldx #>strGot
    jsr printStr
    lda failAct
    jsr printHex
NL: lda #13
    jmp CHROUT
.endproc

; Prints "test <name>: "
.proc printTestName
    lda #<strTest
    ldx #>strTest
    jsr printStr
    lda testNum
    asl a
    asl a
    tax
    lda tests+1,x
    pha
    lda tests,x
    plx
    jsr printStr
    lda #<strColon
    ldx #>strColon
    jmp printStr
.endproc

; A BRK during a test ends up here (see brkCatch in testresult.s)
.proc onBrk
    lda #0
    sta brkCatch
    sta brkCatch+1
    jsr printTestName
    lda #<strBrk
    ldx #>strBrk
    jsr printStr
    lda brkCode
    jsr printHex
    lda #13
    jsr CHROUT
    jmp testFail
.endproc

; A runtime error ends up here (see exitHandler)
.proc runtimeErr
    lda #<strRuntime
    ldx #>strRuntime
    jsr printStr
    jsr printTestName
    jmp testFail
.endproc

; Prints the zero-terminated string in A/X
.proc printStr
    sta ptr4
    stx ptr4+1
    ldy #0
:   lda (ptr4),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   rts
.endproc

; Prints A as two hex digits
.proc printHex
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr digit
    pla
    and #$0f
digit:
    cmp #10
    bcc :+
    adc #'a'-10-1           ; The carry is set
    jmp CHROUT
:   adc #'0'
    jmp CHROUT
.endproc
