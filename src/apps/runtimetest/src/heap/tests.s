;
; tests.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The runtime heap tests, in the script language of heap.inc. A failure
; names the test (its number in the table, from 1) and the step in it.
;
; The MAT grows down from the heap's top, four bytes an entry. Most tests
; use HB to HT, where the MAT's entries are at $710A, $7106, $7102, $70FE,
; $70FA, ... so the walks and moves cross a page boundary.

.include "heap.inc"

.export tests

HB = $7000
HT = $710a

.data

tests:
    .addr tInit             ; 1
    .addr tFirst            ; 2
    .addr tSequence         ; 3
    .addr tSizeFF           ; 4
    .addr tTrimLast         ; 5
    .addr tFreeOnly         ; 6
    .addr tFreeMiddle       ; 7
    .addr tAddrHigh         ; 8
    .addr tFreeUnknown      ; 9
    .addr tMergeNext        ; 10
    .addr tMergePrev        ; 11
    .addr tMergeBoth        ; 12
    .addr tMergeFirst       ; 13
    .addr tMergeTrim        ; 14
    .addr tFreeAll          ; 15
    .addr tBestFit          ; 16
    .addr tSplitNoRoomHi    ; 17
    .addr tSplitNoRoomLo    ; 18
    .addr tSplitJustFits    ; 19
    .addr tMerge8000        ; 20
    .addr tMerge7FFF        ; 21
    .addr tTrimTwo          ; 22
    .addr tOomFirst         ; 23
    .addr tOomNext          ; 24
    .addr tOomReuse         ; 25
    .addr tStress           ; 26
    .addr tStressSmall      ; 27
    .addr tStressTiny       ; 28
    .addr tOomFreed         ; 29
    .addr tOomLastFree      ; 30
    .addr tOomWrap          ; 31
    .addr tOomHuge          ; 32
    .addr 0

; heapInit makes an empty MAT, and the special call returns its top
tInit:
    INIT HB, HT
    MAT 0
    TOP
    MAT 0
    TEND

; The first block is at the heap's bottom
tFirst:
    INIT HB, HT
    ALLOC 10, $7000
    MAT 1
    USED 10, $7000
    TEND

; Each new block follows the last
tSequence:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    ALLOC 1, $701e
    MAT 3
    USED 10, $7000
    USED 20, $700a
    USED 1, $701e
    TEND

; $00FF isn't the special call ($FFFF). The block's end crosses a page.
tSizeFF:
    INIT HB, HT
    ALLOC $ff, $7000
    MAT 1
    USED $ff, $7000
    TEND

; Freeing the last block removes its entry
tTrimLast:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    FREE $700a
    MAT 1
    USED 10, $7000
    TEND

; Freeing the only block empties the MAT
tFreeOnly:
    INIT HB, HT
    ALLOC 10, $7000
    FREE $7000
    MAT 0
    ALLOC 10, $7000
    MAT 1
    USED 10, $7000
    TEND

; A freed block between two allocated ones stays, and freeing it again
; changes nothing
tFreeMiddle:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    ALLOC 30, $701e
    FREE $700a
    MAT 3
    USED 10, $7000
    AVAIL 20, $700a
    USED 30, $701e
    FREE $700a
    MAT 3
    USED 10, $7000
    AVAIL 20, $700a
    USED 30, $701e
    TEND

; heapFree compares both bytes of the address: $7000's low byte matches
; $7100's
tAddrHigh:
    INIT HB, $720a
    ALLOC $100, $7000
    ALLOC $10, $7100
    ALLOC 8, $7110
    FREE $7100
    MAT 3
    USED $100, $7000
    AVAIL $10, $7100
    USED 8, $7110
    TEND

; Freeing an address that isn't a block's changes nothing
tFreeUnknown:
    INIT HB, HT
    ALLOC 10, $7000
    FREE $7005
    MAT 1
    USED 10, $7000
    INIT HB, HT
    FREE $7000
    MAT 0
    TEND

; A freed block takes in the free block after it
tMergeNext:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    ALLOC 30, $701e
    ALLOC 5, $703c
    FREE $701e
    MAT 4
    USED 10, $7000
    USED 20, $700a
    AVAIL 30, $701e
    USED 5, $703c
    FREE $700a
    MAT 3
    USED 10, $7000
    AVAIL 50, $700a
    USED 5, $703c
    TEND

