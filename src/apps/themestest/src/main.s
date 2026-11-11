;
; main.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tests the themes overlay. It runs the test build of the overlay (make
; THEMESTEST=1 in src/overlays/themes), which has more jump table entries
; (see themes.inc) and takes the theme screen's keys from a script (see
; themestest.s in the overlay).
;
; Each test (see tests.inc and tests.s) puts its fixtures on the disk as
; themes.dat and themes.def, then runs its steps: calls into the overlay
; and checks of what it left. Then it frees the theme list and checks for
; leaked heap blocks.
;
; When a check fails the test's name, the step and what differed are
; printed, then RESULT: FAIL.

.include "cbm_kernal.inc"
.include "c64.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "editor.inc"
.include "themes.inc"
.include "4510macros.inc"
.include "poisonbss.inc"
.include "tests.inc"

.import initLib, initThemes
.import testInit, testPass, testFail, testMemCheck, testLeakCheck
.import brkCatch, brkCode
.import tests

FILEBUF_SIZE = 1024         ; The largest fixture CHK_FILE can compare

.bss

testNum: .res 1
testRec: .res 2             ; The current test record
stepNum: .res 1
stateAddr: .res 8           ; The overlay's state table (themesTestState)
failMsg: .res 2
failExp: .res 1
failAct: .res 1
cmdBuf: .res 40             ; A DOS command or a filename
cmdLen: .res 1
colorBuf: .res 10           ; loadDefaultTheme's buffer
fileLen: .res 2
filePos: .res 2
fileBuf: .res FILEBUF_SIZE

.data

; isColorUsedInTheme looks at this theme (OP_ISUSED). Its next pointer's low
; byte is 30, which none of its colors use.
fakeTheme:
    .res 16, ' '
    .byte  2, 0, 0, 0
    .byte  3, 0, 0, 0
    .byte  4, 0, 0, 0
    .byte  5, 0, 0, 0
    .byte  6, 0, 0, 0
    .byte  7, 0, 0, 0
    .byte  8, 0, 0, 0
    .byte  9, 0, 0, 0
    .byte 10, 0, 0, 0
    .byte 30, 0, 0, 0       ; THEME::next
.assert * - fakeTheme = .sizeof(THEME), error, "fakeTheme is the wrong size"

strTest: .asciiz "test "
strColon: .asciiz ": "
strStep: .asciiz "step "
strExpected: .asciiz " expected $"
strGot: .asciiz ", got $"
strBrk: .asciiz "brk code $"
strRuntime: .byte 13, "runtime error", 13, 0
strScratchDat: .asciiz "s0:themes.dat"
strScratchDef: .asciiz "s0:themes.def"
strCopyDat: .asciiz "c0:themes.dat="
strCopyDef: .asciiz "c0:themes.def="
strThemesDat: .asciiz "themes.dat"
strRead: .asciiz ",s,r"
msgDos: .asciiz "dos command failed: "
msgBadStep: .asciiz "unknown step"
msgKeys: .asciiz "the key script ran out"
msgNumThemes: .asciiz "numthemes"
msgListLen: .asciiz "length of the list"
msgSel: .asciiz "selectedthemenum"
msgCurrent: .asciiz "currenttheme isn't the selected theme"
msgNoTheme: .asciiz "no such theme"
msgName: .asciiz "name byte"
msgColor: .asciiz "color byte"
msgPal: .asciiz "palette r/g/b"
msgBorder: .asciiz "border color"
msgBg: .asciiz "background color"
msgBuf: .asciiz "buffer byte"
msgUsed: .asciiz "iscolorusedintheme"
msgFixture: .asciiz "fixture missing or too long"
msgFileByte: .asciiz "themes.dat byte"
msgFileLen: .asciiz "themes.dat length"
msgNotEmpty: .asciiz "the list isn't empty"

; The steps (OP_* and CHK_* in tests.inc)
stepProcs:
    .addr opInit, opRead, opWrite, opReset, opFree, opLoad, opScreen
    .addr opResetPal, opSetPal, opIsUsed
    .addr chkCount, chkSel, chkName, chkColor, chkPal, chkBg, chkBuf
    .addr chkFile, chkEmpty

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

    jsr initThemes          ; Load the themes overlay
    jsr themesTestState
    sta ptr4
    stx ptr4+1
    ldy #7
