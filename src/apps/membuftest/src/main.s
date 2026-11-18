;
; main.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tests the membuf routines in asmlib (src/lib/asmlib/src/membuf):
; allocMemBuf, freeMemBuf, writeToMemBuf, readFromMemBuf, setMemBufPos,
; getMemBufPos and isMemBufAtEnd, and initMemBufChunk and membufIsZero,
; which they use.
;
; A membuf is a header and a chain of chunks of MEMBUF_CHUNK_LEN (50) bytes.
; The tests keep a model of each membuf: the bytes it must hold, its position
; and used. WRITE, READ and SEEK do the same thing to the membuf and the
; model, and CHECK compares them. CHECK walks the chunk chain itself rather
; than trusting the read routine, and checks the header: the position
; (getMemBufPos), used, capacity, isMemBufAtEnd, and that the current chunk
; and posChunk are where the position says. CHKCUR then checks which chunk
; that is and posChunk. A chunk holds zeros past what was written (heapAlloc
; zeros it), and so does the model.
;
; Two membufs can be open at once (SELECT), each with its own model.
;
; Each test frees what it allocated, then the leak check runs.
;
; When a check fails the test number, the check number within the test, and
; the expected and actual values are printed, then RESULT: FAIL.
;
; With COVERAGE defined this runs against instrumented copies of the membuf
; routines and saves the coverage map to the disk (see the Makefile).

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "membufasm.inc"
.include "4510macros.inc"

.import initLib
.import testInit, testPass, testFail, testMemCheck, testLeakCheck
.ifdef COVERAGE
.import covInstall, covSave
.endif

CHUNK = MEMBUF_CHUNK_LEN
MODEL_SIZE = 1100           ; The largest membuf a test makes
MARKER = $ee                ; Fills the read buffer, to catch overruns
MAX_FILLERS = 64
BANK0 = $01                 ; Bank byte of the first heap bank ($12000)
BANK1 = $04                 ; Bank byte of the second ($42000)

; Points a 32-bit pointer in zero page at addr in bank 0
.macro PTR zp, addr
    lda #<(addr)
    sta zp
    lda #>(addr)
    sta zp+1
    lda #0
    sta zp+2
    sta zp+3
.endmacro

; Allocates a membuf with allocMemBuf and starts its model empty
.macro NEWBUF
    jsr newBuf
.endmacro

; Frees the membuf with freeMemBuf
.macro FREEBUF
    jsr freeBuf
.endmacro

; Makes membuf n (0 or 1) the one the other macros work on
.macro SELECT n
    lda #n
    jsr selectBuf
.endmacro

; Writes len bytes made from seed (see genSrc) at the position
.macro WRITE len, seed
    lda #seed
    sta seedArg
    lda #<(len)
    ldx #>(len)
    jsr doWrite
.endmacro

; Asks to read len bytes. count is how many it must read.
.macro READ len, count
    .assert (count) <= (len), error, "READ count is more than len"
    lda #<(count)
    sta countArg
    lda #>(count)
    sta countArg+1
    lda #<(len)
    ldx #>(len)
    jsr doRead
.endmacro

; Sets the position to pos. actual is where it must end up, if not pos.
.macro SEEK pos, actual
    .ifblank actual
        lda #<(pos)
        sta countArg
        lda #>(pos)
        sta countArg+1
    .else
        lda #<(actual)
        sta countArg
        lda #>(actual)
        sta countArg+1
    .endif
    lda #<(pos)
    ldx #>(pos)
    jsr doSeek
.endmacro

; Checks the membuf against its model. cap is its capacity.
.macro CHECK cap
    .assert (cap) <= MODEL_SIZE, error, "CHECK capacity is past the model"
    .assert (cap) .mod CHUNK = 0, error, "CHECK capacity is not whole chunks"
    lda #<(cap)
    ldx #>(cap)
    jsr checkBuf
.endmacro

; Checks the current chunk is number idx in the chain ($ff for none) and
; posChunk is pc, as the last CHECK found them
.macro CHKCUR idx, pc
    lda #idx
    ldx #pc
    jsr checkCur
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
    jsr stackInit               ; The heap's memory checks use the stack
    jsr initMemHeap
    jsr testMemCheck

    lda #0
    sta testIdx
    sta fillerCount
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
.ifdef FIRST_TEST
    ; make test TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m" runs only those
    cmp #FIRST_TEST
    bcc L1
    cmp #LAST_TEST+1
    bcs L1
