;
; loadLibrary.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The libraries
;
; The object file lists the libraries the program uses, each with the names
; of its jump table's slots (linker.inc). readLibraryList keeps the list.
; layoutLibraries reads each library file into the heap, places it and
; defines a symbol at each slot. writeLibraries relocates each library and
; writes it to the PRG.
;
; A library file is in one of two formats (docs/docs/libraries/objfile.md).
; v1 starts with its load address, a page boundary. Any byte in the pages
; the library spans is taken as the high byte of an address. v2 starts with
; load address 0, then the page it was linked at, the code and BSS lengths
; and a table of the offsets of the addresses in the code (mkreloc.py).
; readLibBuf relocates each address in v2 code as it is read.

.include "asm.inc"
.include "c64.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "error.inc"

MAX_LIBS = 16               ; libraries a program can use
LFN_LIB = 5                 ; logical file numbers
LFN_PRG = 3

.export readLibraryList, layoutLibraries, writeLibraries
.export initLibraries, freeLibraries

.import readByte, readName, readStatus, symName, defineSymbol

.data

strLib: .asciiz ".lib"
strSuffix: .asciiz ",p,r"

.bss

; The list from the object file, as it is there
libList: .res 4
numLibs: .res 1
libIndex: .res 1            ; the library being laid out or written
slotsLeft: .res 2
slotKind: .res 1
slotAddr: .res 2

; Each library, by number, from layoutLibraries for writeLibraries
libBufs: .res 4 * MAX_LIBS      ; membuf of its code
relocBufs: .res 4 * MAX_LIBS    ; v2: membuf of the offsets of addresses
libBasesL: .res MAX_LIBS        ; its address
libBasesH: .res MAX_LIBS
libV2s: .res MAX_LIBS           ; non-zero for v2
libPages: .res MAX_LIBS         ; the page it was linked at
libReadL: .res MAX_LIBS         ; bytes in libBuf
libReadH: .res MAX_LIBS
libBssL: .res MAX_LIBS          ; v2: its BSS length
libBssH: .res MAX_LIBS
libRelocsL: .res MAX_LIBS       ; v2: the number of addresses
libRelocsH: .res MAX_LIBS

; The library being laid out or written
buf: .res 3
libBase: .res 2
libBuf: .res 4
filename: .res 20       ; up to 12 chars of the name, ".lib" and ",p,r"
page: .res 1
pages: .res 1
numRead: .res 2
isV2: .res 1            ; non-zero for a v2 library
bssLen: .res 2          ; v2: zero bytes to write after the code
relocsLeft: .res 2      ; v2: offsets not yet read from relocBuf
relocBuf: .res 4        ; v2: membuf of the offsets of addresses
nextReloc: .res 2       ; v2: offset of the next address, $FFFF if none
pos: .res 2             ; v2: offset in the code of the next byte read
relocHi: .res 1         ; v2: non-zero if the next byte is a high byte
relocCarry: .res 1      ; v2: carry from relocating the low byte
rdIdx: .res 1           ; readLibBuf: index in buf
rdCount: .res 1         ; readLibBuf: bytes left to relocate

.code

; This routine starts with no libraries
.proc initLibraries
    lda #0
    sta numLibs
    ldx #4 * MAX_LIBS - 1
:   sta libBufs,x
    sta relocBufs,x
    dex
    bpl :-
    tax
    tay
    taz
    stq libList
    rts
.endproc

; This routine frees the list and any library still in the heap
.proc freeLibraries
    ldq libList
    jsr isQZero
    beq :+
    jsr freeMemBuf
:   ldx #0
L1: phx
    jsr libPtr
    jsr freeLibBufs
    plx
    inx
    cpx #MAX_LIBS
    bne L1
    jmp initLibraries
.endproc

; This routine sets X to the offset of library X in libBufs and relocBufs
.proc libPtr
    txa
    asl a
    asl a
    tax
    rts
.endproc

; This routine frees the library buffers at offset X in libBufs and
; relocBufs, and clears them
.proc freeLibBufs
    phx
    lda libBufs,x
    ldy libBufs+2,x
    ldz libBufs+3,x
    pha
    lda libBufs+1,x
    tax
    pla
    jsr isQZero
    beq :+
    jsr freeMemBuf
