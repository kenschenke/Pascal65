;
; main.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tests the memory heap in asmlib (memheap.s): initMemHeap, heapAlloc,
; heapFree, clearMemHeap, getMemHeapForBank, and the internal routines they
; use (the defragmenter, block splitting, trimming the MAT, and the debug
; check for freeing memory that is not allocated).
;
; Each test starts with an empty heap. Most tests check the address of every
; block they allocate and the exact contents of the Memory Allocation Table
; (MAT) afterwards, so they know where the allocator put things and why.
;
; A test that needs the heap to be full, such as a test of the defragmenter,
; fills the space left in each bank with "filler" blocks (see closeBank).
;
; An allocation that fails ends with runtimeError, which goes through asmlib's
; exit routine. The test points exitHandler at itself to catch that. Freeing
; memory that is not allocated executes BRK (asmlib must be built with
; MEMCHECK=1). testresult.s traps BRK and fails the test. A test that expects
; the BRK catches it with brkCatch (see expectBrk).
;
; When a check fails the test number, the check number within the test, and
; the expected and actual values are printed, then RESULT: FAIL.
;
; With COVERAGE defined this is built with an instrumented copy of memheap.s
; and saves the coverage map to the disk at the end (see the Makefile).

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.import initLib
.import testInit, testPass, testFail, testMemCheck
.import brkCatch, brkCode
.ifdef COVERAGE
.import covInstall, covSave
.endif

; The heap banks (memBanks in memheap.s). Each MAT starts at the top.
B0 = $12000
T0 = $1cffa
B1 = $42000
T1 = $4fffa
B2 = $50000
T2 = $5effa

NUM_SLOTS = 16
NUM_BANKS = 3
MAX_FILLERS = 4

; Stress test sizes
BLOCK_SIZE = 200            ; keeper and spacer size
GROUPS = 155                ; groups of keeper + 3 spacers (about 125K)
NEW_SIZE = 500              ; more than a spacer, less than three
NEW_COUNT = 120             ; more than the fresh heap left can hold
BIG_SIZE = 30000
HEADER = 4                  ; chain pointer at the start of each block

; Stores the 32-bit constant val in the four bytes at var
.macro SET32 var, val
    lda #.lobyte(val)
    sta var
    lda #.hibyte(val)
    sta var+1
    lda #.bankbyte(val)
    sta var+2
    lda #.hibyte(.hiword(val))
    sta var+3
.endmacro

; Loads a 16-bit size into A/X
.macro SIZEAX size
    lda #<(size)
    ldx #>(size)
.endmacro

; Allocates size bytes and keeps the pointer in a slot
.macro ALLOC slot, size
    ldy #slot
    SIZEAX size
    jsr allocSlot
.endmacro

; Allocates size bytes into a slot and checks the block is at addr
.macro ALLOC_AT slot, size, addr
    ALLOC slot, size
    SET32 expVal, addr
    ldy #slot
    jsr expectSlot
.endmacro

; Frees the block in a slot
.macro FREE slot
    ldy #slot
    jsr freeSlot
.endmacro

; Frees the block at addr
.macro FREE_AT addr
    SET32 expVal, addr
    jsr freeExp
.endmacro

; Checks that MAT entry idx of a bank is val
.macro ENTRY bank, idx, val
    SET32 expVal, val
    lda #bank
    ldx #idx
    jsr expectEntry
.endmacro

; Checks the whole MAT of a bank: the entries given, then the terminator
.macro MAT bank, v0, v1, v2, v3, v4, v5, v6
    .local count
    count = .paramcount - 1
    .ifnblank v0
        ENTRY bank, 0, v0
    .endif
    .ifnblank v1
        ENTRY bank, 1, v1
    .endif
    .ifnblank v2
        ENTRY bank, 2, v2
    .endif
    .ifnblank v3
        ENTRY bank, 3, v3
    .endif
    .ifnblank v4
        ENTRY bank, 4, v4
    .endif
    .ifnblank v5
        ENTRY bank, 5, v5
    .endif
    .ifnblank v6
        ENTRY bank, 6, v6
    .endif
    ENTRY bank, count, 0
.endmacro

; Fills size bytes of the block in a slot with val
.macro FILL slot, size, val
    lda #val
    sta fillVal
    ldy #slot
    SIZEAX size
    jsr fillSlot
.endmacro

; Checks size bytes of the block in a slot are val
.macro VERIFY slot, size, val
    lda #val
    sta fillVal
    ldy #slot
    SIZEAX size
    jsr verifySlot
.endmacro

; Fills size bytes at addr with val
.macro FILLMEM addr, size, val
    lda #val
    sta fillVal
    SET32 memAddr, addr
    SIZEAX size
    jsr fillMem
.endmacro

; Checks size bytes at addr are val
.macro CHECKMEM addr, size, val
    lda #val
    sta fillVal
    SET32 memAddr, addr
    SIZEAX size
    jsr checkMem
.endmacro

; Checks that allocating size bytes runs out of memory
.macro EXPECT_OOM size
    SIZEAX size
    jsr expectOOM
.endmacro

; Checks that freeing addr is caught by the debug check (BRK)
.macro EXPECT_BRK addr
    SET32 expVal, addr
    jsr expectBrk
.endmacro

; Fills the space left in a bank with filler blocks
.macro CLOSE bank
    lda #bank
    jsr closeBank
.endmacro

; Frees the filler blocks of a bank
.macro FREE_FILLERS bank
    lda #bank
    jsr freeFillers
.endmacro

; Checks getMemHeapForBank for a bank: the MAT address it returns and the
; heapBottom and heapTop it sets
.macro BANK_INFO bank, bottom, top
    lda #bank
    jsr getMemHeapForBank
    stq gotVal
    SET32 expVal, top
    jsr cmpBankTop
    ldq heapBottom
    stq gotVal
    SET32 expVal, bottom
    jsr cmpBankTop
    ldq heapTop
    stq gotVal
    SET32 expVal, top
    jsr cmpBankTop
.endmacro

.include "poisonbss.inc"

.segment "ENTRY"

main:
    poisonBss                   ; Must run before anything writes BSS

    jsr testInit

    ; Disable BASIC ROM
    lda $01
    and #$f8
    ora #$06
    sta $01

    jsr initLib
.ifdef COVERAGE
    jsr covInstall
.endif
    jsr stackInit
    jsr initMemHeap
    jsr testMemCheck

    ; An unexpected runtime error (such as running out of memory) fails
    tsx
    stx mainSP
    jsr restoreExit

    lda #0
    sta testIdx