.endif
    lda #0
    sta checkNum
    sta checkNum+1
    sta cur
    lda #<model0
    sta modelBase
    lda #>model0
    sta modelBase+1
    jsr callTest
    ; Every test frees what it allocated
    jsr testLeakCheck
    bcc L1
    lda #0
    sta expW
    sta expW+1
    sta gotW
    sta gotW+1
    sta atW
    sta atW+1
    lda #<msgLeak
    ldx #>msgLeak
    jmp fail

L2:
.ifdef COVERAGE
    jsr covSave
.endif
    jsr testPass
    rts

callTest:
    jmp (testVec)

.data

tests:
    .addr testEmpty         ; 1
    .addr testZeroWrite     ; 2
    .addr testSmall         ; 3
    .addr testFillChunk     ; 4
    .addr testLarge         ; 5
    .addr testOverwrite     ; 6
    .addr testRecords       ; 7
    .addr testSeek          ; 8
    .addr testReads         ; 9
    .addr testTwoBufs       ; 10
    .addr testAligned       ; 11
    .addr testHighBank      ; 12
    .addr 0

.code

;-----------------------------------------------------------------------------
; Test 1: a new membuf has no chunks. Reading it reads nothing, and any
; position is 0. Freeing it frees the header.
.proc testEmpty
    NEWBUF
    CHECK 0
    CHKCUR $ff, 0
    READ 10, 0
    CHECK 0
    SEEK 0
    CHECK 0
    SEEK 100, 0
    CHECK 0
    CHKCUR $ff, 0
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 2: writing nothing to a new membuf still gives it its first chunk.
.proc testZeroWrite
    NEWBUF
    WRITE 0, 1
    CHECK 50
    CHKCUR 0, 0
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 3: writes and reads inside the first chunk. Reading past used reads
; the chunk's zeros, and writing there (even nothing) moves used up.
.proc testSmall
    NEWBUF
    WRITE 10, 2
    CHECK 50
    CHKCUR 0, 10
    SEEK 0
    CHECK 50
    CHKCUR 0, 0
    READ 4, 4
    READ 6, 6
    CHECK 50
    CHKCUR 0, 10
    READ 5, 5
    CHECK 50
    WRITE 0, 3
    CHECK 50
    WRITE 7, 4
    CHECK 50
    CHKCUR 0, 22
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 4: a write that fills a chunk exactly doesn't add one. The next
; write, starting at the end of the chunk, does.
.proc testFillChunk
    NEWBUF
    WRITE 50, 5
    CHECK 50
    CHKCUR 0, 50
    WRITE 1, 6
    CHECK 100
    CHKCUR 1, 1
    WRITE 49, 7
    CHECK 100
    CHKCUR 1, 50
    SEEK 0
    READ 100, 100
    CHECK 100
    CHKCUR 1, 50
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 5: writes and reads of more than 255 bytes, which span many chunks,
; and a seek past 255.
.proc testLarge
    NEWBUF
    WRITE 300, 8
    CHECK 300
    CHKCUR 5, 50
    WRITE 20, 9
    CHECK 350
    CHKCUR 6, 20
    SEEK 275
    CHECK 350
    CHKCUR 5, 25
    READ 30, 30
    CHECK 350
    CHKCUR 6, 5
    SEEK 0
    READ 320, 320
    CHECK 350
    FREEBUF

    ; 1000 bytes in one write, read back 7 bytes at a time
    NEWBUF
    WRITE 1000, 10
    CHECK 1000
    CHKCUR 19, 50
    SEEK 0
    lda #0
    sta recNum
L1: lda #7
    sta countArg
    lda #0
    sta countArg+1
    lda #7
    ldx #0
    jsr doRead
    inc recNum
    lda recNum
    cmp #142
    bne L1
    READ 6, 6
    CHECK 1000
    CHKCUR 19, 50
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 6: writes over what is there, into chunks that are already there.
; The rest of a write that runs into the next chunk must come from the
; caller's bytes after the ones already written.
.proc testOverwrite
    NEWBUF
    WRITE 120, 11
    CHECK 150
    SEEK 45
    WRITE 10, 12            ; 5 bytes in chunk 0, 5 in chunk 1
    CHECK 150
    CHKCUR 1, 5
    SEEK 40
    WRITE 70, 13            ; Through all of chunk 1 into chunk 2
    CHECK 150
    CHKCUR 2, 10
    SEEK 110
    WRITE 30, 14            ; Past used, inside the capacity
    CHECK 150
    CHKCUR 2, 40
    SEEK 140
    WRITE 30, 15            ; Into a new chunk
    CHECK 200
    CHKCUR 3, 20
    SEEK 0
    READ 170, 170
    CHECK 200
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 7: 3-byte records, written once and then overwritten one at a time,
; as the linker keeps its import addresses. Some cross a chunk boundary.
.proc testRecords
    NEWBUF
    WRITE 150, 30
    CHECK 150
    lda #0
    sta recNum
