;
; start.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The entry point of every runtime test suite, and the chain to the next.
;
; Each suite is its own PRG, so the runtime's tests never have to fit in
; one program. A suite exports suiteMain, which runs its tests and returns
; if they all pass. A check that fails calls testFail (testresult.s), which
; prints RESULT: FAIL and returns from runSuite, so the chain stops there
; with the failure on the screen.
;
; The Makefile writes each suite's name and the next suite's (suiteName,
; nextSuite) to a file of its own (suiteinfo.s). A suite that passes loads
; the next with a loader it copies to CHAIN_LOADER (rtt.inc), which jumps
; to the new PRG's entry. The last suite prints RESULT: PASS. Only the
; first PRG is started by BASIC, and each one starts and chains with the
; stack as BASIC's SYS left it, so the last one returns to BASIC.
;
; The PRGs share a state block at RTT_STATE. The loader sets rttChainFlag
; just before it jumps to the next PRG. A PRG started any other way, by
; BASIC or the emulator, is the first: it saves BASIC's zero page, which
; the runtime code under test uses, and the chain puts it back at the end.
;
; With COVERAGE defined, the suite runs against instrumented copies of the
; runtime files and saves the coverage map as covName (see the Makefile).

.include "cbm_kernal.inc"
.include "rtt.inc"
.include "poisonbss.inc"

.import suiteMain, suiteName, nextSuite
.import testInit, testPass, testRestoreBrk
.import printZ, printCR, printDec8, rttTest, rttStep
.import rteCatch
.ifdef COVERAGE
.import covName
.endif

.bss

passed: .res 1              ; Non-zero once suiteMain returns

.data

strPassed: .asciiz ": passed"
strSuites: .asciiz " suites passed"

.segment "ENTRY"

.proc entry
    poisonBss
    lda #0
    sta passed
    sta rteCatch+1
    lda rttChainFlag
    cmp #CHAIN_MAGIC1
    bne :+
    lda rttChainFlag+1
    cmp #CHAIN_MAGIC2
    beq CH

    ; The first suite: keep BASIC's zero page
:   ldx #RTT_ZP_SIZE-1
:   lda RTT_ZP_FIRST,x
    sta rttZpSave,x
    dex
    bpl :-
    lda #0
    sta rttSuites
    lda #147                ; Clear the screen
    jsr CHROUT
    ldx #4                  ; testPass, testFail and READY use the first
:   jsr printCR             ; four rows
    dex
    bne :-
    bra RN

CH: lda #0
    sta rttChainFlag
    sta rttChainFlag+1

RN: jsr runSuite
    lda passed
    beq DN                  ; testFail has printed the result
    inc rttSuites
    lda nextSuite
    beq :+
    jmp chainNext
:   lda rttSuites
    jsr printDec8
    LDAX strSuites
    jsr printZ
    jsr printCR
    jsr testPass

DN: jsr restoreZp
    rts
.endproc

.code

; testFail returns from this routine (testInit keeps the stack pointer)
.proc runSuite
    jsr testInit
    lda #0                  ; A suite that doesn't number its tests
    sta rttTest             ; fails at test 0 step 0
    sta rttStep
.ifdef COVERAGE
    jsr covInstall
.endif
    jsr suiteMain
.ifdef COVERAGE
    jsr covSave
.endif
    LDAX suiteName
    jsr printZ
    LDAX strPassed
    jsr printZ
    jsr printCR
    lda #1
    sta passed
    jmp testRestoreBrk
.endproc

.proc restoreZp
    ldx #RTT_ZP_SIZE-1
:   lda rttZpSave,x
    sta RTT_ZP_FIRST,x
    dex
    bpl :-
    rts
.endproc

; Copies the loader and the next suite's name to CHAIN_LOADER, puts BASIC's
; zero page back for the KERNAL's LOAD and jumps to the loader. The stack
; is as it was when this PRG started.
.proc chainNext
    ldx #0
:   lda loader,x
    sta CHAIN_LOADER,x
    inx
    cpx #LOADER_SIZE
    bne :-
    ldy #0
:   lda nextSuite,y
    sta CHAIN_LOADER+LOADER_SIZE,y
    beq :+
    iny
    bne :-
:   tya
    sta CHAIN_LOADER+NAMELEN    ; The name's length
    jsr restoreZp
    jmp CHAIN_LOADER
.endproc

; The loader, assembled to run at CHAIN_LOADER
loader:
.org CHAIN_LOADER
    lda #0
    ldx #8
    ldy #$ff
    jsr SETLFS
    lda #0                  ; The name's length, set by chainNext
NAMELEN = * - 1 - CHAIN_LOADER
    ldx #<lname
    ldy #>lname
    jsr SETNAM
    lda #0
    tax
    tay
    jsr LOAD
    bcs LF
    lda #CHAIN_MAGIC1
    sta rttChainFlag
    lda #CHAIN_MAGIC2
    sta rttChainFlag+1
    jmp $2011               ; The entry (m65hdr.s)
LF: ldx #0                  ; The load failed
:   lda lmsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts                     ; Back to BASIC
lmsg: .byte 13, "chain load failed", 13, "RESULT: FAIL", 13, 0
lname:
LOADER_SIZE = * - CHAIN_LOADER
.reloc
.assert CHAIN_LOADER + LOADER_SIZE + 17 <= RTT_STATE, error, "loader too big"

.ifdef COVERAGE

; Fills the coverage map with $80. A probe shifts its byte right.
.proc covInstall
    lda #$80
    ldx #0
L1:
.repeat ::COVSIZE / 256, i
    sta ::COVMAP + i * 256,x
.endrep
    inx
    bne L1
    rts
.endproc

; Saves the map to the disk as covName
.proc covSave
    ldy #0
:   lda covName,y
    beq :+
    iny
    bne :-
:   tya
    ldx #<covName
    ldy #>covName
    jsr SETNAM
    lda #1
    ldx #8
    ldy #0
    jsr SETLFS
    lda #<COVMAP
    sta covPtr
    lda #>COVMAP
    sta covPtr+1
    lda #covPtr
    ldx #<(COVMAP + COVSIZE)
    ldy #>(COVMAP + COVSIZE)
    jmp SAVE
.endproc

; SAVE takes the start address in zero page. The runtime's zero page is
; free once the suite is done.
covPtr = RTT_ZP_FIRST

.endif