:   lda (ptr4),y
    sta stateAddr,y
    dey
    bpl :-

L1: lda testNum
    asl a
    tax
    lda tests,x
    sta testRec
    lda tests+1,x
    sta testRec+1
    ora testRec
    beq L2
    inc testNum
    jsr runTest
    bra L1

L2: jsr endScreen
    jmp testPass

.code

; Returns the next byte of the steps in A, with the flags set for it. X,
; Y and Z are left alone.
.proc getByte
    lda $ffff               ; The address is set by runTest
opAddr = * - 2
    inc opAddr
    bne :+
    inc opAddr+1
:   cmp #0
    rts
.endproc

; Puts the palette and screen back for the result
.proc endScreen
    jsr themesResetPalette
    lda #6
    sta VIC_BORDERCOLOR
    sta VIC_BG_COLOR0
    lda #CH_CLRSCR
    jsr CHROUT
    lda #13
    jsr CHROUT
    jsr CHROUT
    jsr CHROUT
    jmp CHROUT
.endproc

; Points ptr3 at the current test record
.proc loadRec
    lda testRec
    sta ptr3
    lda testRec+1
    sta ptr3+1
    rts
.endproc

.proc runTest
    lda #<onBrk             ; Report a BRK (a bad free) with the test
    sta brkCatch
    lda #>onBrk
    sta brkCatch+1
    lda #0
    sta stepNum
    jsr setupDisk
    bcs FL
    jsr themesResetPalette

    ; The steps
    clc
    lda testRec
    adc #REC_STEPS
    sta getByte::opAddr
    lda testRec+1
    adc #0
    sta getByte::opAddr+1
    jsr runSteps
    php
    jsr themesFreeThemeList
    lda #0
    sta brkCatch
    sta brkCatch+1
    plp
    bcs FL
    jsr testLeakCheck
    bcc :+
    jsr printTestName
    jmp testFail
:   rts

FL: jsr endScreen
    jsr printFailure
    jmp testFail
.endproc

; Scratches themes.dat and themes.def and copies the test's fixtures to
; them. The carry is set if a DOS command failed.
.proc setupDisk
    lda #<strScratchDat
    ldx #>strScratchDat
    jsr dosCmdStr
    bcs DN
    lda #<strScratchDef
    ldx #>strScratchDef
    jsr dosCmdStr
    bcs DN
    ldy #REC_DAT
    lda #<strCopyDat
    ldx #>strCopyDat
    jsr copyFixture
    bcs DN
    ldy #REC_DEF
    lda #<strCopyDef
    ldx #>strCopyDef
    jmp copyFixture
DN: rts
.endproc

; Copies the fixture at offset Y of the test record, if it has one. A/X is
; the start of the copy command.
.proc copyFixture
    pha
    phx
    jsr loadRec
    lda (ptr3),y
    sta ptr2
    iny
    lda (ptr3),y
    sta ptr2+1
    plx
    pla
    ldy ptr2+1
    bne :+
    ldy ptr2
    bne :+
    clc                     ; NOFILE
    rts
:   jsr startCmd
    lda ptr2
    ldx ptr2+1
    jsr addCmd
    jmp dosCmd
.endproc

; Starts cmdBuf with the zero-terminated string in A/X
.proc startCmd
    ldy #0
    sty cmdLen
    ; Fall through
.endproc

; Adds the zero-terminated string in A/X to cmdBuf
.proc addCmd
    sta ptr4
    stx ptr4+1
    ldy #0
    ldx cmdLen
:   lda (ptr4),y
    beq :+
    sta cmdBuf,x
    inx
    iny
    bne :-
:   stx cmdLen
    rts
.endproc

; Sends the zero-terminated DOS command in A/X
.proc dosCmdStr
    jsr startCmd
    ; Fall through
.endproc

; Sends the DOS command in cmdBuf and reads the drive's status. The carry
; is set if it isn't 00 or 01 (files scratched); then failMsg is set.
.proc dosCmd
    lda cmdLen
    ldx #<cmdBuf
    ldy #>cmdBuf
    jsr SETNAM
    lda #15
    ldx DEVNUM
    ldy #15
    jsr SETLFS
    jsr OPEN
    ldx #15
    jsr CHKIN
    jsr CHRIN
    sta failAct
    jsr CHRIN
    sta failExp