L1: lda recNum
    asl a
    clc
    adc recNum              ; 3 * recNum
    sta countArg
    lda #0
    sta countArg+1
    lda countArg
    ldx #0
    jsr doSeek
    lda recNum
    clc
    adc #100
    sta seedArg
    lda #3
    ldx #0
    jsr doWrite
    inc recNum
    lda recNum
    cmp #50
    bne L1
    CHECK 150
    CHKCUR 2, 50

    ; Records that start one byte before the end of a chunk
    SEEK 49
    WRITE 3, 31
    CHECK 150
    CHKCUR 1, 2
    SEEK 99
    WRITE 3, 32
    CHECK 150
    CHKCUR 2, 2

    ; Read them back one at a time
    SEEK 0
    lda #0
    sta recNum
L2: lda #3
    sta countArg
    lda #0
    sta countArg+1
    lda #3
    ldx #0
    jsr doRead
    inc recNum
    lda recNum
    cmp #50
    bne L2
    CHECK 150
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 8: positions at the end of a chunk are in that chunk, the end of the
; last chunk (capacity) included. Writing there adds a chunk rather than
; writing over the first one. A position past the last chunk is capacity.
.proc testSeek
    NEWBUF
    WRITE 100, 16
    CHECK 100
    CHKCUR 1, 50
    SEEK 50
    CHECK 100
    CHKCUR 0, 50
    READ 10, 10
    CHECK 100
    CHKCUR 1, 10
    SEEK 50
    WRITE 10, 17
    CHECK 100
    CHKCUR 1, 10

    ; The end of the last chunk
    SEEK 100
    CHECK 100
    CHKCUR 1, 50
    READ 5, 0
    CHECK 100
    WRITE 5, 18
    CHECK 150
    CHKCUR 2, 5

    SEEK 0
    CHECK 150
    CHKCUR 0, 0
    SEEK 75
    CHECK 150
    CHKCUR 1, 25
    SEEK 149
    CHECK 150
    CHKCUR 2, 49

    ; Past the end
    SEEK 151, 150
    CHECK 150
    CHKCUR 2, 50
    SEEK 500, 150
    CHECK 150
    CHKCUR 2, 50
    WRITE 3, 19
    CHECK 200
    CHKCUR 3, 3

    SEEK 0
    READ 153, 153
    CHECK 200
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 9: reads that end at the end of a chunk, start there, run past the
; chunk, ask for nothing, or run past the last chunk (which stops them).
.proc testReads
    NEWBUF
    WRITE 260, 20
    CHECK 300
    SEEK 0
    READ 260, 260
    CHECK 300
    SEEK 30
    READ 20, 20
    CHECK 300
    CHKCUR 0, 50
    READ 10, 10
    CHECK 300
    CHKCUR 1, 10
    READ 45, 45
    CHECK 300
    CHKCUR 2, 5
    READ 0, 0
    CHECK 300
    CHKCUR 2, 5
    SEEK 280
    READ 40, 20
    CHECK 300
    CHKCUR 5, 50
    READ 1, 0
    CHECK 300
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 10: two membufs written in turns, so their chunks are mixed in the
; heap. Each keeps its own bytes.
.proc testTwoBufs
    NEWBUF
    SELECT 1
    NEWBUF
    SELECT 0
    WRITE 30, 50
    SELECT 1
    WRITE 30, 51
    SELECT 0
    WRITE 30, 52
    SELECT 1
    WRITE 30, 53
    SELECT 0
    WRITE 30, 54
    SELECT 1
    WRITE 30, 55
    SELECT 0
    WRITE 30, 56
    SELECT 1
    WRITE 30, 57
    SELECT 0
    WRITE 30, 58
    SELECT 1
    WRITE 30, 59

    SELECT 0
    CHECK 150
    SEEK 0
    READ 150, 150
    CHECK 150
    SELECT 1
    CHECK 150
    SEEK 20
    WRITE 100, 60
    CHECK 150
    SELECT 0
    CHECK 150
    FREEBUF
    SELECT 1
    CHECK 150
    FREEBUF
    rts
.endproc

