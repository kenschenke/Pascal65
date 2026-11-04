;
; testresult.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Shared by the test programs to report an overall PASS/FAIL result to
; the host. The result is printed on the screen as the last line before
; the BASIC READY prompt. The Makefile runs the emulator with -dumpscreen
; and looks for "RESULT: PASS" or "RESULT: FAIL" in the screen dump.
;
; testInit must be called first thing in main. testFail abandons the
; test run immediately by restoring the stack to where it was when main
; started and returning to BASIC, so no test needs to unwind itself.
;
; The tests run with asmlib built with MEMCHECK=1 (see its Makefile). Then
; freeing memory that is not allocated, such as a double free, executes BRK
; with a code in Z that says which routine found it. testInit points the
; KERNAL's BRK vector at brkTrap, which reports the BRK and fails the test.
; testPass and testFail put the vector back.
;
; A test that expects a BRK sets brkCatch to a routine of its own. brkTrap
; jumps there instead of failing, with the BRK's code in brkCode. That routine
; must clear brkCatch, restore the stack pointer, and carry on.
;
; testMemCheck makes sure asmlib was built with the memory checks. Call it
; once the heap is initialized. It frees a block twice and fails the test if
; that does not execute BRK.

.include "cbm_kernal.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "4510macros.inc"

.export testInit, testPass, testFail, testMemCheck, testRestoreBrk
.export brkCatch, brkCode

CH_HOME = $13
CH_DOWN = $11

BRKVEC = $0316              ; KERNAL BRK vector

.bss

savedSP: .res 1
oldBrk: .res 2
brkCode: .res 1
brkCatch: .res 2
checkSP: .res 1
checkBlock: .res 4

.data

strPass: .byte "RESULT: PASS", 13, 0
strFail: .byte "RESULT: FAIL", 13, 0
strBrk: .byte 13, "brk code $", 0
strDoubleFree: .byte ": freeing unallocated memory (double free?) in ", 0
strUnknown: .byte ": not a memory check", 0
strNoCheck: .byte 13, "asmlib has no memory checks. rebuild it with "
    .byte "memcheck=1.", 13, 0

; The codes the memory checks put in Z, and the routines they are in
brkCodes: .byte $11, $12, $13, $14, $22
NUM_CODES = * - brkCodes
brkNames: .addr nameFreeDecl, nameFreeSymbol, nameFreeSymtab, nameFreeType
    .addr nameHeapFree
nameFreeDecl: .asciiz "freeDecl"
nameFreeSymbol: .asciiz "freeSymbol"
nameFreeSymtab: .asciiz "freeSymtab"
nameFreeType: .asciiz "freeType"
nameHeapFree: .asciiz "heapFree"

.code

; Remembers the stack pointer as it was on entry to main and traps BRK
.proc testInit
    tsx
    inx                 ; Discard the return address pushed by the JSR
    inx
    stx savedSP

    lda #0
    sta brkCatch
    sta brkCatch+1
    sei
    lda BRKVEC
    sta oldBrk
    lda BRKVEC+1
    sta oldBrk+1
    lda #<brkTrap
    sta BRKVEC
    lda #>brkTrap
    sta BRKVEC+1
    cli
    rts
.endproc

.proc testPass
    jsr testRestoreBrk
    lda #<strPass
    ldx #>strPass
    jmp printString
.endproc

; Does not return to the caller. Control goes back to whatever called main.
.proc testFail
    jsr testRestoreBrk
    jsr CLALL           ; Close open files and send output back to the screen
    lda #<strFail
    ldx #>strFail
    jsr printString
    ldx savedSP
    txs
    rts
.endproc

; Puts the KERNAL's BRK vector back, if testInit changed it. A program that
; ends without testPass or testFail calls this before it returns.
.proc testRestoreBrk
    lda oldBrk
    ora oldBrk+1
    beq :+
    sei
    lda oldBrk
    sta BRKVEC
    lda oldBrk+1
    sta BRKVEC+1
    lda #0
    sta oldBrk
    sta oldBrk+1
    cli
:   rts
.endproc

; The KERNAL jumps here on BRK. The memory checks leave their code in Z.
.proc brkTrap
    tza
    sta brkCode
    cli
    lda brkCatch+1
    beq :+
    jmp (brkCatch)      ; The test expected this BRK

:   jsr CLRCHN          ; Output to the screen
    lda #<strBrk
    ldx #>strBrk
    jsr printZString
    lda brkCode
    jsr printHex

    ; Look up the routine that found the problem
    ldx #0
L1: lda brkCodes,x
    cmp brkCode
    beq L2
    inx
    cpx #NUM_CODES
    bne L1
    lda #<strUnknown
    ldx #>strUnknown
    jsr printZString
    bra L3
L2: phx
    lda #<strDoubleFree
    ldx #>strDoubleFree
    jsr printZString
    pla
    asl a
    tax
    lda brkNames,x
    pha
    lda brkNames+1,x
    tax
    pla
    jsr printZString
L3: lda #13
    jsr CHROUT
    jmp testFail
.endproc

; Fails the test if asmlib was built without the memory checks. The heap must
; be initialized. It is left as it was.
.proc testMemCheck
    lda #1
    ldx #0
    jsr heapAlloc
    stq checkBlock
    jsr heapFree

    ; Freeing it again must execute BRK
    lda #<caught
    sta brkCatch
    lda #>caught
    sta brkCatch+1
    tsx
    stx checkSP
    ldq checkBlock
    jsr heapFree

    lda #0
    sta brkCatch
    sta brkCatch+1
    lda #<strNoCheck
    ldx #>strNoCheck
    jsr printZString
    jmp testFail

    ; Back to testMemCheck's caller
caught:
    ldx checkSP
    txs
    lda #0
    sta brkCatch
    sta brkCatch+1
    rts
.endproc

; Prints the zero-terminated string in A/X where the cursor is
.proc printZString
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
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
    adc #6              ; The carry is set: 10 + 6 + 1 + '0' = 'a'
:   adc #'0'
    jmp CHROUT
.endproc

; Prints the result string at the top of the screen. xemu's -prgexit does not
; see a READY prompt in the bottom two screen rows, so a test that scrolled the
; screen would never exit. Printing at the top puts READY well clear of them.
;
; xemu also only recognizes the prompt when the cursor sits over a blank cell.
; After this returns BASIC prints READY on row 2, which leaves the cursor at
; column 0 of row 3, so a space is written there. Only that one cell is changed
; so the rest of the screen, which has the details of a failure, stays visible.
; (Writing whole blank rows made the screen editor shift the screen contents.)
.proc printString
    sta ptr1
    stx ptr1+1
    lda #CH_HOME
    jsr CHROUT
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   lda #13             ; Move to row 3
    jsr CHROUT
    jsr CHROUT
    lda #' '
    jsr CHROUT
    lda #CH_HOME        ; Back to row 1 for BASIC
    jsr CHROUT
    lda #CH_DOWN
    jmp CHROUT
.endproc