L1: lda testIdx
    asl a
    tax
    lda tests,x
    sta testVec
    lda tests+1,x
    sta testVec+1
    ora testVec
    beq L2
    inc testIdx
    lda testIdx
    sta testNum
    lda #0
    sta checkNum
    sta checkNum+1
    jsr initMemHeap
    jsr callTest
    jmp L1

L2: jsr initMemHeap
.ifdef COVERAGE
    jsr covSave
.endif
    jsr testPass
    rts

callTest:
    jmp (testVec)

.data

tests:
    .addr testInitHeap      ; 1
    .addr testAlloc         ; 2
    .addr testFree          ; 3
    .addr testExact         ; 4
    .addr testTrim256       ; 5
    .addr testMany          ; 6
    .addr testBankEdge      ; 7
    .addr testFullHeap      ; 8
    .addr testZeroing       ; 9
    .addr testSplit         ; 10
    .addr testSplitTrim     ; 11
    .addr testRunLimit      ; 12
    .addr testEndRun        ; 13
    .addr testClear         ; 14
    .addr testBadFree       ; 15
    .addr testStress        ; 16
    .addr testZeroSize      ; 17
    .addr testTooBig        ; 18
    .addr testFreeAbove     ; 19
    .addr testClearEmpty    ; 20
    .addr testManyBig       ; 21
    .addr testSplitCheckpoint ; 22
    .addr 0

.code

;-----------------------------------------------------------------------------
; Test 1: initMemHeap writes an empty MAT to every bank, and
; getMemHeapForBank describes each bank and returns null past the last one.
.proc testInitHeap
    ; Put garbage where the terminators go so initMemHeap has to write them
    FILLMEM T0, 2, $ff
    FILLMEM T1, 2, $ff
    FILLMEM T2, 2, $ff
    jsr initMemHeap
    MAT 0
    MAT 1
    MAT 2

    BANK_INFO 0, B0, T0
    BANK_INFO 1, B1, T1
    BANK_INFO 2, B2, T2

    ; Past the last bank
    lda #3
    jsr getMemHeapForBank
    stq gotVal
    SET32 expVal, 0
    jsr cmpBankTop
    lda #$ff
    jsr getMemHeapForBank
    stq gotVal
    SET32 expVal, 0
    jmp cmpBankTop
.endproc

;-----------------------------------------------------------------------------
; Test 2: blocks are allocated one after another from the bottom of the
; heap, they are zeroed, and they do not overlap.
.proc testAlloc
    FILLMEM B0, 1024, $aa
    ALLOC_AT 0, 10, B0
    ALLOC_AT 1, 20, B0+10
    ALLOC_AT 2, 256, B0+30
    MAT 0, $800a, $8014, $8100
    MAT 1
    MAT 2
    VERIFY 0, 10, 0
    VERIFY 1, 20, 0
    VERIFY 2, 256, 0
    ; Zeroing stops at the end of the last block
    CHECKMEM B0+286, 10, $aa

    FILL 0, 10, 1
    FILL 1, 20, 2
    FILL 2, 256, 3
    VERIFY 0, 10, 1
    VERIFY 1, 20, 2
    VERIFY 2, 256, 3
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 3: freeing the last block trims it from the MAT, freeing a block in
; the middle leaves a free entry, a free block of the requested size is
; reused, and freeing null does nothing.
.proc testFree
    ALLOC_AT 0, 10, B0
    ALLOC_AT 1, 20, B0+10
    ALLOC_AT 2, 30, B0+30
    ALLOC_AT 3, 40, B0+60
    FILL 0, 10, $10
    FILL 1, 20, $11
    FILL 2, 30, $12
    FILL 3, 40, $13

    ; Freeing null does nothing
    FREE_AT 0
    MAT 0, $800a, $8014, $801e, $8028

    ; The last block is trimmed
    FREE 3
    MAT 0, $800a, $8014, $801e

    ; Its space is used again, and zeroed
    ALLOC_AT 4, 40, B0+60
    VERIFY 4, 40, 0
    MAT 0, $800a, $8014, $801e, $8028

    ; A block in the middle stays in the MAT as a free entry
    FREE 1
    MAT 0, $800a, $0014, $801e, $8028
    VERIFY 0, 10, $10
    VERIFY 2, 30, $12

    ; and is reused for the same size, zeroed
    ALLOC_AT 5, 20, B0+10
    VERIFY 5, 20, 0
    MAT 0, $800a, $8014, $801e, $8028

    ; Two free blocks in the middle, then freeing the last block trims all
    ; three
    FREE 5
    FREE 2
    MAT 0, $800a, $0014, $001e, $8028
    FREE 4
    MAT 0, $800a

    ; Freeing the only block empties the MAT
    FREE 0
    MAT 0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 4: a free block is only reused for exactly its size. Both bytes of the
; size are compared, and a larger free block is not used for a smaller
; request (block splitting only happens after the heap is defragmented).
.proc testExact
    ALLOC_AT 0, $0105, B0
    ALLOC_AT 1, 1, B0+$105
    FREE 0
    MAT 0, $0105, $8001

    ; Same low byte, different high byte
    ALLOC_AT 2, $0005, B0+$106
    ; Different low byte, same high byte
    ALLOC_AT 3, $0106, B0+$10b
    ; Smaller
    ALLOC_AT 4, $0104, B0+$211
    ; Exact
    ALLOC_AT 5, $0105, B0
    MAT 0, $8105, $8001, $8005, $8106, $8104
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 5: sizes that are a multiple of 256 (the low byte of the MAT entry is
; zero). Trimming stops at an allocated one and heapFree finds one.
.proc testTrim256
    ALLOC_AT 0, 10, B0
    ALLOC_AT 1, $200, B0+10
    FREE 0
    MAT 0, $000a, $8200
    FREE 1
    MAT 0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 6: a MAT with 128 entries. The terminator is then 256 bytes below the
; top of the MAT, so only the high byte of its address differs from the top.
.proc testMany
    SET32 runAddr, B0
    lda #0
    sta loopCnt
L1: lda #1
    ldx #0
    jsr heapAlloc
    stq gotVal
    ldq runAddr
    stq expVal
    jsr cmpAddr
    jsr incRunAddr
    inc loopCnt
    lda loopCnt
    cmp #128
    bne L1

    ENTRY 0, 0, $8001
    ENTRY 0, 127, $8001
    ENTRY 0, 128, 0

    ; Free the last block
    FREE_AT B0+127
    ENTRY 0, 126, $8001
    ENTRY 0, 127, 0

    ; Free the rest from the first. The last one trims them all.
    SET32 runAddr, B0
    lda #0
    sta loopCnt