;-----------------------------------------------------------------------------
; Test 11: a chunk whose address has a low byte of 0, so membufIsZero has to
; look past the first byte to see it isn't null.
.proc testAligned
    NEWBUF
    ; Find where the next block goes and fill up to the next page
    lda #1
    ldx #0
    jsr heapAlloc
    stq probe
    jsr heapFree
    lda probe
    beq :+
    eor #$ff
    clc
    adc #1                  ; 256 - the low byte
    ldx #0
    jsr heapAlloc
    stq probe
    jsr addFiller
:
    WRITE 60, 41
    CHECK 100
    ; The first chunk's low byte is 0
    jsr countCheck
    ldq mb
    stq ptr1
    ldz #MEMBUF::firstChunk
    nop
    lda (ptr1),z
    sta gotW
    lda #0
    sta gotW+1
    sta expW
    sta expW+1
    lda #<msgAlign
    ldx #>msgAlign
    jsr expectEq
    SEEK 0
    READ 60, 60
    CHECK 100
    FREEBUF
    jmp freeFillers
.endproc

;-----------------------------------------------------------------------------
; Test 12: chunks in the second heap bank, after chunks in the first. The
; first bank is filled in between.
.proc testHighBank
    NEWBUF
    WRITE 100, 42
    jsr fillBank0
    WRITE 300, 43
    CHECK 400
    CHKCUR 7, 50
    ; The last chunk is in the second bank
    jsr countCheck
    ldq mb
    stq ptr1
    ldz #MEMBUF::currentChunk+2
    nop
    lda (ptr1),z
    sta gotW
    lda #0
    sta gotW+1
    sta expW+1
    lda #BANK1
    sta expW
    lda #<msgBank
    ldx #>msgBank
    jsr expectEq
    SEEK 90
    READ 100, 100
    CHECK 400
    SEEK 0
    WRITE 400, 44
    CHECK 400
    CHKCUR 7, 50
    FREEBUF
    jmp freeFillers
.endproc

;-----------------------------------------------------------------------------
; Membuf operations. Each does the same to the model.

; Allocates a membuf into mb, starts its model empty, and checks the header
; is clear
.proc newBuf
    jsr allocMemBuf
    stq mb
    lda #0
    sta mPos
    sta mPos+1
    sta mUsed
    sta mUsed+1
    lda #0
    tax
    jsr modelAt
    lda #<MODEL_SIZE
    sta cmpLen
    lda #>MODEL_SIZE
    sta cmpLen+1
    lda #0
    jsr fillMem

    jsr countCheck
    ldq mb
    stq ptr1
    ldz #.sizeof(MEMBUF)-1
:   nop
    lda (ptr1),z
    bne :+
    dez
    bpl :-
    rts
:   sta gotW
    tza
    sta atW
    lda #0
    sta gotW+1
    sta expW
    sta expW+1
    lda #<msgHdr
    ldx #>msgHdr
    jmp fail
.endproc

.proc freeBuf
    ldq mb
    jmp freeMemBuf
.endproc

; Makes membuf A (0 or 1) the current one, keeping the other's state
.proc selectBuf
    pha
    ; Save the current one
    lda cur
    asl a
    tax
    lda mPos
    sta slotPos,x
    lda mPos+1
    sta slotPos+1,x
    lda mUsed
    sta slotUsed,x
    lda mUsed+1
    sta slotUsed+1,x
    txa
    asl a
    tax
    ldy #0
:   lda mb,y
    sta slotMb,x
    inx
    iny
    cpy #4
    bne :-
    ; Load the new one
    pla
    sta cur
    asl a
    tax
    lda slotPos,x
    sta mPos
    lda slotPos+1,x
    sta mPos+1
    lda slotUsed,x
    sta mUsed
    lda slotUsed+1,x
    sta mUsed+1
    txa
    asl a
    tax
    ldy #0
:   lda slotMb,x
    sta mb,y
    inx
    iny
    cpy #4
    bne :-
    lda cur
    bne :+
    lda #<model0
    sta modelBase
    lda #>model0
    sta modelBase+1
    rts
:   lda #<model1
    sta modelBase
    lda #>model1
    sta modelBase+1
    rts
.endproc

; Writes A/X bytes from genSrc (seed in seedArg) at the position
.proc doWrite
    sta lenArg
    stx lenArg+1
    ; The model must hold the bytes
    lda mPos
    clc
    adc lenArg
    sta idx
    lda mPos+1
    adc lenArg+1
    sta idx+1
    lda #<MODEL_SIZE
    cmp idx
    lda #>MODEL_SIZE
    sbc idx+1
    bcs :+
    lda #<msgModel
    ldx #>msgModel
    jmp fail
