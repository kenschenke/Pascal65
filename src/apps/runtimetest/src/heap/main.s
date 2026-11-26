;
; main.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tests the runtime's memory heap (memheap.s in src/lib/runtime): heapInit,
; heapAlloc, heapFree and the routines they use (splitting a reused block,
; merging free blocks, trimming the MAT and the out of memory check).
;
; The heap is linked into this program from the runtime's own sources, and
; rterror.s stands in for runtimeError, so a test can catch out of memory.
; The heap lives in TESTMEM (rtt.inc), which is filled with a guard byte
; first, so a write outside the heap is found.
;
; Each test is a script (tests.s, in the language of heap.inc). Most check
; the address of every block and the exact contents of the MAT after each
; change, so they know where the heap put things and why. heapAlloc must
; change only the zero page it uses (ptr1 to ptr4, tmp1 to tmp4 and the
; intOps), and heapFree only ptr1 and ptr2: the runtime's callers keep
; values in the rest.
;
; The stress steps allocate and free blocks at random, fill each block with
; a tag and check after each step that the MAT is sound and no block was
; written.
;
; The scripts use three zero page pointers the heap doesn't: intPtr,
; stackP and savedStackPtr.

.include "error.inc"
.include "rtt.inc"
.include "rterror.inc"
.include "heap.inc"

.export suiteMain

.import heapInit, heapAlloc, heapFree
.import tests
.import rttTest, rttStep, rttExpect, rttActual, rttFail, rttCheck8
.import rttCheck16, rttWhere, printZ, printHex8, printHex16, printDec8
.import printCR, testFail

; The runtime's zero page (runtime.inc, which can't be included here:
; under --cpu 4510, sp is a register)
ptr1 = $08
ptr2 = $0a
intOp32 = $18
intPtr = $1c
stackP = $1e
savedStackPtr = $20

SCRIPT = intPtr             ; The script's next byte
WORK = stackP               ; The MAT entry being looked at
BLK = savedStackPtr         ; A block being filled or checked

GUARD = $ee                 ; TESTMEM is filled with this
MAXLIVE = 24                ; The most blocks a stress step keeps

; Zero page the heap may change, as offsets from RTT_ZP_FIRST
ALLOC_ZP_FIRST = ptr1 - RTT_ZP_FIRST
ALLOC_ZP_LAST = intOp32 + 3 - RTT_ZP_FIRST
FREE_ZP_FIRST = ptr1 - RTT_ZP_FIRST
FREE_ZP_LAST = ptr2 + 1 - RTT_ZP_FIRST

.bss

heapBot: .res 2             ; The heap's bottom and top, from INIT
heapTopV: .res 2
argSize: .res 2
argAddr: .res 2
count: .res 1
index: .res 1
zpSnap: .res RTT_ZP_SIZE
zpFirst: .res 1             ; The zero page checkZp lets change
zpLast: .res 1
guardEnd: .res 2
expSize: .res 2             ; A MAT entry, expected and actual
expAddr: .res 2
actSize: .res 2
actAddr: .res 2
; The stress steps
steps: .res 2
sizeMask: .res 1
oomOk: .res 1
rnd: .res 2
liveCount: .res 1
liveAddr: .res MAXLIVE * 2
liveSize: .res MAXLIVE * 2
liveTag: .res MAXLIVE
blkSize: .res 2
blkTag: .res 1
nextAddr: .res 2
prevFree: .res 1
usedCount: .res 1

.data

opTable:
    .addr opInit, opAlloc, opOom, opFree, opMat, opSetMat, opTop, opStress
.assert (* - opTable) / 2 = NUM_OPS, error, "opTable"

strBadOp: .asciiz "bad opcode"
strAddr: .asciiz "heapalloc's address"
strTop: .asciiz "heapalloc($ffff)"
strNoOom: .asciiz "no out of memory error. got $"
strErr: .asciiz "runtime error"
strZp: .asciiz "zero page changed at $"
strGuard: .asciiz "memory outside the heap changed at $"
strMatEntry: .asciiz "mat entry "
strExpected: .asciiz " expected "
strGot: .asciiz " got "
strAt: .asciiz " at $"
strEntry: .asciiz ", entry "
strGap: .asciiz "blocks not contiguous"
strZeroSize: .asciiz "block of size 0"
strNotLive: .asciiz "allocated block no test owns"
strSmall: .asciiz "block smaller than requested"
strTwoFree: .asciiz "two free blocks side by side"
strOverlap: .asciiz "mat overlaps the last block"
strMissing: .asciiz "a block the test owns is not in the mat"
strWritten: .asciiz "a block was written. block at $"
strOomNotOk: .asciiz "out of memory with oomok 0"
strNotEmpty: .asciiz "heap not empty after freeing every block"