; The free block before a freed block takes it in
tMergePrev:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    ALLOC 30, $701e
    ALLOC 5, $703c
    FREE $700a
    FREE $701e
    MAT 3
    USED 10, $7000
    AVAIL 50, $700a
    USED 5, $703c
    TEND

; A freed block between two free blocks makes one block of the three
tMergeBoth:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    ALLOC 30, $701e
    ALLOC 5, $703c
    ALLOC 7, $7041
    FREE $700a
    FREE $703c
    MAT 5
    USED 10, $7000
    AVAIL 20, $700a
    USED 30, $701e
    AVAIL 5, $703c
    USED 7, $7041
    FREE $701e
    MAT 3
    USED 10, $7000
    AVAIL 55, $700a
    USED 7, $7041
    TEND

; The first block has no block before it to merge with
tMergeFirst:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    ALLOC 30, $701e
    FREE $700a
    FREE $7000
    MAT 2
    AVAIL 30, $7000
    USED 30, $701e
    TEND

; The last block merges with the free block before it, which is then
; trimmed
tMergeTrim:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    ALLOC 30, $701e
    FREE $700a
    FREE $701e
    MAT 1
    USED 10, $7000
    TEND

; Freeing every block, first to last, empties the MAT: the first block,
; free, is trimmed too, and the next block starts at the bottom again
tFreeAll:
    INIT HB, HT
    ALLOC 10, $7000
    ALLOC 20, $700a
    ALLOC 30, $701e
    FREE $7000
    MAT 3
    AVAIL 10, $7000
    USED 20, $700a
    USED 30, $701e
    FREE $700a
    MAT 2
    AVAIL 30, $7000
    USED 30, $701e
    FREE $701e
    MAT 0
    ALLOC 70, $7000
    MAT 1
    USED 70, $7000
    TEND

; heapAlloc reuses the smallest free block that's big enough, the first
; of those the same size, and splits it, moving the entries after it down
tBestFit:
    INIT HB, HT
    ALLOC 30, $7000
    ALLOC 5, $701e
    ALLOC 10, $7023
    ALLOC 5, $702d
    ALLOC 20, $7032
    ALLOC 5, $7046
    FREE $7000
    FREE $7023
    FREE $7032
    MAT 6
    AVAIL 30, $7000
    USED 5, $701e
    AVAIL 10, $7023
    USED 5, $702d
    AVAIL 20, $7032
    USED 5, $7046
    ; 20 is the smallest that fits
    ALLOC 15, $7032
    MAT 7
    AVAIL 30, $7000
    USED 5, $701e
    AVAIL 10, $7023
    USED 5, $702d
    USED 15, $7032
    AVAIL 5, $7041
    USED 5, $7046
    ; Only 30 fits. Every entry after the first moves, across a page.
    ALLOC 25, $7000
    MAT 8
    USED 25, $7000
    AVAIL 5, $7019
    USED 5, $701e
    AVAIL 10, $7023
    USED 5, $702d
    USED 15, $7032
    AVAIL 5, $7041
    USED 5, $7046
    ; The first 5 wins over the later 5 and the 10
    ALLOC 3, $7019
    MAT 9
    USED 25, $7000
    USED 3, $7019
    AVAIL 2, $701c
    USED 5, $701e
    AVAIL 10, $7023
    USED 5, $702d
    USED 15, $7032
    AVAIL 5, $7041
    USED 5, $7046
    TEND

; A split needs room for one more entry. Here the zero entry is at $70FE
; and the last block ends at $70FD. The new zero entry would be at $70FA,
; on the block, so the whole free block is used. (The high bytes differ.)
tSplitNoRoomHi:
    INIT HB, $7106
    SETMAT 2
    AVAIL $f0, $7000
    USED $0d, $70f0
    ALLOC 8, $7000
    MAT 2
    USED $f0, $7000
    USED $0d, $70f0
    TEND

; The same with the zero entry at $7108 and the last block ending at
; $7106 (the high bytes are the same)
tSplitNoRoomLo:
    INIT HB, $7110
    SETMAT 2
    AVAIL $100, $7000
    USED 6, $7100
    ALLOC $10, $7000
    MAT 2
    USED $100, $7000
    USED 6, $7100
    TEND

; The zero entry is at $710C and the last block ends at $7108: the new
; zero entry just fits
tSplitJustFits:
    INIT HB, $7114
    SETMAT 2
    AVAIL $100, $7000
    USED 8, $7100
    ALLOC $10, $7000
    MAT 3
    USED $10, $7000
    AVAIL $f0, $7010
    USED 8, $7100
    TEND