:   jsr genSrc
    ldq mb
    stq ptr1
    PTR ptr2, srcBuf
    lda lenArg
    ldx lenArg+1
    jsr writeToMemBuf

    ; The model
    PTR ptr2, srcBuf
    lda mPos
    ldx mPos+1
    jsr modelAt
    lda lenArg
    sta cmpLen
    lda lenArg+1
    sta cmpLen+1
    jsr copyMem
    lda mPos
    clc
    adc lenArg
    sta mPos
    lda mPos+1
    adc lenArg+1
    sta mPos+1
    ; used moves up to the position
    lda mUsed
    cmp mPos
    lda mUsed+1
    sbc mPos+1
    bcs :+
    lda mPos
    sta mUsed
    lda mPos+1
    sta mUsed+1
:   rts
.endproc

; Asks to read A/X bytes and checks the countArg bytes that must be read
.proc doRead
    sta lenArg
    stx lenArg+1
    ; Fill the buffer, and 8 bytes past it, with the marker
    PTR ptr3, dstBuf
    lda lenArg
    clc
    adc #8
    sta cmpLen
    lda lenArg+1
    adc #0
    sta cmpLen+1
    lda #MARKER
    jsr fillMem
    ldq mb
    stq ptr1
    PTR ptr2, dstBuf
    lda lenArg
    ldx lenArg+1
    jsr readFromMemBuf

    ; The bytes read are the model's
    jsr countCheck
    PTR ptr2, dstBuf
    lda mPos
    ldx mPos+1
    jsr modelAt
    lda countArg
    sta cmpLen
    lda countArg+1
    sta cmpLen+1
    jsr cmpMem
    bcc :+
    lda #<msgRead
    ldx #>msgRead
    jmp failBytes

    ; and nothing after them was written
:   jsr countCheck
    lda #<dstBuf
    clc
    adc countArg
    sta ptr2
    lda #>dstBuf
    adc countArg+1
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda lenArg
    clc
    adc #8
    sta cmpLen
    lda lenArg+1
    adc #0
    sta cmpLen+1
    lda cmpLen
    sec
    sbc countArg
    sta cmpLen
    lda cmpLen+1
    sbc countArg+1
    sta cmpLen+1
    lda #MARKER
    jsr checkFill
    bcc :+
    lda idx
    clc
    adc countArg
    sta idx
    lda idx+1
    adc countArg+1
    sta idx+1
    lda #<msgOverrun
    ldx #>msgOverrun
    jmp failBytes

:   lda mPos
    clc
    adc countArg
    sta mPos
    lda mPos+1
    adc countArg+1
    sta mPos+1
    rts
.endproc

; Sets the position to A/X. The model's position becomes countArg.
.proc doSeek
    sta lenArg
    stx lenArg+1
    ldq mb
    stq ptr1
    lda lenArg
    ldx lenArg+1
    jsr setMemBufPos
    lda countArg
    sta mPos
    lda countArg+1
    sta mPos+1
    rts
.endproc

;-----------------------------------------------------------------------------
; Checks

; Checks the membuf against the model. A/X is its capacity.
.proc checkBuf
    sta capArg
    stx capArg+1

    ; The position
    jsr countCheck
    ldq mb
    jsr getMemBufPos
    sta gotW
    stx gotW+1
    lda mPos
    sta expW
    lda mPos+1
    sta expW+1
    lda #<msgPos
    ldx #>msgPos
    jsr expectEq

    ; used
    jsr countCheck
    ldq mb
    stq ptr1
    ldz #MEMBUF::used
    jsr hdrWord
    lda mUsed
    sta expW
    lda mUsed+1
    sta expW+1
    lda #<msgUsed
    ldx #>msgUsed
    jsr expectEq

    ; The capacity
    jsr countCheck
    ldz #MEMBUF::capacity
    jsr hdrWord
    lda capArg
    sta expW
    lda capArg+1
    sta expW+1
    lda #<msgCap
    ldx #>msgCap
    jsr expectEq

    ; isMemBufAtEnd: A is 1 and the Z flag clear if the position is before
    ; used. gotW is A and gotW+1 is 1 if Z was clear.
    jsr countCheck
    ldq mb
    jsr isMemBufAtEnd
    sta gotW
    php
    pla
    and #$02
    eor #$02
    lsr a
    sta gotW+1
    lda mPos
    cmp mUsed
    lda mPos+1
    sbc mUsed+1             ; The carry is clear if mPos < mUsed
    lda #0
    rol a
    eor #1
    sta expW
    sta expW+1
    lda #<msgAtEnd
    ldx #>msgAtEnd
    jsr expectEq

    ; Walk the chunks, comparing each with the model
    jsr countCheck
    ldq mb
    stq ptr1
    ldz #MEMBUF::currentChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq curChunk
    ldz #MEMBUF::posChunk
    nop
    lda (ptr1),z
    sta posChunk
    ldz #MEMBUF::firstChunk
    neg
    neg
    nop
    lda (ptr1),z
    stq chunkPtr
    lda #$ff
    sta curIdx
    lda #0
    sta chunkIdx
    sta chunkOff
    sta chunkOff+1