:   jsr READST
    bne :+
    jsr CHRIN
    cmp #13
    bne :-
:   jsr CLRCHN
    lda #15
    jsr CLOSE
    lda failAct
    cmp #'0'
    bne ER
    lda failExp
    cmp #'2'
    bcs ER
    clc
    rts

    ; Show the command and the status
ER: ldx cmdLen
    lda #' '
    sta cmdBuf,x
    inx
    lda failAct
    sta cmdBuf,x
    inx
    lda failExp
    sta cmdBuf,x
    inx
    lda #0
    sta cmdBuf,x
    sta failExp
    sta failAct
    lda #<msgDos
    ldx #>msgDos
    sta failMsg
    stx failMsg+1
    sec
    rts
.endproc

; Runs the steps. The carry is set if one failed.
.proc runSteps
L1: jsr getByte
    bne :+
    clc
    rts
:   inc stepNum
    cmp #OP_LAST+1
    bcc :+
    lda #<msgBadStep
    ldx #>msgBadStep
    jmp failZero
:   asl a
    tax
    jsr callStep
    bcc L1
    rts
.endproc

.proc callStep
    jmp (stepProcs-2,x)
.endproc

; Fails a step: A/X is the message. failExp and failAct must be set.
.proc failValue
    sta failMsg
    stx failMsg+1
    sec
    rts
.endproc

; Fails a step with no values: A/X is the message
.proc failZero
    ldy #0
    sty failExp
    sty failAct
    jmp failValue
.endproc

; Sets failExp to the next byte of the steps and failAct to A. The Z flag
; is set if they are the same.
.proc cmpNext
    sta failAct
    jsr getByte
    sta failExp
    cmp failAct
    rts
.endproc

.proc opInit
    jsr themesInitThemeList
    clc
    rts
.endproc

.proc opRead
    jsr themesReadThemeFile
    clc
    rts
.endproc

.proc opWrite
    jsr themesWriteThemeFile
    clc
    rts
.endproc

.proc opReset
    jsr themesResetToDefaults
    clc
    rts
.endproc

.proc opFree
    jsr themesFreeThemeList
    clc
    rts
.endproc

; Fills the buffer so the bytes loadDefaultTheme doesn't write show
.proc opLoad
    ldx #9
    lda #$ee
:   sta colorBuf,x
    dex
    bpl :-
    lda #<colorBuf
    ldx #>colorBuf
    jsr loadDefaultTheme
    clc
    rts
.endproc

.proc opScreen
    jsr getByte
    pha
    jsr getByte
    tax
    pla
    jsr themesTestSetup
    jsr themesTestRun
    bcs :+
    rts
:   lda #<msgKeys
    ldx #>msgKeys
    jmp failZero
.endproc

.proc opResetPal
    jsr themesResetPalette
    clc
    rts
.endproc

.proc opSetPal
    jsr getByte
    tax
    jsr getByte
    sta $d100,x
    jsr getByte
    sta $d200,x
    jsr getByte
    sta $d300,x
    clc
    rts
.endproc

.proc opIsUsed
    lda #<fakeTheme
    sta ptr1
    lda #>fakeTheme
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr getByte
    jsr themesIsColorUsed
    beq :+                  ; Z set: used
    lda #0
    bra :++
:   lda #1
:   jsr cmpNext
    beq OK
    lda #<msgUsed
    ldx #>msgUsed
    jmp failValue
OK: clc
    rts
.endproc

; Copies the 32-bit variable at offset Y of stateAddr to ptr2. The flags
; are set as isQZero sets them.
.proc loadState
    lda stateAddr,y
    sta ptr4
    lda stateAddr+1,y
    sta ptr4+1
    ldy #3
:   lda (ptr4),y
    sta ptr2,y
    dey
    bpl :-
    ldq ptr2
    jmp isQZero
.endproc

; Returns the byte variable at offset Y of stateAddr in A
.proc loadStateByte
    lda stateAddr,y
    sta ptr4
    lda stateAddr+1,y
    sta ptr4+1
    ldy #0
    lda (ptr4),y
    rts
.endproc

STATE_LIST = 0
STATE_NUM = 2
STATE_SEL = 4
STATE_CURRENT = 6

; Moves ptr2 to the next theme. The flags are set as isQZero sets them.
.proc nextTheme
    ldz #THEME::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    jmp isQZero