.code

; Runs every test in the table in tests.s, which ends with 0, or
; FIRST_TEST to LAST_TEST (make test TESTSEL="-D FIRST_TEST=n ...")
.ifndef FIRST_TEST
FIRST_TEST = 1
.endif
.ifndef LAST_TEST
LAST_TEST = 255
.endif

.proc suiteMain
    lda #FIRST_TEST-1
    sta rttTest
L1: lda rttTest
    cmp #LAST_TEST
    bne :+
    rts
:   inc rttTest
    lda rttTest
    asl a
    tax
    lda tests-2,x
    sta SCRIPT
    lda tests-1,x
    sta SCRIPT+1
    ora SCRIPT
    bne :+
    rts
:   lda #0
    sta rttStep
    jsr runScript
    bra L1
.endproc

.proc runScript
L1: inc rttStep
    jsr fetch
    cmp #OP_END
    beq DN
    cmp #NUM_OPS+1
    bcc :+
    LDAX strBadOp
    jmp rttFail
:   asl a
    tax
    jsr dispatch
    bra L1
DN: jmp checkGuard

dispatch:
    jmp (opTable-2,x)
.endproc

; Returns the script's next byte in A. Keeps X.
.proc fetch
    ldy #0
    lda (SCRIPT),y
    inc SCRIPT
    bne :+
    inc SCRIPT+1
:   rts
.endproc

; Returns the script's next word in A/X
.proc fetchWord
    jsr fetch
    pha
    jsr fetch
    tax
    pla
    rts
.endproc

; INIT bottom, top
.proc opInit
    jsr fetchWord
    sta heapBot
    stx heapBot+1
    jsr fetchWord
    sta heapTopV
    stx heapTopV+1
    lda #0
    sta liveCount

    ; Fill TESTMEM with the guard byte
    lda #<TESTMEM
    sta WORK
    lda #>TESTMEM
    sta WORK+1
    ldy #0
    lda #GUARD
:   sta (WORK),y
    iny
    bne :-
    inc WORK+1
    ldx WORK+1
    cpx #>TESTMEM_END
    bne :-

    lda heapTopV
    sta ptr1
    lda heapTopV+1
    sta ptr1+1
    lda heapBot
    ldx heapBot+1
    jmp heapInit
.endproc

; ALLOC size, address
.proc opAlloc
    jsr fetchWord
    sta argSize
    stx argSize+1
    jsr fetchWord
    sta rttExpect
    stx rttExpect+1
    jsr snapZp
    lda argSize
    ldx argSize+1
    jsr heapAlloc
    sta rttActual
    stx rttActual+1
    LDAX strAddr
    jsr rttCheck16
    jmp checkAllocZp
.endproc

; OOM size
.proc opOom
    jsr fetchWord
    sta argSize
    stx argSize+1
    CATCH_RTE caught
    lda argSize
    ldx argSize+1
    jsr heapAlloc
    UNCATCH_RTE
    pha
    phx
    jsr rttWhere
    LDAX strNoOom
    jsr printZ
    plx
    pla
    jsr printHex16
    jsr printCR
    jmp testFail

caught:
    lda #rteOutOfMemory
    sta rttExpect
    lda rteCode
    sta rttActual
    LDAX strErr
    jmp rttCheck8
.endproc

; FREE address
.proc opFree
    jsr fetchWord
    pha
    phx
    jsr snapZp
    plx
    pla
    jsr heapFree
    jmp checkFreeZp
.endproc

; MAT count, entries
.proc opMat
    jsr fetch
    sta count
    jsr matStart
L1: lda index
    cmp count
    beq TM
    jsr fetchWord
    sta expSize
    stx expSize+1
    jsr fetchWord
    sta expAddr
    stx expAddr+1
    jsr checkEntry
    jsr matNext
    bra L1
    ; The zero entry
TM: lda #0
    sta expSize
    sta expSize+1
    sta expAddr
    sta expAddr+1
    jmp checkEntry
.endproc

; SETMAT count, entries
.proc opSetMat
    jsr fetch
    sta count
    jsr matStart