CL: ldq chunkPtr
    jsr isQZero
    bne :+
    jmp CD
    ; There must be room for another chunk in the capacity
:   lda chunkOff
    clc
    adc #CHUNK
    sta gotW
    lda chunkOff+1
    adc #0
    sta gotW+1
    lda capArg
    cmp gotW
    lda capArg+1
    sbc gotW+1
    bcs :+
    lda capArg
    sta expW
    lda capArg+1
    sta expW+1
    lda #<msgChunks
    ldx #>msgChunks
    jmp fail
    ; Is it the current chunk?
:   ldx #3
:   lda chunkPtr,x
    cmp curChunk,x
    bne :+
    dex
    bpl :-
    lda chunkIdx
    sta curIdx
    ; Compare its data with the model
:   ldq chunkPtr
    clc
    adc #MEMBUF_CHUNK::data
    bcc :+
    inx
    bne :+
    iny
    bne :+
    inz
:   stq ptr2
    lda chunkOff
    ldx chunkOff+1
    jsr modelAt
    lda #CHUNK
    sta cmpLen
    lda #0
    sta cmpLen+1
    jsr cmpMem
    bcc :+
    lda idx
    clc
    adc chunkOff
    sta idx
    lda idx+1
    adc chunkOff+1
    sta idx+1
    lda #<msgData
    ldx #>msgData
    jmp failBytes
    ; The next chunk
:   ldq chunkPtr
    stq ptr4
    ldz #MEMBUF_CHUNK::nextChunk
    neg
    neg
    nop
    lda (ptr4),z
    stq chunkPtr
    inc chunkIdx
    lda chunkOff
    clc
    adc #CHUNK
    sta chunkOff
    bcc :+
    inc chunkOff+1
:   jmp CL

CD: ; The chunks hold the whole capacity
    jsr countCheck
    lda chunkOff
    sta gotW
    lda chunkOff+1
    sta gotW+1
    lda capArg
    sta expW
    lda capArg+1
    sta expW+1
    lda #<msgChunks
    ldx #>msgChunks
    jsr expectEq

    ; The current chunk and posChunk are where the position is
    jsr countCheck
    lda chunkIdx
    bne HC
    ; No chunks: no current chunk and posChunk 0
    ldq curChunk
    jsr isQZero
    beq :+
    lda curChunk
    sta gotW
    lda curChunk+1
    sta gotW+1
    lda #0
    sta expW
    sta expW+1
    lda #<msgNoChunks
    ldx #>msgNoChunks
    jmp fail
:   lda posChunk
    sta gotW
    lda #0
    sta gotW+1
    sta expW
    sta expW+1
    lda #<msgPosChunk
    ldx #>msgPosChunk
    jmp expectEq

HC: lda curIdx
    cmp #$ff
    bne :+
    sta gotW
    lda #0
    sta gotW+1
    sta expW
    sta expW+1
    lda #<msgCur
    ldx #>msgCur
    jmp fail
:   lda posChunk
    cmp #CHUNK+1
    bcc :+
    sta gotW
    lda #0
    sta gotW+1
    sta expW+1
    lda #CHUNK
    sta expW
    lda #<msgPosChunk
    ldx #>msgPosChunk
    jmp fail
    ; curIdx * CHUNK + posChunk is the position
:   lda posChunk
    sta gotW
    lda #0
    sta gotW+1
    ldx curIdx
    beq MD
ML: lda gotW
    clc
    adc #CHUNK
    sta gotW
    bcc :+
    inc gotW+1
:   dex
    bne ML
MD: lda mPos
    sta expW
    lda mPos+1
    sta expW+1
    lda #<msgPosChunk
    ldx #>msgPosChunk
    jmp expectEq
.endproc

; Checks the current chunk was number A in the chain and posChunk was X,
; as the last checkBuf found them. Low byte is the chunk, high posChunk.
.proc checkCur
    sta expW
    stx expW+1
    jsr countCheck
    lda curIdx
    sta gotW
    lda posChunk
    sta gotW+1
    lda #<msgWhere
    ldx #>msgWhere
    jmp expectEq
.endproc