; Merged blocks must stay below $8000 bytes, since the size's high bit is
; the allocated bit. The blocks are never written, so they can be outside
; the heap. The freed block merges with the one after it ($4000) but not
; the one before ($8000).
tMerge8000:
    INIT HB, HT
    SETMAT 4
    AVAIL $4000, $1000
    USED $10, $5000
    AVAIL $3ff0, $5010
    USED 8, $9000
    FREE $5000
    MAT 3
    AVAIL $4000, $1000
    AVAIL $4000, $5000
    USED 8, $9000
    TEND

; $7FFF bytes is small enough
tMerge7FFF:
    INIT HB, HT
    SETMAT 4
    AVAIL $3fff, $1000
    USED $10, $4fff
    AVAIL $3ff0, $500f
    USED 8, $8fff
    FREE $4fff
    MAT 2
    AVAIL $7fff, $1000
    USED 8, $8fff
    TEND

; Two free blocks too large to merge are both trimmed from the end
tTrimTwo:
    INIT HB, HT
    SETMAT 4
    USED $10, $1000
    AVAIL $4000, $1010
    AVAIL $4000, $5010
    USED 8, $9010
    FREE $9010
    MAT 1
    USED $10, $1000
    TEND

; With the MAT at $7040, the first block's entry goes there and the zero
; entry at $703C, so a block can end at $703C but not past it
tOomFirst:
    INIT HB, $7040
    OOM $3d
    MAT 0
    ALLOC $3c, $7000
    MAT 1
    USED $3c, $7000
    TEND

; A new block must end at or below the new zero entry. After the first
; block the zero entry is at $703C: a block at $7010 can't reach the next
; zero entry, $7038, and one at $7030 can end just at $7034.
tOomNext:
    INIT HB, $7040
    ALLOC $10, $7000
    OOM $29
    MAT 1
    USED $10, $7000
    ALLOC $20, $7010
    OOM 5
    ALLOC 4, $7030
    MAT 3
    USED $10, $7000
    USED $20, $7010
    USED 4, $7030
    TEND

; A free block too small for the request isn't used, and there's no room
; after the last block
tOomReuse:
    INIT HB, $7040
    ALLOC $10, $7000
    ALLOC $10, $7010
    FREE $7000
    OOM $28
    MAT 2
    AVAIL $10, $7000
    USED $10, $7010
    ALLOC $10, $7000
    MAT 2
    USED $10, $7000
    USED $10, $7010
    TEND

; Random allocations and frees in a heap they never fill
tStress:
    INIT HB, $8f02
    STRESS $1234, 1500, $3f, 0
    TEND

; The same in a heap they fill, so some run out of memory
tStressSmall:
    INIT HB, $7202
    STRESS $ace1, 3000, $3f, 1
    TEND

; Small blocks, many of them
tStressTiny:
    INIT HB, $7082
    STRESS $5a5a, 3000, $07, 1
    TEND

; A freed first block leaves the heap empty, so the whole heap can be
; used again. (Its entry once stayed, the next block went after it, and
; the out of memory check, which measured from the last allocated block,
; gave that block memory in the MAT.)
tOomFreed:
    INIT HB, $7040
    ALLOC $20, $7000
    FREE $7000
    MAT 0
    ALLOC $3c, $7000
    MAT 1
    USED $3c, $7000
    TEND

; The out of memory check measures from the end of the last entry's
; block, even if it's free. The new block's entry goes at $7038 and the
; zero entry at $7034, so a block at $7008 can end at $7034.
tOomLastFree:
    INIT HB, $7040
    SETMAT 2
    USED 4, $7000
    AVAIL 4, $7004
    OOM $2d
    ALLOC $2c, $7008
    MAT 3
    USED 4, $7000
    AVAIL 4, $7004
    USED $2c, $7008
    TEND

; The end of a large request near the top of memory is past $FFFF. (The
; check once added in 16 bits, and it wrapped around and fit.)
tOomWrap:
    INIT $8e00, $8f00
    OOM $7300
    MAT 0
    TEND

; No block can be $8000 bytes or more. (The sizes are compared as signed
; numbers, and such a request once fit in any free block.)
tOomHuge:
    INIT HB, $7040
    ALLOC $10, $7000
    ALLOC 4, $7010
    FREE $7000
    OOM $8000
    OOM $fffe
    MAT 2
    AVAIL $10, $7000
    USED 4, $7010
    TEND