.endproc

; Points ptr2 at the theme whose number is the next byte of the steps. The
; carry is set if there is no such theme, and the step fails.
.proc findTheme
    jsr getByte
    ; Fall through
.endproc

; Points ptr2 at the theme whose number is in A, as findTheme does
.proc findThemeN
    sta tmp3
    ldy #STATE_LIST
    jsr loadState
L1: beq NO
    lda tmp3
    beq :+
    dec tmp3
    jsr nextTheme
    bra L1
:   clc
    rts
NO: lda #<msgNoTheme
    ldx #>msgNoTheme
    jmp failZero
.endproc

.proc chkCount
    ldy #STATE_NUM
    jsr loadStateByte
    jsr cmpNext
    beq :+
    lda #<msgNumThemes
    ldx #>msgNumThemes
    jmp failValue
:   lda #0
    sta failAct
    ldy #STATE_LIST
    jsr loadState
L1: beq L2
    inc failAct
    jsr nextTheme
    bra L1
L2: lda failAct
    cmp failExp
    beq :+
    lda #<msgListLen
    ldx #>msgListLen
    jmp failValue
:   clc
    rts
.endproc

.proc chkSel
    ldy #STATE_SEL
    jsr loadStateByte
    jsr cmpNext
    beq :+
    lda #<msgSel
    ldx #>msgSel
    jmp failValue
    ; currentTheme must be that theme
:   lda failExp
    jsr findThemeN
    bcs DN
    ldq ptr2
    stq ptr3
    ldy #STATE_CURRENT
    jsr loadState
    ldx #3
:   lda ptr2,x
    cmp ptr3,x
    bne NE
    dex
    bpl :-
    clc
DN: rts
NE: lda #<msgCurrent
    ldx #>msgCurrent
    jmp failZero
.endproc

.proc chkName
    jsr findTheme
    bcs DN
    ldz #THEME::name
L1: nop
    lda (ptr2),z
    jsr cmpNext             ; Leaves X and Z alone
    bne NE
    inz
    cpz #THEME::name+16
    bne L1
    clc
DN: rts
NE: inz                     ; Skip the rest of the name
    cpz #THEME::name+16
    beq :+
    jsr getByte
    bra NE
:   lda #<msgName
    ldx #>msgName
    jmp failValue
.endproc

.proc chkColor
    jsr findTheme
    bcs DN
    jsr getByte             ; SYNTAXHL_*
    sec
    sbc #1
    asl a
    asl a
    clc
    adc #THEME::colors
    taz
    ldx #4
L1: nop
    lda (ptr2),z
    jsr cmpNext             ; Leaves X and Z alone
    bne NE
    inz
    dex
    bne L1
    clc
DN: rts
NE: dex                     ; Skip the rest of the color
    beq :+
    jsr getByte
    bra NE
:   lda #<msgColor
    ldx #>msgColor
    jmp failValue
.endproc

.proc chkPal
    jsr getByte
    sta tmp3
    tax
    lda $d100,x
    jsr cmpNext
    bne NE
    ldx tmp3
    lda $d200,x
    jsr cmpNext
    bne NE
    ldx tmp3
    lda $d300,x
    jsr cmpNext
    bne NE
    clc
    rts
NE: lda #<msgPal
    ldx #>msgPal
    jmp failValue
.endproc

.proc chkBg
    jsr getByte
    sta failExp
    lda VIC_BORDERCOLOR
    sta failAct
    cmp failExp
    beq :+
    lda #<msgBorder
    ldx #>msgBorder
    jmp failValue
:   lda VIC_BG_COLOR0
    sta failAct
    cmp failExp
    beq :+
    lda #<msgBg
    ldx #>msgBg
    jmp failValue
:   clc
    rts
.endproc

.proc chkBuf
    lda #1
    sta tmp3
L1: ldx tmp3
    lda colorBuf,x
    jsr cmpNext
    bne NE
    inc tmp3
    lda tmp3
    cmp #10
    bne L1
    clc
    rts
NE: inc tmp3                ; Skip the rest of the buffer
    lda tmp3
    cmp #10
    beq :+
    jsr getByte
    bra NE
:   lda #<msgBuf
    ldx #>msgBuf
    jmp failValue
.endproc