; Reads the word at offset Z of the header in ptr1 into gotW
.proc hdrWord
    nop
    lda (ptr1),z
    sta gotW
    inz
    nop
    lda (ptr1),z
    sta gotW+1
    rts
.endproc

; Fails with the message in A/X if expW and gotW differ
.proc expectEq
    pha
    lda expW
    cmp gotW
    bne :+
    lda expW+1
    cmp gotW+1
    bne :+
    pla
    rts
:   pla
    jmp fail
.endproc

.proc countCheck
    inc checkNum
    bne :+
    inc checkNum+1
:   lda #0
    sta atW
    sta atW+1
    rts
.endproc

; Fails with the message in A/X, expB and gotB as the values and idx as
; where they differ
.proc failBytes
    pha
    lda expB
    sta expW
    lda gotB
    sta gotW
    lda #0
    sta expW+1
    sta gotW+1
    lda idx
    sta atW
    lda idx+1
    sta atW+1
    pla
    jmp fail
.endproc

; Prints the test and check numbers, the message in A/X, and expW, gotW and
; atW, then fails the test
.proc fail
    sta failMsg
    stx failMsg+1
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
    lda expW+1
    jsr printHex
    lda expW
    jsr printHex
    lda #<msgGot
    ldx #>msgGot
    jsr printStr
    lda gotW+1
    jsr printHex
    lda gotW
    jsr printHex
    lda #<msgAt
    ldx #>msgAt
    jsr printStr
    lda atW+1
    jsr printHex
    lda atW
    jsr printHex
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

;-----------------------------------------------------------------------------
; Memory helpers. The pointers are 32-bit and only their low word moves.

; Points ptr3 at the model, A/X bytes in
.proc modelAt
    clc
    adc modelBase
    sta ptr3
    txa
    adc modelBase+1
    sta ptr3+1
    lda #0
    sta ptr3+2
    sta ptr3+3
    rts
.endproc

; Writes seedArg's bytes to srcBuf, lenArg of them. Each is the next value
; of v = v * 5 + 1 (from the seed), exclusive-ored with the high byte of its
; offset, so no two 256-byte runs are the same.
.proc genSrc
    lda seedArg
    sta genV
    PTR ptr3, srcBuf
    lda #0
    sta idx
    sta idx+1
L1: lda idx
    cmp lenArg
    bne :+
    lda idx+1
    cmp lenArg+1
    beq DN
:   lda genV
    asl a
    asl a
    clc
    adc genV
    clc
    adc #1
    sta genV
    eor idx+1
    ldz #0
    nop
    sta (ptr3),z
    inw ptr3
    inc idx
    bne L1
    inc idx+1
    bra L1
DN: rts
.endproc

; Fills cmpLen bytes at ptr3 with A
.proc fillMem
    sta fillB
    lda #0
    sta idx
    sta idx+1
L1: lda idx
    cmp cmpLen
    bne :+
    lda idx+1
    cmp cmpLen+1
    beq DN
:   lda fillB
    ldz #0
    nop
    sta (ptr3),z
    inw ptr3
    inc idx
    bne L1
    inc idx+1
    bra L1
DN: rts
.endproc

; Copies cmpLen bytes from ptr2 to ptr3
.proc copyMem
    lda #0
    sta idx
    sta idx+1
L1: lda idx
    cmp cmpLen
    bne :+
    lda idx+1
    cmp cmpLen+1
    beq DN
:   ldz #0
    nop
    lda (ptr2),z
    nop
    sta (ptr3),z
    inw ptr2
    inw ptr3
    inc idx
    bne L1
    inc idx+1
    bra L1
DN: rts
.endproc

; Compares cmpLen bytes at ptr2 (what the membuf has) with ptr3 (the
; model). The carry is set if they differ, with the offset in idx and the
; bytes in gotB and expB.
.proc cmpMem
    lda #0
    sta idx
    sta idx+1
L1: lda idx
    cmp cmpLen
    bne :+
    lda idx+1
    cmp cmpLen+1
    beq OK
:   ldz #0
    nop
    lda (ptr2),z
    sta gotB
    nop
    lda (ptr3),z
    sta expB
    cmp gotB
    bne BAD
    inw ptr2
    inw ptr3
    inc idx
    bne L1
    inc idx+1
    bra L1
OK: clc
    rts
BAD:
    sec
    rts
.endproc

; Checks cmpLen bytes at ptr2 are all A. The carry is set if one isn't, with
; its offset in idx and it in gotB.
.proc checkFill
    sta expB
    lda #0
    sta idx
    sta idx+1