L2: ldq runAddr
    jsr heapFree
    jsr incRunAddr
    inc loopCnt
    lda loopCnt
    cmp #127
    bne L2
    MAT 0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 7: a new block that ends exactly at the new terminating MAT entry
; fits, and one that is a byte bigger goes to the next bank.
;
; With one entry the bank 0 terminator is at T0-2, so a second block must end
; by T0-4 = $1cff6. The first block ends at $19fff, leaving $2ff7 bytes.
.proc testBankEdge
    ALLOC_AT 0, $7fff, B0
    ; A byte too big for bank 0
    ALLOC_AT 1, $2ff8, B1
    ; Exactly fills bank 0
    ALLOC_AT 2, $2ff7, B0+$7fff
    ; Bank 0 is full
    ALLOC_AT 3, 1, B1+$2ff8
    MAT 0, $ffff, $aff7
    MAT 1, $aff8, $8001
    MAT 2
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 8: fill every bank exactly, then run out of memory. Nothing is free
; so the defragmenter finds nothing to merge. Then free and reuse blocks in
; the last bank and empty the heap.
.proc testFullHeap
    ALLOC_AT 0, $7fff, B0
    ALLOC_AT 1, $2ff7, B0+$7fff         ; bank 0 is full
    ALLOC_AT 2, $7fff, B1
    ALLOC_AT 3, $5ff8, B2               ; a byte too big for bank 1
    ALLOC_AT 4, $5ff7, B1+$7fff         ; bank 1 is full
    ALLOC_AT 5, $7fff, B2+$5ff8
    EXPECT_OOM $ffe                     ; a byte too big for bank 2
    ALLOC_AT 6, $ffd, B2+$5ff8+$7fff    ; bank 2 is full
    EXPECT_OOM 1
    MAT 0, $ffff, $aff7
    MAT 1, $ffff, $dff7
    MAT 2, $dff8, $ffff, $8ffd

    ; Free a block in the middle of the last bank and get it back
    FREE 5
    MAT 2, $dff8, $7fff, $8ffd
    ALLOC_AT 7, $7fff, B2+$5ff8
    MAT 2, $dff8, $ffff, $8ffd

    ; The last block of the last bank
    FREE 6
    MAT 2, $dff8, $ffff
    ALLOC_AT 8, $ffd, B2+$5ff8+$7fff
    MAT 2, $dff8, $ffff, $8ffd

    ; Empty the heap. Each bank is trimmed on its own.
    FREE 0
    FREE 2
    FREE 3
    MAT 0, $7fff, $aff7
    MAT 1, $7fff, $dff7
    MAT 2, $5ff8, $ffff, $8ffd
    FREE 4
    MAT 1
    MAT 0, $7fff, $aff7
    FREE 1
    FREE 7
    FREE 8
    MAT 0
    MAT 2

    ; The heap is usable again
    ALLOC_AT 9, $7fff, B0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 9: zeroing a block stops at its end, for sizes around 256 and sizes
; that are a multiple of 256.
.proc testZeroing
    FILLMEM B0, $600, $ff
    ALLOC_AT 0, 1, B0
    VERIFY 0, 1, 0
    CHECKMEM B0+1, 1, $ff
    ALLOC_AT 1, 255, B0+1
    VERIFY 1, 255, 0
    CHECKMEM B0+256, 1, $ff
    ALLOC_AT 2, 256, B0+256
    VERIFY 2, 256, 0
    CHECKMEM B0+512, 1, $ff
    ALLOC_AT 3, 257, B0+512
    VERIFY 3, 257, 0
    CHECKMEM B0+769, 1, $ff
    ALLOC_AT 4, 512, B0+769
    VERIFY 4, 512, 0
    CHECKMEM B0+1281, 1, $ff

    ; A reused block of 256 bytes is zeroed and its neighbours are not
    FILL 1, 255, $11
    FILL 2, 256, $22
    FILL 3, 257, $33
    FREE 2
    ALLOC_AT 5, 256, B0+256
    VERIFY 5, 256, 0
    VERIFY 1, 255, $11
    VERIFY 3, 257, $33
    rts
.endproc