; Opens the file named in cmdBuf for reading as file 2
.proc openRead
    lda #<strRead
    ldx #>strRead
    jsr addCmd
    lda cmdLen
    ldx #<cmdBuf
    ldy #>cmdBuf
    jsr SETNAM
    lda #2
    ldx DEVNUM
    ldy #2
    jsr SETLFS
    jsr OPEN
    ldx #2
    jmp CHKIN
.endproc

.proc closeRead
    jsr CLRCHN
    lda #2
    jmp CLOSE
.endproc

; Reads the next byte of file 2 into A. tmp3 is its status: zero if more
; bytes follow, $40 if it was the last one, anything else is an error.
.proc readByte
    jsr CHRIN
    pha
    jsr READST
    sta tmp3
    pla
    rts
.endproc

; CHK_FILE: themes.dat holds the same bytes as the fixture
.proc chkFile
    ; Read the fixture into fileBuf
    ldx #0
    stx cmdLen
:   jsr getByte
    beq :+
    ldx cmdLen
    sta cmdBuf,x
    inc cmdLen
    bra :-
:   jsr openRead
    lda #<fileBuf
    sta ptr3
    lda #>fileBuf
    sta ptr3+1
    lda #0
    sta fileLen
    sta fileLen+1
L1: jsr readByte
    ldy tmp3
    beq :+
    cpy #$40
    bne BF                  ; A read error, or no such file
:   ldy #0
    sta (ptr3),y
    inw ptr3
    inc fileLen
    bne :+
    inc fileLen+1
:   lda tmp3
    bne :+                  ; The last byte
    lda fileLen+1
    cmp #>FILEBUF_SIZE
    bne L1
BF: jsr closeRead
    lda #<msgFixture
    ldx #>msgFixture
    jmp failZero
:   jsr closeRead

    ; Compare themes.dat to it
    lda #<strThemesDat
    ldx #>strThemesDat
    jsr startCmd
    jsr openRead
    lda #<fileBuf
    sta ptr3
    lda #>fileBuf
    sta ptr3+1
    lda #0
    sta filePos
    sta filePos+1
L2: jsr readByte
    sta failAct
    ldy tmp3
    beq :+
    cpy #$40
    bne LN                  ; A read error, or no such file
:   ldy #0
    lda (ptr3),y
    sta failExp
    cmp failAct
    bne NE
    inw ptr3
    inc filePos
    bne :+
    inc filePos+1
:   lda filePos             ; The fixture must end with themes.dat
    cmp fileLen
    bne :+
    lda filePos+1
    cmp fileLen+1
    bne :+
    lda tmp3
    cmp #$40
    bne LN
    jsr closeRead
    clc
    rts
:   lda tmp3
    beq L2

    ; themes.dat is shorter, longer or unreadable. failAct is the bytes
    ; read, low byte only.
LN: jsr closeRead
    lda fileLen
    sta failExp
    lda filePos
    sta failAct
    lda #<msgFileLen
    ldx #>msgFileLen
    jmp failValue

NE: jsr closeRead
    lda #<msgFileByte
    ldx #>msgFileByte
    jmp failValue
.endproc

.proc chkEmpty
    ldy #STATE_LIST
    jsr loadState
    bne NE
    ldy #STATE_CURRENT
    jsr loadState
    bne NE
    ldy #STATE_NUM
    jsr loadStateByte
    bne NE
    clc
    rts
NE: lda #<msgNotEmpty
    ldx #>msgNotEmpty
    jmp failZero
.endproc

.proc printFailure
    jsr printTestName
    lda stepNum
    beq :+
    lda #<strStep
    ldx #>strStep
    jsr printStr
    lda stepNum
    jsr printHex
    lda #<strColon
    ldx #>strColon
    jsr printStr
:   lda failMsg
    ldx failMsg+1
    jsr printStr
    lda failMsg
    cmp #<msgDos
    bne :+
    lda failMsg+1
    cmp #>msgDos
    bne :+
    lda #<cmdBuf
    ldx #>cmdBuf
    jsr printStr
    bra NL
:   lda failExp
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
    jsr loadRec
    ldy #REC_NAME+1
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
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
    jsr endScreen
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
    jsr endScreen
    lda #<strRuntime
    ldx #>strRuntime
    jsr printStr
    lda testNum
    beq :+
    jsr printTestName
:   jmp testFail
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