L1: lda index
    cmp count
    beq TM
    ldy #0
:   phy
    jsr fetch
    ply
    sta (WORK),y
    iny
    cpy #4
    bne :-
    jsr matNext
    bra L1
TM: lda #0
    ldy #3
:   sta (WORK),y
    dey
    bpl :-
    rts
.endproc

; TOP
.proc opTop
    lda heapTopV
    sta rttExpect
    lda heapTopV+1
    sta rttExpect+1
    lda #$ff
    ldx #$ff
    jsr heapAlloc
    sta rttActual
    stx rttActual+1
    LDAX strTop
    jmp rttCheck16
.endproc

; Points WORK at the MAT's first entry, with index 0
.proc matStart
    lda heapTopV
    sta WORK
    lda heapTopV+1
    sta WORK+1
    lda #0
    sta index
    rts
.endproc

; Moves WORK to the next MAT entry, four bytes down
.proc matNext
    inc index
    sec
    lda WORK
    sbc #4
    sta WORK
    bcs :+
    dec WORK+1
:   rts
.endproc

; Reads the MAT entry at WORK into actSize and actAddr
.proc readEntry
    ldy #0
:   lda (WORK),y
    sta actSize,y
    iny
    cpy #4
    bne :-
    rts
.endproc

; Fails if the MAT entry at WORK isn't expSize and expAddr
.proc checkEntry
    jsr readEntry
    ldx #3
:   lda expSize,x
    cmp actSize,x
    bne FL
    dex
    bpl :-
    rts

FL: jsr rttWhere
    LDAX strMatEntry
    jsr printZ
    lda index
    jsr printDec8
    LDAX strExpected
    jsr printZ
    lda expSize
    ldx expSize+1
    jsr printHex16
    lda #' '
    jsr printChar
    lda expAddr
    ldx expAddr+1
    jsr printHex16
    LDAX strGot
    jsr printZ
    lda actSize
    ldx actSize+1
    jsr printHex16
    lda #' '
    jsr printChar
    lda actAddr
    ldx actAddr+1
    jsr printHex16
    jsr printCR
    jmp testFail
.endproc

.proc printChar
    sta str
    LDAX str
    jmp printZ
.pushseg
.data
str: .byte 0, 0
.popseg
.endproc

; Keeps a copy of the runtime's zero page
.proc snapZp
    ldx #RTT_ZP_SIZE-1
:   lda RTT_ZP_FIRST,x
    sta zpSnap,x
    dex
    bpl :-
    rts
.endproc

.proc checkAllocZp
    lda #ALLOC_ZP_FIRST
    ldx #ALLOC_ZP_LAST
    bra checkZp
.endproc

.proc checkFreeZp
    lda #FREE_ZP_FIRST
    ldx #FREE_ZP_LAST
    ; Fall through
.endproc

; Fails if the runtime's zero page differs from the copy snapZp kept,
; other than the offsets A to X
.proc checkZp
    sta zpFirst
    stx zpLast
    ldx #0
L1: cpx zpFirst
    bcc :+
    cpx zpLast
    bcc NX
    beq NX
:   lda RTT_ZP_FIRST,x
    cmp zpSnap,x
    bne FL
NX: inx
    cpx #RTT_ZP_SIZE
    bne L1
    rts

FL: phx
    jsr rttWhere
    LDAX strZp
    jsr printZ
    pla
    clc
    adc #RTT_ZP_FIRST
    jsr printHex8
    jsr printCR
    jmp testFail
.endproc

; Fails if TESTMEM below the heap's bottom or above the MAT's first entry
; isn't the guard byte
.proc checkGuard
    lda #<TESTMEM
    sta WORK
    lda #>TESTMEM
    sta WORK+1
    lda heapBot
    sta guardEnd
    lda heapBot+1
    sta guardEnd+1
    jsr checkRange
    clc
    lda heapTopV
    adc #4
    sta WORK
    lda heapTopV+1
    adc #0
    sta WORK+1
    lda #<TESTMEM_END
    sta guardEnd
    lda #>TESTMEM_END
    sta guardEnd+1
    ; Fall through
.endproc

; Fails if WORK up to guardEnd isn't all guard bytes
.proc checkRange
L1: lda WORK+1
    cmp guardEnd+1
    bcc :+
    bne DN
    lda WORK
    cmp guardEnd
    bcs DN