; Builds the heap used by the split tests: K0, three spacers, and K1 in
; bank 0, then fills the rest of the heap and frees the spacers. That leaves
; one run of three free blocks.
;
;   slot 0: K0, 100 bytes of $11 at B0
;   slots 1-3: spacers, 100 bytes each at B0+100, B0+200, B0+300
;   slot 4: K1, 256 bytes of $22 at B0+400 (its MAT entry's low byte is 0)
.proc splitSetup
    ALLOC_AT 0, 100, B0
    ALLOC_AT 1, 100, B0+100
    ALLOC_AT 2, 100, B0+200
    ALLOC_AT 3, 100, B0+300
    ALLOC_AT 4, 256, B0+400
    FILL 0, 100, $11
    FILL 1, 100, $77
    FILL 2, 100, $77
    FILL 3, 100, $77
    FILL 4, 256, $22
    CLOSE 0
    CLOSE 1
    CLOSE 2
    FREE 1
    FREE 2
    FREE 3
    ENTRY 0, 0, $8064
    ENTRY 0, 1, $0064
    ENTRY 0, 2, $0064
    ENTRY 0, 3, $0064
    ENTRY 0, 4, $8100

    ; The heap is full: no free block is 250 bytes and there is no room for
    ; a new one. heapAlloc defragments the heap, which merges the run into
    ; one free 300-byte entry followed by two spare entries, then splits it.
    ALLOC_AT 5, 250, B0+100
    VERIFY 5, 250, 0
    ENTRY 0, 1, $80fa
    ENTRY 0, 2, $0032                   ; the remainder
    ENTRY 0, 3, $8000                   ; a spare entry
    ENTRY 0, 4, $8100
    VERIFY 0, 100, $11
    VERIFY 4, 256, $22
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 10: the defragmenter and block splitting.
.proc testSplit
    jsr splitSetup

    ; Bigger than the remainder. The defragmenter runs again: the spare
    ; entry after the remainder does not end its run, K1 does.
    EXPECT_OOM 60
    ENTRY 0, 2, $0032
    ENTRY 0, 3, $8000

    ; The remainder is reused for its exact size
    ALLOC_AT 6, 50, B0+350
    ENTRY 0, 2, $8032

    ; Nothing is free. The defragmenter passes over the spare entry.
    EXPECT_OOM 1

    ; Split the remainder into the spare entry
    FREE 6
    ENTRY 0, 2, $0032
    ALLOC_AT 7, 30, B0+350
    ENTRY 0, 2, $801e
    ENTRY 0, 3, $0014
    ENTRY 0, 4, $8100

    ; The 20-byte remainder cannot be split again: the entry after it is K1,
    ; which is allocated (with a low byte of 0)
    EXPECT_OOM 10
    ENTRY 0, 3, $0014

    ALLOC_AT 8, 20, B0+380
    ENTRY 0, 3, $8014

    ; A free block followed by an allocated entry with a nonzero low byte
    FREE 7
    ENTRY 0, 2, $001e
    EXPECT_OOM 10
    ENTRY 0, 2, $001e

    ; None of the blocks overlap
    FILL 5, 250, $33
    FILL 8, 20, $44
    VERIFY 0, 100, $11
    VERIFY 5, 250, $33
    VERIFY 8, 20, $44
    VERIFY 4, 256, $22
    ENTRY 0, 0, $8064
    ENTRY 0, 1, $80fa
    ENTRY 0, 4, $8100
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 11: freeing a block after a spare entry, and trimming spare entries
; from the end of the MAT.
.proc testSplitTrim
    jsr splitSetup

    ; heapFree and the debug check have to skip the spare entry to work out
    ; K1's address
    FREE 4
    ENTRY 0, 3, $8000
    ENTRY 0, 4, $0100
    VERIFY 0, 100, $11

    ; Freeing the fillers after K1 trims them, K1, the spare entry, and the
    ; free remainder
    FREE_FILLERS 0
    MAT 0, $8064, $80fa

    ; A new block goes after the last allocated one
    FILLMEM B0+350, 100, $55
    ALLOC_AT 6, 100, B0+350
    VERIFY 6, 100, 0
    MAT 0, $8064, $80fa, $8064
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 12: a merged run must fit in 15 bits. A run that reaches $7fff is
; merged. A free block that would take it past $7fff starts a new run.
.proc testRunLimit
    ALLOC_AT 0, 10, B0                  ; K0
    ALLOC_AT 1, $4000, B0+10
    ALLOC_AT 2, $3fff, B0+$400a
    ALLOC_AT 3, $1000, B0+$8009
    ALLOC_AT 4, $10, B0+$9009
    ALLOC_AT 5, 10, B0+$9019            ; K1
    FILL 0, 10, $a0
    FILL 5, 10, $a5
    CLOSE 0
    ALLOC_AT 6, 10, B1                  ; K2
    ALLOC_AT 7, $4000, B1+10
    ALLOC_AT 8, $4000, B1+$400a
    ALLOC_AT 9, 10, B1+$800a            ; K3
    FILL 6, 10, $a6
    FILL 9, 10, $a9
    CLOSE 1
    CLOSE 2
    FREE 1
    FREE 2
    FREE 3
    FREE 4
    FREE 7
    FREE 8

    ; No free block is $7fff bytes. After defragmenting, the first run in
    ; bank 0 is exactly that.
    ALLOC_AT 10, $7fff, B0+10
    ENTRY 0, 0, $800a
    ENTRY 0, 1, $ffff
    ENTRY 0, 2, $8000
    ENTRY 0, 3, $1010
    ENTRY 0, 4, $8000
    ENTRY 0, 5, $800a
    ; In bank 1 the two blocks add up to $8000, so they stay apart
    ENTRY 1, 0, $800a
    ENTRY 1, 1, $4000
    ENTRY 1, 2, $4000
    ENTRY 1, 3, $800a

    ; The second run in bank 0 is reused for its exact size
    ALLOC_AT 11, $1010, B0+$8009
    ENTRY 0, 3, $9010

    ; The free blocks in bank 1 are followed by a free entry, not a spare
    ; one, so they cannot be split
    EXPECT_OOM $3000
    ENTRY 1, 1, $4000
    ENTRY 1, 2, $4000

    VERIFY 0, 10, $a0
    VERIFY 5, 10, $a5
    VERIFY 6, 10, $a6
    VERIFY 9, 10, $a9
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 13: a free run at the very end of a MAT. That cannot happen after
; heapFree, which trims free entries from the end, but clearMemHeap keeps the
; first entry even if it is free.
.proc testEndRun
    ALLOC_AT 0, $7ff0, B0
    ALLOC_AT 1, 10, B0+$7ff0
    FREE 0
    MAT 0, $7ff0, $800a
    jsr clearMemHeap
    MAT 0, $7ff0

    ; Bank 0 has $3006 bytes left after the free block
    CLOSE 1
    CLOSE 2
    EXPECT_OOM $7ff8
    MAT 0, $7ff0

    ; The heap has been defragmented, so blocks can be split. The free block
    ; is followed by the terminator, which is not a spare entry.
    ALLOC_AT 2, $10, B0+$7ff0
    MAT 0, $7ff0, $8010
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 14: clearMemHeap keeps only the first block of bank 0 (asmlib keeps
; the compiler's error messages there) and empties the other banks.
.proc testClear
    ALLOC_AT 0, 100, B0
    FILL 0, 100, $ab
    ALLOC_AT 1, 200, B0+100
    FILL 1, 200, $cd
    CLOSE 0
    ALLOC_AT 2, 300, B1
    CLOSE 1
    ALLOC_AT 3, 10, B2
    jsr clearMemHeap
    MAT 0, $8064
    MAT 1
    MAT 2
    VERIFY 0, 100, $ab

    ; Freed space is zeroed when it is used again
    ALLOC_AT 4, 50, B0+100
    VERIFY 4, 50, 0
    ALLOC_AT 5, 50, B0+150
    MAT 0, $8064, $8032, $8032
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 15: freeing memory that is not allocated. With asmlib built with
; MEMCHECK=1, heapFree checks first and executes BRK. The heap must be
; unchanged.
.proc testBadFree
    ALLOC_AT 0, 10, B0
    ALLOC_AT 1, 10, B0+10
    ALLOC_AT 2, 10, B0+20
    FREE 0
    MAT 0, $000a, $800a, $800a

    EXPECT_BRK B0                       ; already free
    EXPECT_BRK B0+15                    ; inside a block
    EXPECT_BRK B0+30                    ; past the last block
    EXPECT_BRK B2                       ; a bank with an empty MAT
    EXPECT_BRK $30000                   ; between banks
    MAT 0, $000a, $800a, $800a
    MAT 1
    MAT 2

    FREE 1
    FREE 2
    MAT 0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 17: a size of zero allocates one byte. Otherwise its MAT entry would be
; $00 $80, which is a spare entry, and the block would share its address with
; the next block.
.proc testZeroSize
    FILLMEM B0, 4, $ff
    ALLOC_AT 0, 0, B0
    ALLOC_AT 1, 0, B0+1
    ALLOC_AT 2, 10, B0+2
    MAT 0, $8001, $8001, $800a
    VERIFY 0, 1, 0
    VERIFY 1, 1, 0

    ; Each has a block of its own, so freeing one frees only that one
    FREE 1
    MAT 0, $8001, $0001, $800a

    ; A free one-byte block is reused for a size of zero
    ALLOC_AT 3, 0, B0+1
    MAT 0, $8001, $8001, $800a

    FREE 0
    FREE 3
    FREE 2
    MAT 0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 18: a size of $8000 or more does not fit in a MAT entry, so it is out
; of memory and the heap is unchanged.
.proc testTooBig
    ALLOC_AT 0, 10, B0
    EXPECT_OOM $8000
    EXPECT_OOM $8001
    EXPECT_OOM $ffff
    MAT 0, $800a
    MAT 1
    MAT 2

    ; The largest size still works
    ALLOC_AT 1, $7fff, B0+10
    MAT 0, $800a, $ffff
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 19: freeing an address above the last bank. It is not in any bank, so
; it is not allocated (the debug check executes BRK) and the heap is
; unchanged.
.proc testFreeAbove
    ALLOC_AT 0, 10, B0
    ALLOC_AT 1, 10, B0+10
    EXPECT_BRK T2                       ; the top of the last bank
    EXPECT_BRK $5f000                   ; the runtime stack
    EXPECT_BRK $ffffff
    EXPECT_BRK $ffffffff
    MAT 0, $800a, $800a
    MAT 1
    MAT 2
    FREE 1
    FREE 0
    MAT 0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 20: clearMemHeap on an empty heap. There is no first entry to keep, so
; the MAT stays empty and blocks come from the bottom of the heap.
.proc testClearEmpty
    jsr clearMemHeap
    MAT 0
    MAT 1
    MAT 2
    ALLOC_AT 0, 10, B0
    MAT 0, $800a
    FREE 0
    MAT 0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 21: a MAT with more entries than heapFree's checkpoints cover (64
; checkpoints, 128 entries apart, in memheap.s). Blocks past the last
; checkpoint, between checkpoints and at the first entry are freed and
; reused. Then they are all freed from the last, which trims each one.
MANY_BIG = 8262
.proc testManyBig
    SET32 runAddr, B0
    lda #<MANY_BIG
    sta loopCnt16
    lda #>MANY_BIG
    sta loopCnt16+1
L1: lda #1
    ldx #0
    jsr heapAlloc
    stq gotVal
    ldq runAddr
    stq expVal
    jsr cmpAddr
    jsr incRunAddr
    jsr decLoopCnt16
    bne L1

    ; Past the last checkpoint
    FREE_AT B0+8250
    ALLOC_AT 0, 1, B0+8250
    ; Between checkpoints
    FREE_AT B0+1000
    ALLOC_AT 1, 1, B0+1000
    ; The first entry, which is a checkpoint
    FREE_AT B0
    ENTRY 0, 0, $0001
    ALLOC_AT 2, 1, B0
    ENTRY 0, 0, $8001

    ; Free them all from the last
    SET32 runAddr, B0+MANY_BIG-1
    lda #<MANY_BIG
    sta loopCnt16
    lda #>MANY_BIG
    sta loopCnt16+1
L2: ldq runAddr
    jsr heapFree
    lda runAddr             ; runAddr stays above B0, so 16 bits will do
    bne :+
    dec runAddr+1
:   dec runAddr
    jsr decLoopCnt16
    bne L2
    MAT 0
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 22: a split whose remainder goes into a spare entry that has a
; checkpoint (entry 128). The split moves the entry's block, so heapFree's
; checkpoint for it must move too (verifyHeap checks it).
.proc testSplitCheckpoint
    ; Entries 0 to 126 are one-byte blocks
    SET32 runAddr, B0
    lda #0
    sta loopCnt
L1: lda #1
    ldx #0
    jsr heapAlloc
    stq gotVal
    ldq runAddr
    stq expVal
    jsr cmpAddr
    jsr incRunAddr
    inc loopCnt
    lda loopCnt
    cmp #127
    bne L1

    ALLOC_AT 1, 100, B0+127             ; entry 127
    ALLOC_AT 2, 100, B0+227             ; entry 128, a checkpoint
    ALLOC_AT 3, 256, B0+327             ; entry 129
    CLOSE 0
    CLOSE 1
    CLOSE 2
    FREE 1
    FREE 2
    ENTRY 0, 127, $0064
    ENTRY 0, 128, $0064

    ; The heap is full. The defragmenter merges entries 127 and 128, so
    ; entry 128 becomes a spare entry. The split puts the 50-byte remainder
    ; in it, which moves its block from B0+327 to B0+277.
    ALLOC_AT 4, 150, B0+127
    ENTRY 0, 127, $8096
    ENTRY 0, 128, $0032
    ENTRY 0, 129, $8100

    ; The remainder is found and reused from its checkpoint
    ALLOC_AT 5, 50, B0+277
    ENTRY 0, 128, $8032
    FREE 5
    ENTRY 0, 128, $0032
    ; and so is the block after it
    FREE 3
    ENTRY 0, 129, $0100
    rts
.endproc

; Subtracts one from loopCnt16. The Z flag is set if it is then zero.
.proc decLoopCnt16
    lda loopCnt16
    bne :+
    dec loopCnt16+1
:   dec loopCnt16
    lda loopCnt16
    ora loopCnt16+1
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 16: a stress test of the defragmenter.
;
; Phase 1 allocates groups of one "keeper" block and three "spacer" blocks,
; all the same size, until most of the heap is used. Then the spacers are
; freed, which leaves a run of three adjacent free blocks beside every keeper.
; Phase 2 allocates more blocks than there is fresh heap left. Each is smaller
; than a free run but larger than any single free block, so most of them come
; from splitting merged runs.
;
; Every block starts with a pointer to the previous block on its chain. The
; rest of the block is filled with a value that identifies the block.
.proc testStress
    jsr phase1
    jsr phase2
    jsr phase3
    MAT 0
    MAT 1
    MAT 2
    rts
.endproc

; Allocates the groups of keepers and spacers, then frees the spacers
.proc phase1
    lda #0
    sta groupNum
    ldx #3
:   sta keepHead,x
    sta spacerHead,x
    dex
    bpl :-

L1: inc groupNum

    ; The keeper is filled with the group number
    lda #<BLOCK_SIZE
    ldx #>BLOCK_SIZE
    jsr setSize
    jsr allocBlock
    lda #<keepHead
    ldx #>keepHead
    jsr chainPush
    lda groupNum
    jsr fillBlock

    ; Three spacers
    lda #3
    sta spacerNum
L2: jsr allocBlock
    lda #<spacerHead
    ldx #>spacerHead
    jsr chainPush
    dec spacerNum
    bne L2

    lda groupNum
    cmp #GROUPS
    bne L1

    lda #<spacerHead
    ldx #>spacerHead
    jmp freeChain
.endproc

; Allocates blocks bigger than a spacer. The fresh heap runs out part way
; through, so the rest have to come from the free runs.
.proc phase2
    lda #0
    sta newNum
    ldx #3
:   sta newHead,x
    dex
    bpl :-

    lda #<NEW_SIZE
    ldx #>NEW_SIZE
    jsr setSize

L1: jsr allocBlock

    ; Memory from the heap is supposed to be zeroed. That includes the
    ; part of a free block that was left over from a split.
    lda #0
    sta fillVal
    jsr setRange
    jsr checkContent

    lda #<newHead
    ldx #>newHead
    jsr chainPush
    inc newNum
    lda newNum
    clc
    adc #$80
    jsr fillBlock

    lda newNum
    cmp #NEW_COUNT
    bne L1

    ; Check the blocks from both phases. A block that overlaps another one
    ; will have had its contents overwritten.
    lda #<BLOCK_SIZE
    ldx #>BLOCK_SIZE
    jsr setSize
    lda #<keepHead
    ldx #>keepHead
    ldy #GROUPS
    jsr verifyChain

    lda #<NEW_SIZE
    ldx #>NEW_SIZE
    jsr setSize
    lda #<newHead
    ldx #>newHead
    ldy #NEW_COUNT+$80
    jmp verifyChain
.endproc

; Frees everything and checks the heap is usable. With all the blocks
; freed the heap is empty again, so one large block has to fit.
.proc phase3
    lda #<newHead
    ldx #>newHead
    jsr freeChain
    lda #<keepHead
    ldx #>keepHead
    jsr freeChain

    lda #<BIG_SIZE
    ldx #>BIG_SIZE
    jsr setSize
    jsr allocBlock
    ldq blk
    stq gotVal
    SET32 expVal, B0
    jsr cmpAddr
    ldq blk
    jmp heapFree
.endproc

; Allocates a block of blkSize bytes and returns it in blk.
.proc allocBlock
    lda blkSize
    ldx blkSize+1
    jsr heapAlloc
    stq blk
    rts
.endproc

; Sets the block size used by allocBlock, setRange, and fillBlock from A/X
.proc setSize
    sta blkSize
    stx blkSize+1
    rts
.endproc

; Points ptr1 at blk + A and sets cnt to the number of bytes after that in
; the block.
.proc setRange
    sta tmp1
    ldq blk
    stq ptr1
    ldx tmp1
    beq :++
:   jsr incPtr1
    dex
    bne :-
:   sec
    lda blkSize
    sbc tmp1
    sta cnt
    lda blkSize+1
    sbc #0
    sta cnt+1
    rts
.endproc

; Reads the four byte value at ptr1 into ptrVal
.proc readPtr
    ldx #0
    ldz #0
:   nop
    lda (ptr1),z
    sta ptrVal,x
    inx
    inz
    cpx #4
    bne :-
    rts
.endproc

; Sets ptr1 to the address in A/X, in the bottom 64K
.proc setPtr1
    sta ptr1
    stx ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    rts
.endproc

; Adds the block in blk to the chain whose head is at A/X. The head is a
; four byte value. The block's first four bytes get the old head.
.proc chainPush
    jsr setPtr1
    jsr readPtr             ; ptrVal = old head
    ldq blk
    stq ptr2
    ldx #0
    ldz #0
:   lda ptrVal,x
    nop
    sta (ptr2),z            ; blk's header = old head
    inx
    inz
    cpx #4
    bne :-

    ; The head is now blk. ptr1 still points at the head.
    ldx #0
    ldz #0
:   lda blk,x
    nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    rts
.endproc

; Fills the block in blk, after its header, with the value in A.
.proc fillBlock
    sta fillVal
    lda #HEADER
    jsr setRange
    jmp fillRange
.endproc

; Walks the chain whose head is at A/X. The first block on the chain is
; filled with the value in Y, and each block after it with one less. The
; block size is in blkSize.
.proc verifyChain
    sty expect
    jsr setPtr1
    jsr readPtr
    ldq ptrVal
    stq cur

L1: ldq cur
    jsr isQZero
    beq done
    ldq cur
    stq blk
    lda #HEADER
    jsr setRange
    lda expect
    sta fillVal
    jsr checkContent

    ; cur = the block's chain pointer
    ldq blk
    stq ptr1
    jsr readPtr
    ldq ptrVal
    stq cur
    dec expect
    bra L1
done:
    rts
.endproc

; Frees every block on the chain whose head is at A/X. The head is cleared.
.proc freeChain
    sta headPtr
    stx headPtr+1
    jsr setPtr1
    jsr readPtr
    ldq ptrVal
    stq cur

L1: ldq cur
    jsr isQZero
    beq done

    ; next = the block's chain pointer
    ldq cur
    stq ptr1
    jsr readPtr
    ldq ptrVal
    stq next

    ldq cur
    jsr heapFree
    ldq next
    stq cur
    bra L1

done:
    ; Clear the head variable
    lda headPtr
    ldx headPtr+1
    jsr setPtr1
    lda #0
    ldz #0
:   nop
    sta (ptr1),z
    inz
    cpz #4
    bne :-
    rts
.endproc

;-----------------------------------------------------------------------------
; Test helpers

; Allocates A/X bytes and keeps the pointer in blk and slot Y
.proc allocSlot
    sty slotNum
    jsr heapAlloc
    stq blk
    lda slotNum
    asl a
    asl a
    tax
    ldy #0
:   lda blk,y
    sta slots,x
    inx
    iny
    cpy #4
    bne :-
    rts
.endproc

; Copies slot Y into blk
.proc loadSlot
    tya
    asl a
    asl a
    tax
    ldy #0
:   lda slots,x
    sta blk,y
    inx
    iny
    cpy #4
    bne :-
    rts
.endproc

; Checks that slot Y holds the address in expVal
.proc expectSlot
    jsr loadSlot
    ldq blk
    stq gotVal
    jmp cmpAddr
.endproc

; Frees the block in slot Y
.proc freeSlot
    jsr loadSlot
    ldq blk
    jmp heapFree
.endproc

; Frees the block at the address in expVal
.proc freeExp
    ldq expVal
    jmp heapFree
.endproc

; Checks that entry X of the MAT of bank A is the low word of expVal
.proc expectEntry
    stx entryIdx
    jsr getMemHeapForBank
    stq ptr1
    lda entryIdx
    asl a
    sta tmpWord
    lda #0
    rol a
    sta tmpWord+1
    sec
    lda ptr1
    sbc tmpWord
    sta ptr1
    lda ptr1+1
    sbc tmpWord+1
    sta ptr1+1
    lda ptr1+2
    sbc #0
    sta ptr1+2
    lda ptr1+3
    sbc #0
    sta ptr1+3
    ldz #0
    nop
    lda (ptr1),z
    sta gotVal
    inz
    nop
    lda (ptr1),z
    sta gotVal+1
    lda #0
    sta gotVal+2
    sta gotVal+3
    lda #<msgEntry
    ldx #>msgEntry
    jmp compare
.endproc

; Points ptr1 at the block in slot Y and sets cnt to A/X
.proc slotRange
    sta cnt
    stx cnt+1
    jsr loadSlot
    ldq blk
    stq ptr1
    rts
.endproc

; Points ptr1 at memAddr and sets cnt to A/X
.proc memRange
    sta cnt
    stx cnt+1
    ldq memAddr
    stq ptr1
    rts
.endproc

.proc fillSlot
    jsr slotRange
    jmp fillRange
.endproc

.proc verifySlot
    jsr slotRange
    jmp checkContent
.endproc

.proc fillMem
    jsr memRange
    jmp fillRange
.endproc

.proc checkMem
    jsr memRange
    jmp checkContent
.endproc

; Fills cnt bytes from ptr1 with fillVal
.proc fillRange
L1: lda cnt
    ora cnt+1
    beq L3
    lda fillVal
    ldz #0
    nop
    sta (ptr1),z
    jsr incPtr1
    lda cnt
    bne L2
    dec cnt+1
L2: dec cnt
    bra L1
L3: rts
.endproc

; Checks that cnt bytes from ptr1 are all fillVal
.proc checkContent
    jsr countCheck
L1: lda cnt
    ora cnt+1
    beq L3
    ldz #0
    nop
    lda (ptr1),z
    cmp fillVal
    bne bad
    jsr incPtr1
    lda cnt
    bne L2
    dec cnt+1
L2: dec cnt
    bra L1
L3: rts
bad:
    sta gotVal
    lda fillVal
    sta expVal
    lda #0
    sta gotVal+1
    sta gotVal+2
    sta gotVal+3
    sta expVal+1
    sta expVal+2
    sta expVal+3
    lda #<msgContent
    sta failMsg
    lda #>msgContent
    sta failMsg+1
    jmp failNow
.endproc

.proc incPtr1
    inc ptr1
    bne :+
    inc ptr1+1
    bne :+
    inc ptr1+2
    bne :+
    inc ptr1+3
:   rts
.endproc

.proc incRunAddr
    inc runAddr
    bne :+
    inc runAddr+1
    bne :+
    inc runAddr+2
    bne :+
    inc runAddr+3
:   rts
.endproc

.proc countCheck
    inc checkNum
    bne :+
    inc checkNum+1
:   rts
.endproc

.proc cmpAddr
    lda #<msgAddr
    ldx #>msgAddr
    jmp compare
.endproc

.proc cmpBankTop
    lda #<msgBank
    ldx #>msgBank
    jmp compare
.endproc

; Compares expVal and gotVal. If they differ the message in A/X is printed
; and the test fails.
.proc compare
    sta failMsg
    stx failMsg+1
    jsr countCheck
    ldx #3
:   lda expVal,x
    cmp gotVal,x
    bne :+
    dex
    bpl :-
    rts
:   jmp failNow
.endproc

; Allocates A/X bytes. If that runs out of memory the carry is set.
; Otherwise the carry is clear and the block is in blk.
.proc tryAlloc
    sta sizeArg
    stx sizeArg+1
    lda #<caught
    sta exitHandler
    lda #>caught
    sta exitHandler+1
    ; asmlib's exit routine restores this stack pointer before it jumps to
    ; exitHandler, so caught returns to tryAlloc's caller
    tsx
    stx savedStackPtr
    lda sizeArg
    ldx sizeArg+1
    jsr heapAlloc
    stq blk
    jsr restoreExit
    clc
    rts
caught:
    jsr restoreExit
    sec
    rts
.endproc

; Checks that allocating A/X bytes runs out of memory
.proc expectOOM
    jsr tryAlloc
    php
    jsr countCheck
    plp
    bcs :+
    ldq blk
    stq gotVal
    SET32 expVal, 0
    lda #<msgNoOOM
    sta failMsg
    lda #>msgNoOOM
    sta failMsg+1
    jmp failNow
:   rts
.endproc

; Makes a runtime error fail the test
.proc restoreExit
    lda #<unexpectedExit
    sta exitHandler
    lda #>unexpectedExit
    sta exitHandler+1
    lda mainSP
    sta savedStackPtr
    rts
.endproc

.proc unexpectedExit
    SET32 expVal, 0
    SET32 gotVal, 0
    lda #<msgExit
    sta failMsg
    lda #>msgExit
    sta failMsg+1
    jmp failNow
.endproc

; Checks that freeing the address in expVal executes BRK, and that the BRK
; is heapFree's memory check (code $22)
.proc expectBrk
    jsr countCheck
    lda #<caught
    sta brkCatch
    lda #>caught
    sta brkCatch+1
    ; caught restores this stack pointer, so it returns to expectBrk's caller
    tsx
    stx brkSP
    ldq expVal
    jsr heapFree
    lda #0
    sta brkCatch
    sta brkCatch+1
    SET32 gotVal, 0
    lda #<msgNoBrk
    sta failMsg
    lda #>msgNoBrk
    sta failMsg+1
    jmp failNow

    ; testresult.s's brkTrap jumps here
caught:
    ldx brkSP
    txs
    lda #0
    sta brkCatch
    sta brkCatch+1
    SET32 expVal, $22
    SET32 gotVal, 0
    lda brkCode
    sta gotVal
    lda #<msgBrkCode
    ldx #>msgBrkCode
    jmp compare
.endproc

; Works out the space left at the end of bank A for a new block. Sets
; nextAddr to where the next new block would go (the end of the last block)
; and remain to the most it could hold. remain is negative if no block fits.
.proc bankInfo
    jsr getMemHeapForBank
    stq ptr3                ; The current MAT entry
    stq remain
    lda #0
    sta used
    sta used+1
    sta used+2
    sta used+3

L1: ldz #0
    nop
    lda (ptr3),z
    sta entryVal
    inz
    nop
    lda (ptr3),z
    sta entryVal+1
    ora entryVal
    beq L2

    ; used += the size in the entry
    clc
    lda used
    adc entryVal
    sta used
    lda entryVal+1
    and #$7f
    adc used+1
    sta used+1
    lda used+2
    adc #0
    sta used+2

    ; Each entry moves the terminator down two bytes
    jsr sub2Remain
    sec
    lda ptr3
    sbc #2
    sta ptr3
    lda ptr3+1
    sbc #0
    sta ptr3+1
    lda ptr3+2
    sbc #0
    sta ptr3+2
    lda ptr3+3
    sbc #0
    sta ptr3+3
    bra L1

    ; remain is the terminator's address. The new block has to end at or
    ; below the new terminator, two bytes lower.
L2: jsr sub2Remain

    ; nextAddr = heapBottom + used
    clc
    ldx #0
:   lda heapBottom,x
    adc used,x
    sta nextAddr,x
    inx
    txa
    eor #4
    bne :-

    ; remain -= nextAddr
    sec
    ldx #0
:   lda remain,x
    sbc nextAddr,x
    sta remain,x
    inx
    txa
    eor #4
    bne :-
    rts
.endproc

.proc sub2Remain
    sec
    lda remain
    sbc #2
    sta remain
    lda remain+1
    sbc #0
    sta remain+1
    lda remain+2
    sbc #0
    sta remain+2
    lda remain+3
    sbc #0
    sta remain+3
    rts
.endproc

; Allocates filler blocks until no block of any size fits at the end of bank
; A. The bank before it must already be full and the heap must have no free
; blocks of the filler sizes. Each filler is checked to land where expected.
.proc closeBank
    sta cbBank
    tax
    lda #0
    sta fillerCount,x

L1: lda cbBank
    jsr bankInfo
    lda remain+3
    bmi L4                  ; Nothing fits
    ora remain+2
    ora remain+1
    ora remain
    beq L4                  ; Nothing fits

    ; size = the smaller of remain and $7fff
    lda remain+3
    ora remain+2
    bne L2
    lda remain+1
    bmi L2
    lda remain
    ldx remain+1
    bra L3
L2: lda #$ff
    ldx #$7f
L3: jsr heapAlloc
    stq blk
    stq gotVal
    ldq nextAddr
    stq expVal
    lda #<msgFiller
    ldx #>msgFiller
    jsr compare

    ; Remember the filler
    ldx cbBank
    lda fillerCount,x
    cmp #MAX_FILLERS
    bcs L1
    inc fillerCount,x
    jsr fillerOffset
    ldy #0
:   lda blk,y
    sta fillers,x
    inx
    iny
    cpy #4
    bne :-
    bra L1

L4: rts
.endproc

; Sets X to the offset in fillers of filler fillerCount-1 of bank cbBank
.proc fillerOffset
    ldx cbBank
    lda fillerCount,x
    sec
    sbc #1
    asl a
    asl a
    sta tmpWord
    txa
    asl a
    asl a
    asl a
    asl a                   ; MAX_FILLERS * 4 bytes per bank
    clc
    adc tmpWord
    tax
    rts
.endproc

; Frees the fillers of bank A, the first one first
.proc freeFillers
    sta cbBank
    lda #0
    sta loopCnt
L1: ldx cbBank
    lda loopCnt
    cmp fillerCount,x
    beq L2
    ; X = cbBank * 16 + loopCnt * 4
    txa
    asl a
    asl a
    sta tmpWord
    lda loopCnt
    clc
    adc tmpWord
    asl a
    asl a
    tax
    ldy #0
:   lda fillers,x
    sta blk,y
    inx
    iny
    cpy #4
    bne :-
    ldq blk
    jsr heapFree
    inc loopCnt
    bra L1
L2: ldx cbBank
    lda #0
    sta fillerCount,x
    rts
.endproc

; Prints the failure and fails the test
.proc failNow
    jsr restoreExit
    lda #13
    jsr CHROUT
    lda #<msgTest
    ldx #>msgTest
    jsr printStr
    lda testNum
    jsr printHex
    lda #<msgCheck
    ldx #>msgCheck
    jsr printStr
    lda checkNum+1
    jsr printHex
    lda checkNum
    jsr printHex
    lda #':'
    jsr CHROUT
    lda #' '
    jsr CHROUT
    lda failMsg
    ldx failMsg+1
    jsr printStr
    lda #13
    jsr CHROUT
    lda #<msgExp
    ldx #>msgExp
    jsr printStr
    ldx #3
:   lda expVal,x
    phx
    jsr printHex
    plx
    dex
    bpl :-
    lda #<msgGot
    ldx #>msgGot
    jsr printStr
    ldx #3
:   lda gotVal,x
    phx
    jsr printHex
    plx
    dex
    bpl :-
    lda #13
    jsr CHROUT
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
    adc #6                  ; The carry is set: 10 + 6 + 1 + '0' = 'a'
:   adc #'0'
    jmp CHROUT
.endproc

.bss

; Test state
testIdx: .res 1
testNum: .res 1
testVec: .res 2
checkNum: .res 2
mainSP: .res 1
brkSP: .res 1
failMsg: .res 2
expVal: .res 4
gotVal: .res 4

; Helper state
slots: .res NUM_SLOTS * 4
slotNum: .res 1
sizeArg: .res 2
memAddr: .res 4
runAddr: .res 4
loopCnt: .res 1
loopCnt16: .res 2
entryIdx: .res 1
entryVal: .res 2
tmpWord: .res 2
used: .res 4
remain: .res 4
nextAddr: .res 4
cbBank: .res 1
fillerCount: .res NUM_BANKS
fillers: .res NUM_BANKS * MAX_FILLERS * 4

; Stress test state
blk: .res 4
cur: .res 4
next: .res 4
ptrVal: .res 4
keepHead: .res 4
spacerHead: .res 4
newHead: .res 4
headPtr: .res 2
blkSize: .res 2
cnt: .res 2
fillVal: .res 1
expect: .res 1
groupNum: .res 1
spacerNum: .res 1
newNum: .res 1

.data

msgTest: .asciiz "test "
msgCheck: .asciiz " check "
msgExp: .asciiz "exp "
msgGot: .asciiz " got "
msgAddr: .asciiz "wrong block address"
msgEntry: .asciiz "wrong mat entry"
msgBank: .asciiz "wrong bank info"
msgContent: .asciiz "wrong block contents"
msgFiller: .asciiz "filler misplaced"
msgNoOOM: .asciiz "expected out of memory"
msgNoBrk: .asciiz "no brk for bad free. build asmlib with memcheck=1"
msgBrkCode: .asciiz "brk was not heapfree's check"
msgExit: .asciiz "unexpected runtime error"
