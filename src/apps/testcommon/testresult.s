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
;
; testLeakCheck reports any heap block still allocated and returns with the
; carry set, so the caller can fail the test. Call it once the tests have
; freed everything. The buffers that hold the compile-time
; error messages (see initCompilerErrors) are never freed, so blocks of that
; size are not counted.
;
; In a debug build (make DEBUG=1, which make test always uses) testInit also
; fails the test if main did not start with poisonBss, by checking that a BSS
; byte nothing writes holds the poison byte.

.include "cbm_kernal.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "poisonbss.inc"
.include "error.inc"

.export testInit, testPass, testFail, testMemCheck, testRestoreBrk
.export testLeakCheck, brkCatch, brkCode

; The size of the block initCompilerErrors allocates for the error messages
ERROR_BUFFER_SIZE = numParserErrors * (MAX_ERROR_LENGTH + 1)

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
bssCanary: .res 1           ; Never written. poisonBss should have filled it.
leakBank: .res 1
leakEntry: .res 2           ; The MAT entry being looked at
leakBlocks: .res 2          ; Number of leaked blocks
leakBytes: .res 4           ; Total size of the leaked blocks
leakBuf: .res 12

.data

strPass: .byte "RESULT: PASS", 13, 0
strFail: .byte "RESULT: FAIL", 13, 0
strBrk: .byte 13, "brk code $", 0
strDoubleFree: .byte ": freeing unallocated memory (double free?) in ", 0
strUnknown: .byte ": not a memory check", 0
strNoCheck: .byte 13, "asmlib has no memory checks. rebuild it with "
    .byte "memcheck=1.", 13, 0
strNoPoison: .byte 13, "bss was not poisoned. main must start with "
    .byte "poisonbss.", 13, 0
strLeak: .byte 13, "memory leak: ", 0
strLeakBlocks: .asciiz " blocks, "
strLeakBytes: .byte " bytes", 13, 0

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

.ifdef __DEBUG__
    ; Fail if BSS was not filled with the poison byte (see poisonbss.inc)
    lda bssCanary
    cmp #POISON_BYTE
    bne :+
    rts
:   lda #<strNoPoison
    ldx #>strNoPoison
    jsr printZString
    jmp testFail
.else
    rts
.endif
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

; Looks for heap blocks that are still allocated, other than the error message
; buffers. If there are any it prints how many and their total size and returns
; with the carry set. The caller then fails the test. Otherwise the carry is
; clear. Walks the MAT of every bank (see memheap.s). Each
; entry is two bytes: the block size, with the high bit of the second byte set
; if the block is allocated. Two $00 bytes end the MAT, which grows downward.
.proc testLeakCheck
    lda #0
    sta leakBank
    sta leakBlocks
    sta leakBlocks+1
    sta leakBytes
    sta leakBytes+1
    sta leakBytes+2
    sta leakBytes+3

BN: lda leakBank
    jsr getMemHeapForBank
    jsr isQZero
    beq DN                  ; No more banks
    stq ptr1

    ; Read the MAT entry
L1: ldz #0
    nop
    lda (ptr1),z
    sta leakEntry
    inz
    nop
    lda (ptr1),z
    sta leakEntry+1
    ora leakEntry
    bne :+
    inc leakBank            ; End of this bank's MAT
    bra BN

:   lda leakEntry+1
    bpl NX                  ; Branch if the block is free
    and #$7f
    sta leakEntry+1

    ; The error message buffers are never freed
    cmp #>ERROR_BUFFER_SIZE
    bne LK
    lda leakEntry
    cmp #<ERROR_BUFFER_SIZE
    beq NX

LK: inc leakBlocks
    bne :+
    inc leakBlocks+1
:   lda leakBytes
    clc
    adc leakEntry
    sta leakBytes
    lda leakBytes+1
    adc leakEntry+1
    sta leakBytes+1
    bcc NX
    inc leakBytes+2

    ; Move to the next entry, two bytes down
NX: lda ptr1
    sec
    sbc #2
    sta ptr1
    bcs L1
    lda ptr1+1
    bne :+
    dec ptr1+2
:   dec ptr1+1
    bra L1

DN: lda leakBlocks
    ora leakBlocks+1
    bne :+
    clc
    rts

    ; Report the leak
:   jsr CLRCHN              ; Output to the screen
    lda #<strLeak
    ldx #>strLeak
    jsr printZString
    lda leakBlocks
    sta intOp1
    lda leakBlocks+1
    sta intOp1+1
    lda #<leakBuf
    ldx #>leakBuf
    jsr writeInt16
    jsr printLeakBuf
    lda #<strLeakBlocks
    ldx #>strLeakBlocks
    jsr printZString
    ldq leakBytes
    stq intOp1
    lda #<leakBuf
    ldx #>leakBuf
    jsr writeInt32
    jsr printLeakBuf
    lda #<strLeakBytes
    ldx #>strLeakBytes
    jsr printZString
    sec
    rts

printLeakBuf:
    ldx #0
:   lda leakBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
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