:   plx
    phx
    lda relocBufs,x
    ldy relocBufs+2,x
    ldz relocBufs+3,x
    pha
    lda relocBufs+1,x
    tax
    pla
    jsr isQZero
    beq :+
    jsr freeMemBuf
:   plx
    lda #0
    sta libBufs,x
    sta libBufs+1,x
    sta libBufs+2,x
    sta libBufs+3,x
    sta relocBufs,x
    sta relocBufs+1,x
    sta relocBufs+2,x
    sta relocBufs+3,x
    rts
.endproc

; This routine reads the object file's list of libraries into libList. The
; carry is set if it's bad.
.proc readLibraryList
    jsr allocMemBuf
    stq libList

    jsr readByte
    sta numLibs
    jsr appendList
    lda numLibs
    cmp #MAX_LIBS + 1
    bcs BD

    lda numLibs
    sta libIndex
L1: lda libIndex
    beq OK
    dec libIndex
    jsr copyName                ; The library's name
    bcs BD
    jsr readByte                ; Its slots
    sta slotsLeft
    jsr appendList
    jsr readByte
    sta slotsLeft+1
    jsr appendList
L2: lda slotsLeft
    ora slotsLeft+1
    beq L1
    jsr readByte                ; The slot's kind
    jsr appendList
    jsr copyName                ; and name
    bcs BD
    jsr decSlots
    bra L2

OK: lda readStatus
    bne BD
    clc
    rts
BD: sec
    rts
.endproc

; This routine copies a name from the object file to libList. The carry is
; set if it's too long.
.proc copyName
    jsr readName
    bcs DN
    ldx #0
:   lda symName,x
    beq :+
    inx
    bra :-
:   txa
    jsr appendList
    ldx #0
:   lda symName,x
    beq :+
    phx
    jsr appendList
    plx
    inx
    bra :-
:   clc
DN: rts
.endproc

; This routine writes the byte in A to the end of libList
.proc appendList
    sta buf
    ldq libList
    jmp appendBuf
.endproc

; This routine reads a byte from libList into A
.proc readList
    ldq libList
    stq ptr1
    lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buf
    rts
.endproc

; This routine reads a name from libList into symName, null-terminated
.proc readListName
    jsr readList
    sta rdCount
    ldx #0
:   cpx rdCount
    beq :+
    phx
    jsr readList
    plx
    sta symName,x
    inx
    bra :-
:   lda #0
    sta symName,x
    rts
.endproc

; This routine reads a slot count from libList into slotsLeft
.proc readSlotCount
    jsr readList
    sta slotsLeft
    jsr readList
    sta slotsLeft+1
    rts
.endproc

; This routine counts down slotsLeft
.proc decSlots
    lda slotsLeft
    bne :+
    dec slotsLeft+1
:   dec slotsLeft
    rts
.endproc

; This routine moves to the start of libList
.proc rewindList
    ldq libList
    stq ptr1
    lda #0
    tax
    jmp setMemBufPos
.endproc

; This routine reads each library file, places the libraries from the
; address in A/X and defines a symbol at each slot. The address after them
; is returned in A/X. A library that's missing or bad is
; errLibraryFileInvalid, and the carry is set.
.proc layoutLibraries
    sta libBase
    stx libBase+1
    jsr rewindList
    jsr readList                ; The count
    lda #0
    sta libIndex

L1: lda libIndex
    cmp numLibs
    bne :+
    lda libBase
    ldx libBase+1
    clc
    rts

:   jsr readListName
    jsr loadLibrary
    php

    ; Keep its membufs, which freeLibraries frees if it fails
    ldx libIndex
    jsr libPtr
    ldy #0
:   lda libBuf,y
    sta libBufs,x
    lda relocBuf,y
    sta relocBufs,x
    inx
    iny
    cpy #4
    bne :-
    plp
    bcc :+
    rts

    ; A symbol for each slot
:   lda libBase
    sta slotAddr
    lda libBase+1
    sta slotAddr+1
    jsr readSlotCount
L2: lda slotsLeft
    ora slotsLeft+1
    beq NX
    jsr readList
    sta slotKind
    jsr readListName
    lda slotAddr
    ldx slotAddr+1
    jsr defineSymbol
    lda slotKind
    cmp #OBJLIB_VARIABLE
    beq :+
    lda #3
    bra :++
:   lda #2
:   clc
    adc slotAddr
    sta slotAddr
    bcc :+
    inc slotAddr+1
:   jsr decSlots
    bra L2

    ; Save the library's state for writeLibraries