:   ldy #0
    lda (WORK),y
    cmp #GUARD
    bne FL
    inc WORK
    bne L1
    inc WORK+1
    bra L1
DN: rts

FL: jsr rttWhere
    LDAX strGuard
    jsr printZ
    lda WORK
    ldx WORK+1
    jsr printHex16
    jsr printCR
    jmp testFail
.endproc

; STRESS seed, steps, mask, oomok
;
; Each step either allocates a block of a random size or frees a random
; block the test owns, then checks the heap (verifyHeap, checkBlocks). At
; the end every block is freed and the heap must be empty.
.proc opStress
    jsr fetchWord
    sta rnd
    stx rnd+1
    jsr fetchWord
    sta steps
    stx steps+1
    jsr fetch
    sta sizeMask
    jsr fetch
    sta oomOk

L1: lda steps
    ora steps+1
    beq FA
    jsr stressStep
    lda steps
    bne :+
    dec steps+1
:   dec steps
    bra L1

    ; Free every block that's left
FA: lda liveCount
    beq EM
    lda #0
    jsr freeLive
    bra FA

    ; The heap must be empty
EM: jsr matStart
    jsr readEntry
    lda actAddr
    ora actAddr+1
    bne NE
    rts
NE: LDAX strNotEmpty
    jmp rttFail
.endproc

.proc stressStep
    jsr rand
    lda liveCount
    beq AL
    cmp #MAXLIVE
    beq FR
    lda rnd+1
    lsr a
    bcs AL

FR: jsr rand
    and #$7f
:   cmp liveCount           ; A random block
    bcc :+
    sbc liveCount
    bra :-
:   jsr freeLive
    jmp verifyAll

AL: jsr rand
    and sizeMask
    clc
    adc #1
    sta argSize
    lda #0
    adc #0
    sta argSize+1
    jsr snapZp
    CATCH_RTE oom
    lda argSize
    ldx argSize+1
    jsr heapAlloc
    UNCATCH_RTE
    sta argAddr
    stx argAddr+1
    jsr checkAllocZp
    ldy liveCount           ; Keep the block
    sty index
    tya
    asl a
    tay
    lda argAddr
    sta liveAddr,y
    sta BLK
    lda argAddr+1
    sta liveAddr+1,y
    sta BLK+1
    lda argSize
    sta liveSize,y
    sta blkSize
    lda argSize+1
    sta liveSize+1,y
    sta blkSize+1
    ldy index
    lda steps
    ora #1                  ; Never 0
    sta liveTag,y
    sta blkTag
    inc liveCount
    jsr verifyHeap          ; Before the block is written
    jsr fillBlock
    jmp verifyAll

oom:
    lda #rteOutOfMemory
    sta rttExpect
    lda rteCode
    sta rttActual
    LDAX strErr
    jsr rttCheck8
    lda oomOk
    bne :+
    LDAX strOomNotOk
    jmp rttFail
:   jmp verifyAll
.endproc

; Checks the block in slot A, frees it and drops the slot
.proc freeLive
    sta index
    jsr loadLive
    jsr checkBlock
    jsr loadLive            ; checkBlock moves BLK
    jsr snapZp
    lda BLK
    ldx BLK+1
    jsr heapFree
    jsr checkFreeZp
    ; Move the last slot to this one
    dec liveCount
    lda liveCount
    asl a
    tax
    lda index
    asl a
    tay
    lda liveAddr,x
    sta liveAddr,y
    lda liveAddr+1,x
    sta liveAddr+1,y
    lda liveSize,x
    sta liveSize,y
    lda liveSize+1,x
    sta liveSize+1,y
    ldx liveCount
    ldy index
    lda liveTag,x
    sta liveTag,y
    rts
.endproc

; Loads slot index into BLK, blkSize and blkTag
.proc loadLive
    lda index
    asl a
    tay
    lda liveAddr,y
    sta BLK
    lda liveAddr+1,y
    sta BLK+1
    lda liveSize,y
    sta blkSize
    lda liveSize+1,y
    sta blkSize+1
    ldy index
    lda liveTag,y
    sta blkTag
    rts
.endproc

; Fills the block at BLK, blkSize bytes, with blkTag
.proc fillBlock
    jsr blkSetup
L1: jsr blkDone
    beq DN
    lda blkTag
    sta (BLK),y
    jsr blkNext
    bra L1
DN: rts
.endproc

; Fails if the block at BLK, blkSize bytes, isn't all blkTag
.proc checkBlock
    jsr blkSetup