L1: lda idx
    cmp cmpLen
    bne :+
    lda idx+1
    cmp cmpLen+1
    beq OK
:   ldz #0
    nop
    lda (ptr2),z
    sta gotB
    cmp expB
    bne BAD
    inw ptr2
    inc idx
    bne L1
    inc idx+1
    bra L1
OK: clc
    rts
BAD:
    sec
    rts
.endproc

;-----------------------------------------------------------------------------
; Filler blocks, which put the membuf's blocks where a test wants them

; Keeps the block in probe in the filler list
.proc addFiller
    lda fillerCount
    cmp #MAX_FILLERS
    bcc :+
    lda #0
    sta expW
    sta expW+1
    sta gotW
    sta gotW+1
    lda #<msgFillers
    ldx #>msgFillers
    jmp fail
:   asl a
    asl a
    tax
    ldy #0
:   lda probe,y
    sta fillers,x
    inx
    iny
    cpy #4
    bne :-
    inc fillerCount
    rts
.endproc

; Frees the filler blocks, last first
.proc freeFillers
L1: lda fillerCount
    beq DN
    dec fillerCount
    lda fillerCount
    asl a
    asl a
    tax
    ldy #0
:   lda fillers,x
    sta probe,y
    inx
    iny
    cpy #4
    bne :-
    ldq probe
    jsr heapFree
    bra L1
DN: rts
.endproc

; Fills the first heap bank with filler blocks, smaller and smaller, until
; not even a byte fits. A block that goes to another bank is freed.
.proc fillBank0
    lda #0
    sta sizeIdx
L1: lda sizeIdx
    asl a
    tax
    lda fillSizes,x
    sta fillSize
    lda fillSizes+1,x
    sta fillSize+1
    ora fillSize
    beq DN
L2: lda fillSize
    ldx fillSize+1
    jsr heapAlloc
    stq probe
    lda probe+2
    cmp #BANK0
    bne L3
    jsr addFiller
    bra L2
L3: ldq probe
    jsr heapFree
    inc sizeIdx
    bra L1
DN: rts
.endproc

.rodata

fillSizes: .word 4096, 1024, 256, 64, 16, 4, 1, 0

msgTest: .asciiz "test "
msgCheck: .asciiz " check "
msgExp: .asciiz "exp "
msgGot: .asciiz " got "
msgAt: .asciiz " at "
msgPos: .asciiz "wrong position"
msgUsed: .asciiz "wrong used"
msgCap: .asciiz "wrong capacity"
msgAtEnd: .asciiz "wrong ismembufatend"
msgChunks: .asciiz "chunks don't match capacity"
msgData: .asciiz "wrong chunk data"
msgNoChunks: .asciiz "current chunk with no chunks"
msgCur: .asciiz "current chunk not in the chain"
msgPosChunk: .asciiz "poschunk doesn't match position"
msgWhere: .asciiz "wrong chunk (lo) or poschunk (hi)"
msgRead: .asciiz "wrong data read"
msgOverrun: .asciiz "read past what it should"
msgHdr: .asciiz "new header not clear"
msgModel: .asciiz "write past the model"
msgLeak: .asciiz "blocks leaked"
msgFillers: .asciiz "too many fillers"
msgAlign: .asciiz "first chunk not page aligned"
msgBank: .asciiz "chunk not in second heap bank"

.bss

; Test state
testIdx: .res 1
testNum: .res 1
testVec: .res 2
checkNum: .res 2
failMsg: .res 2
expW: .res 2
gotW: .res 2
atW: .res 2

; The current membuf and its model
cur: .res 1
mb: .res 4
mPos: .res 2
mUsed: .res 2
modelBase: .res 2
; Both membufs' state, kept by selectBuf
slotMb: .res 8
slotPos: .res 4
slotUsed: .res 4

; Arguments
lenArg: .res 2
countArg: .res 2
seedArg: .res 1
capArg: .res 2

; Helper state
genV: .res 1
idx: .res 2
cmpLen: .res 2
gotB: .res 1
expB: .res 1
fillB: .res 1
recNum: .res 1
curChunk: .res 4
curIdx: .res 1
posChunk: .res 1
chunkPtr: .res 4
chunkIdx: .res 1
chunkOff: .res 2
probe: .res 4
fillerCount: .res 1
fillers: .res MAX_FILLERS * 4
fillSize: .res 2
sizeIdx: .res 1

; Buffers
model0: .res MODEL_SIZE
model1: .res MODEL_SIZE
srcBuf: .res MODEL_SIZE
dstBuf: .res MODEL_SIZE + 8