NX: ldx libIndex
    lda libBase
    sta libBasesL,x
    lda libBase+1
    sta libBasesH,x
    lda isV2
    sta libV2s,x
    lda page
    sta libPages,x
    lda numRead
    sta libReadL,x
    lda numRead+1
    sta libReadH,x
    lda bssLen
    sta libBssL,x
    lda bssLen+1
    sta libBssH,x
    lda relocsLeft
    sta libRelocsL,x
    lda relocsLeft+1
    sta libRelocsH,x

    ; The next library follows its code and BSS
    lda libBase
    clc
    adc numRead
    sta libBase
    lda libBase+1
    adc numRead+1
    sta libBase+1
    lda libBase
    clc
    adc bssLen
    sta libBase
    lda libBase+1
    adc bssLen+1
    sta libBase+1
    inc libIndex
    jmp L1
.endproc

; This routine reads the library named in symName into libBuf. The carry is
; set if the file is missing or bad.
.proc loadLibrary
    lda #0
    sta isV2
    sta bssLen
    sta bssLen+1
    sta relocsLeft
    sta relocsLeft+1
    tax
    tay
    taz
    stq libBuf
    stq relocBuf

    jsr openLibrary

    ; Read the starting address
    ldx #LFN_LIB
    jsr CHKIN
    jsr CHRIN
    cmp #0              ; Library must start on a page boundary
    bne BD
    jsr CHRIN
    sta page
    lda STATUS
    bne BD              ; Missing, or nothing after the load address
    lda page
    bne :+              ; Branch if v1 (load address isn't 0)
    jsr readV2Header

    ; Read the entire library into a memory buffer
:   jsr readLibrary
    jsr closeLibrary
    lda numRead
    ora numRead+1
    beq ER
    clc
    rts

BD: jsr closeLibrary
ER: lda #errLibraryFileInvalid
    ldx #0
    ldy #0
    jsr compilerError
    sec
    rts
.endproc

.proc closeLibrary
    lda #LFN_LIB
    jsr CLOSE
    ldx #0
    jmp CHKIN
.endproc

; This routine writes each library to the PRG, which is the current output,
; relocated to its address, and frees it.
.proc writeLibraries
    jsr rewindList
    jsr readList                ; The count
    lda #0
    sta libIndex

L1: lda libIndex
    cmp numLibs
    bne :+
    rts

    ; The library's state
:   ldx libIndex
    lda libBasesL,x
    sta libBase
    lda libBasesH,x
    sta libBase+1
    lda libV2s,x
    sta isV2
    lda libPages,x
    sta page
    lda libReadL,x
    sta numRead
    lda libReadH,x
    sta numRead+1
    lda libBssL,x
    sta bssLen
    lda libBssH,x
    sta bssLen+1
    lda libRelocsL,x
    sta relocsLeft
    lda libRelocsH,x
    sta relocsLeft+1
    jsr libPtr
    ldy #0
:   lda libBufs,x
    sta libBuf,y
    lda relocBufs,x
    sta relocBuf,y
    inx
    iny
    cpy #4
    bne :-

    ; The number of pages it spans
    lda numRead+1
    sta pages
    lda numRead
    beq :+
    inc pages

:   ldq libBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos
    lda isV2
    beq :+
    jsr startV2Relocs

:   ldx #LFN_PRG
    jsr CHKOUT
    jsr readListName            ; Skip the name
    jsr processJumpTable
    jsr processLibraryObjCode
    lda isV2
    beq :+
    jsr writeBss

:   ldx libIndex
    jsr libPtr
    jsr freeLibBufs
    inc libIndex
    jmp L1
.endproc

; Reads the rest of a v2 header (after load address 0) and the offsets of
; the addresses into relocBuf.
.proc readV2Header
    inc isV2
    jsr CHRIN
    sta page
    jsr CHRIN           ; The code length isn't needed
    jsr CHRIN
    jsr CHRIN
    sta bssLen
    jsr CHRIN
    sta bssLen+1
    jsr CHRIN
    sta relocsLeft
    jsr CHRIN
    sta relocsLeft+1

    jsr allocMemBuf
    stq relocBuf

    ; Each offset is two bytes
    lda relocsLeft
    sta numRead
    lda relocsLeft+1
    sta numRead+1
    asl numRead
    rol numRead+1

L1: lda numRead
    ora numRead+1
    beq L2
    jsr CHRIN
    sta buf
    ldq relocBuf
    jsr appendBuf
    lda numRead
    bne :+
    dec numRead+1
:   dec numRead
    bra L1

L2: rts
.endproc

; This routine starts relocating a v2 library: it reads the first offset
.proc startV2Relocs
    ldq relocBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    lda #0
    sta pos
    sta pos+1
    sta relocHi
    ; Fall through
.endproc

; Reads the next offset from relocBuf into nextReloc, or sets it to $FFFF
; when there are no more.
.proc fetchReloc
    lda relocsLeft
    ora relocsLeft+1
    bne :+
    lda #$ff
    sta nextReloc
    sta nextReloc+1
    rts

:   lda relocsLeft
    bne :+
    dec relocsLeft+1
:   dec relocsLeft

    ldq relocBuf
    stq ptr1
    lda #<nextReloc
    sta ptr2
    lda #>nextReloc
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #2
    ldx #0
    jmp readFromMemBuf
.endproc

; Relocates the v2 code byte in A, at offset pos, and returns it in A.
; The low byte of an address gets libBase's low byte added. The high byte
; gets libBase's high byte and the carry added, and the page subtracted.
.proc relocByte
    ldx relocHi
    bne HI

    ; Is this the low byte of an address?
    ldx pos
    cpx nextReloc
    bne NX
    ldx pos+1
    cpx nextReloc+1
    bne NX

    clc
    adc libBase
    pha
    lda #0
    rol a
    sta relocCarry
    lda #1
    sta relocHi
    pla
    bra NX

HI: clc
    adc relocCarry
    clc
    adc libBase+1
    sec
    sbc page
    pha
    lda #0
    sta relocHi
    jsr fetchReloc
    pla

NX: inc pos
    bne :+
    inc pos+1
:   rts
.endproc

; Writes the zero bytes of a v2 library's BSS after its code
.proc writeBss
L1: lda bssLen
    ora bssLen+1
    beq DN
    lda #0
    jsr CHROUT
    lda bssLen
    bne :+
    dec bssLen+1
:   dec bssLen
    bra L1

DN: rts
.endproc

; Writes the byte in buf to the end of the membuf in Q
.proc appendBuf
    stq ptr1
    lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jmp writeToMemBuf
.endproc

; Relocates the JMP operand in buf+1 and buf+2 of a v1 library.
; readLibBuf has already relocated a v2 library's.
.proc relocJmp
    lda isV2
    bne :+
    jmp relocAddr
:   rts
.endproc

; This routine opens the library named in symName: up to 12 characters of
; the name, then ".lib"
.proc openLibrary
    ldx #0
:   lda symName,x
    beq :+
    cpx #12         ; CBM names are 16 chars: room for ".lib"
    beq :+
    sta filename,x
    inx
    bne :-
:   ldy #0
:   lda strLib,y
    beq :+
    sta filename,x
    inx
    iny
    bne :-
:   ldy #0
:   lda strSuffix,y
    beq :+
    sta filename,x
    inx
    iny
    bne :-

    ; Open the library file
:   phx             ; Save the filename length
    ldx DEVNUM
    lda #LFN_LIB
    tay
    jsr SETLFS
    ; Call SETNAM
    ldx #<filename
    ldy #>filename
    pla             ; filename length
    jsr SETNAM
    ; Open the file
    jmp OPEN
.endproc

; Read the library into a memory buffer
.proc readLibrary
    lda #0
    sta numRead
    sta numRead+1

    jsr allocMemBuf
    stq libBuf

L1: lda STATUS
    and #$40
    beq :+
    rts

:   jsr CHRIN
    sta buf

    ; Write the byte to the memory buffer
    ldq libBuf
    jsr appendBuf

    lda numRead
    clc
    adc #1
    sta numRead
    lda numRead+1
    adc #0
    sta numRead+1
    bra L1
.endproc

; This routine writes the library's jump table, a slot at a time as libList
; lists them, relocating a JMP's address.
.proc processJumpTable
    jsr readSlotCount
L1: lda slotsLeft
    ora slotsLeft+1
    bne :+
    rts

:   jsr readList
    sta slotKind
    jsr readListName            ; The name isn't needed
    lda slotKind
    cmp #OBJLIB_VARIABLE
    beq VR

    ; A routine
    lda #<buf
    ldx #>buf
    ldy #3
    jsr readLibBuf
    lda buf
    cmp #OC_JMP
    bne :+
    jsr relocJmp
:   lda buf
    jsr CHROUT
    lda buf+1
    jsr CHROUT
    lda buf+2
    jsr CHROUT
    bra NX

    ; A variable's address, as it is in a v1 library
VR: lda #<buf
    ldx #>buf
    ldy #2
    jsr readLibBuf
    lda buf
    jsr CHROUT
    lda buf+1
    jsr CHROUT

NX: jsr decSlots
    bra L1
.endproc

; This routine reads object code from the library file.
; It loads bytes into the buffer and searches for addresses
; to relocate.
.proc processLibraryObjCode
    ; Loop through the buffer
    ; Algorithm:
    ;    Read one byte before going into the loop
    ;    Loop:
    ;        If the end of the buffer has been reached, write the current byte and exit
    ;        Read another byte from the buffer
    ;        If the second byte is a page number to relocate:
    ;            Relocate the two bytes and write them both
    ;            If the end of the buffer, exit the loop
    ;            Read another byte from the buffer
    ;        Else
    ;            Write the first byte then keep the second byte for the next loop

    ; readLibBuf relocates a v2 library's code, so it is only copied
    lda isV2
    beq V1
V2: ldq libBuf
    jsr isMemBufAtEnd
    bne :+
    rts
:   lda #<buf
    ldx #>buf
    ldy #1
    jsr readLibBuf
    lda buf
    jsr CHROUT
    bra V2

    ; Nothing left after the jump table
V1: ldq libBuf
    jsr isMemBufAtEnd
    beq DN

    ; Read one byte to prime the pump
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readLibBuf

L1: ldq libBuf
    jsr isMemBufAtEnd
    bne L2
    ; End of the buffer - write the last byte then exit
    lda buf
    jsr CHROUT
    bra DN

    ; Read another byte
L2: lda #<(buf+1)
    ldx #>(buf+1)
    ldy #1
    jsr readLibBuf

    ; Is this an address that needs to be relocated?
    jsr isPageInRange
    bcs L3                  ; Branch if the first byte of address to be relocated

    ; Write the first byte but keep the second byte
    lda buf
    jsr CHROUT
    lda buf+1
    sta buf
    bra L1

    ; Address needs to be relocated.
L3: lda buf+1
    sta buf+2
    lda buf
    sta buf+1
    jsr relocAddr
    lda buf+1
    jsr CHROUT
    lda buf+2
    jsr CHROUT

    ; If those were the last two bytes then exit
    ldq libBuf
    jsr isMemBufAtEnd
    beq DN

    ; Read another byte
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readLibBuf

    bra L1

DN: rts
.endproc

; This routine checks the page number in buf+1 and determines
; if it in the range of page..(page+pages)
; Carry flag set if address needs to be relocated
.proc isPageInRange
    ; Is buf+1 < page
    lda buf+1
    cmp page
    bcc :+

    ; Is page+pages <= buf+1?
    lda page
    adc pages
    sec
    sbc #2
    sec
    sbc buf+1

:   rts
.endproc

; This routine calculates the relocated address for the
; address in buf+1 and buf+2
;
; Page number in buf+2 and offset in buf+1
.proc relocAddr
    lda libBase
    sta intOp1
    lda libBase+1
    sta intOp1+1
    lda buf+2
    sec
    sbc page
    sta intOp2+1
    lda buf+1
    sta intOp2
    jsr addInt16
    lda intOp1
    sta buf+1
    lda intOp1+1
    sta buf+2
    rts
.endproc

; Buffer in A/X, which must be in buf
; Number of bytes to read in Y
; The bytes of a v2 library are relocated (relocByte).
.proc readLibBuf
    ; Set up the buffer
    sta ptr2
    stx ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ; Save the buffer's index in buf and the number of bytes to read
    lda ptr2
    sec
    sbc #<buf
    sta rdIdx
    sty rdCount
    phy

    ; Set up the membuf header
    ldq libBuf
    stq ptr1

    ; Number of bytes to read
    pla
    ldx #0

    jsr readFromMemBuf

    lda isV2
    beq DN
L1: ldx rdIdx
    lda buf,x
    jsr relocByte
    ldx rdIdx
    sta buf,x
    inc rdIdx
    dec rdCount
    bne L1

DN: rts
.endproc