L1: jsr blkDone
    beq DN
    lda (BLK),y
    cmp blkTag
    bne FL
    jsr blkNext
    bra L1
DN: rts
FL: jsr rttWhere
    LDAX strWritten
    jsr printZ
    lda BLK
    ldx BLK+1
    jsr printHex16
    jsr printCR
    jmp testFail
.endproc

; The block loops count argSize down with Y as the offset in the page
.proc blkSetup
    lda blkSize
    sta argSize
    lda blkSize+1
    sta argSize+1
    ldy #0
    rts
.endproc

; Sets Z if no bytes are left
.proc blkDone
    lda argSize
    ora argSize+1
    rts
.endproc

.proc blkNext
    lda argSize
    bne :+
    dec argSize+1
:   dec argSize
    iny
    bne :+
    inc BLK+1               ; The next page. checkBlock's caller reloads BLK.
:   rts
.endproc

; Checks the MAT and every block the test owns
.proc verifyAll
    jsr verifyHeap
    lda #0
    sta index
L1: lda index
    cmp liveCount
    beq DN
    jsr loadLive
    jsr checkBlock
    inc index
    bra L1
DN: rts
.endproc

; Fails unless the MAT is sound: its blocks start at the heap's bottom and
; are contiguous, no block has size 0, no two free blocks are side by side,
; each allocated block is one the test owns, at least its size, and each block
; the test owns is in the MAT. The zero entry must be at or above the end
; of the last block.
.proc verifyHeap
    jsr matStart
    lda heapBot
    sta nextAddr
    lda heapBot+1
    sta nextAddr+1
    lda #0
    sta prevFree
    sta usedCount
L1: jsr readEntry
    lda actAddr
    ora actAddr+1
    bne :+
    jmp EN
:   lda actAddr
    cmp nextAddr
    bne GP
    lda actAddr+1
    cmp nextAddr+1
    beq :+
GP: LDAX strGap
    jmp failAt
:   lda actSize+1
    and #$7f
    sta actSize+1
    ora actSize
    bne :+
    LDAX strZeroSize
    jmp failAt
:   clc
    lda nextAddr
    adc actSize
    sta nextAddr
    lda nextAddr+1
    adc actSize+1
    sta nextAddr+1
    ldy #1
    lda (WORK),y
    bmi US
    lda prevFree
    beq :+
    LDAX strTwoFree
    jmp failAt
:   inc prevFree
    bra NX

    ; An allocated block. Look for it in the slots.
US: lda #0
    sta prevFree
    inc usedCount
    ldx #0
L2: cpx liveCount
    bne :+
    LDAX strNotLive
    jmp failAt
:   txa
    asl a
    tay
    lda liveAddr,y
    cmp actAddr
    bne L3
    lda liveAddr+1,y
    cmp actAddr+1
    bne L3
    ; A reused block that couldn't be split is larger than requested
    lda actSize
    cmp liveSize,y
    lda actSize+1
    sbc liveSize+1,y
    bcs NX
    LDAX strSmall
    jmp failAt
L3: inx
    bra L2

NX: jsr matNext
    jmp L1

    ; The zero entry must not be below the end of the last block
EN: lda WORK+1
    cmp nextAddr+1
    bcc OV
    bne :+
    lda WORK
    cmp nextAddr
    bcc OV
:   lda usedCount
    cmp liveCount
    beq :+
    LDAX strMissing
    jmp rttFail
:   rts
OV: LDAX strOverlap
    ; Fall through
.endproc

; Fails with the message in A/X and the address of the MAT entry at WORK
.proc failAt
    pha
    phx
    jsr rttWhere
    plx
    pla
    jsr printZ
    LDAX strAt
    jsr printZ
    lda WORK
    ldx WORK+1
    jsr printHex16
    LDAX strEntry
    jsr printZ
    ldy #1
    lda (WORK),y
    tax
    dey
    lda (WORK),y
    jsr printHex16
    lda #' '
    jsr printChar
    ldy #3
    lda (WORK),y
    tax
    dey
    lda (WORK),y
    jsr printHex16
    jsr printCR
    jmp testFail
.endproc

; A 16-bit Galois LFSR. Returns the low byte in A.
.proc rand
    lsr rnd+1
    ror rnd
    bcc :+
    lda rnd+1
    eor #$b4
    sta rnd+1
:   lda rnd
    rts
.endproc
