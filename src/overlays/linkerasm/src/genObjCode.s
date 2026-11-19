;
; genObjCode.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; genObjCode routine
;
; The linker reads the object file that code generation wrote (zztmp, see
; linker.inc), lays out the program (rtlayout.inc) and writes the PRG:
;
;   1. Read. The header, the imports (imports.s), the libraries
;      (loadLibrary.s) and the relocations, sorted by offset
;      (sortLinkerTags.s). The code is read last, in step 3.
;   2. Lay out. Place the runtime (runtime.s), then each library, which
;      defines a symbol at each of its slots, then the program module, then
;      the runtime's BSS (runtimeBss.s). Every import must then have an
;      address, and the program must fit below the ceiling.
;   3. Write. The BASIC line, the runtime and the libraries, then the code,
;      patching each relocation with its address, then the BSS.
;
; A bad object file is errObjFileInvalid. Any error stops the link, deletes
; the object file and leaves no PRG.

.include "c64.inc"
.include "asm.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "rtlayout.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "error.inc"

OBJ_FILENUM = 2
PRG_FILENUM = 3

.export genObjCode, readByte, readStatus, readName
.export objMode, objFeatures, stackSize, progBase

.import sortLinkerTags
.import initImports, readImports, importAddress, checkImports, freeImports
.import symName
.import initLibraries, readLibraryList, layoutLibraries, writeLibraries
.import freeLibraries
.import readFrames, setGlobalSlots
.import layoutRuntime, writeRuntime, codeCeiling
.import defineLinkerSymbols, writeRuntimeBss, RTBSS_LEN: zp

.bss

curByte: .res 1             ; the byte a relocation patches

objMode: .res 1             ; RT_MODE_* from the object file
objFeatures: .res 1         ; RTF_*
stackSize: .res 2           ; the runtime stack's size
codeLen: .res 2             ; the module's code
bssLen: .res 2              ; and BSS
progBase: .res 2            ; the module's address
skipCount: .res 2           ; for readObjHeader
bytesOver: .res 4           ; for checkCodeSize
intBuf: .res 12

toGo: .res 2
codePos: .res 2
tagsMemBuf: .res 4
tagToFix: .res .sizeof(TAGTOFIX)
prgFilename: .res 17
strbuf: .res 20
readStatus: .res 1

.data

; The start of the object file's header
objHeader: .byte OBJ_MAGIC0, OBJ_MAGIC1, OBJ_VERSION, RT_ABI_VERSION
objHeader2:

pasExt: .asciiz ".pas"
prgExt: .asciiz ".prg"
strObjFile: .byte "zztmp,s,r"
strObjFile2:
writeExt: .asciiz ",p,w"
strTooLarge1: .asciiz "Program is "
strTooLarge2: .asciiz " bytes too large"

; The start of the PRG, after its load address: the BASIC line
; "10 BANK 0:SYS 8209", then the JMP to the program header
prgStub:
    .word LINK_CODE_BASE + 14   ; the next line
    .word 10                    ; the line number
    .byte $fe, $02, '0', ':'    ; BANK 0:
    .byte $9e                   ; SYS
    .byte .sprintf("%d", LINK_CODE_BASE + 16)
    .byte 0                     ; the end of the line
    .byte 0, 0                  ; the end of the program
    .assert * - prgStub = 16, error, "the BASIC line moved"
    .byte OC_JMP
prgStub2:

.code

; This routine links the object file, zztmp, into the PRG.
; Source filename passed in A/X
.proc genObjCode
    jsr formatPrgFilename

    ; Delete the output PRG file if it exists
    jsr deletePrgFile

    jsr initLinkerTags
    jsr initImports
    jsr initLibraries
    lda #0
    tax
    tay
    taz
    stq tagsMemBuf

    ; Open the object file
    ldx DEVNUM
    lda #OBJ_FILENUM
    tay
    jsr SETLFS
    ldx #<strObjFile
    ldy #>strObjFile
    lda #strObjFile2-strObjFile
    jsr SETNAM
    jsr OPEN

    lda #0
    sta readStatus

    ; 1. Read everything but the code
    jsr readObjHeader
    bcs BD
    jsr readImports
    bcs BD
    jsr readLibraryList
    bcs BD
    jsr readFrames
    bcs BD
    jsr sortLinkerTags
    stq tagsMemBuf
    lda readStatus
    beq :+
BD: jmp objFileInvalid

    ; 2. Lay out: the runtime, the libraries, the module and the BSS
:   jsr layoutRuntime
    bcs ER
    clc
    adc #<(LINK_CODE_BASE + LINK_STUB_SIZE)
    pha
    txa
    adc #>(LINK_CODE_BASE + LINK_STUB_SIZE)
    tax
    pla
    jsr layoutLibraries
    bcs ER
    sta progBase
    stx progBase+1
    clc
    adc codeLen
    pha
    txa
    adc codeLen+1
    tax
    pla
    clc
    adc bssLen
    pha
    txa
    adc bssLen+1
    tax
    pla
    jsr defineLinkerSymbols
    jsr checkImports
    bcs ER
    jsr checkCodeSize
    bcc :+
ER: jmp finish

    ; 3. Write the PRG: its load address and the BASIC line
:   jsr openPrgFile
    ldx #PRG_FILENUM
    jsr CHKOUT
    lda #<LINK_CODE_BASE
    jsr CHROUT
    lda #>LINK_CODE_BASE
    jsr CHROUT
    ldx #0
:   lda prgStub,x
    jsr CHROUT
    inx
    cpx #prgStub2-prgStub
    bne :-
    lda progBase
    jsr CHROUT
    lda progBase+1
    jsr CHROUT

    ; 20 bytes for the MEGA65 DMA command block
    ldx #20
    lda #0
:   jsr CHROUT
    dex
    bne :-
    .assert prgStub2 - prgStub + 2 + 20 = LINK_STUB_SIZE, error, "stub size"

    ; The runtime and the libraries
    jsr writeRuntime
    bcc :+
    jmp prgError
:   jsr writeLibraries

    ; The module's code. Read the first tagToFix (initializes toGo).
    ldq tagsMemBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos
    lda #0
    sta codePos
    sta codePos+1
    jsr readTagToFix

    ; Loop through the object file
L1: lda readStatus
    and #$40
    bne DN

    lda toGo
    cmp #$ff
    bne L2
    lda toGo+1
    cmp #$ff
    bne L2

    ; Copy a byte from the object file
    jsr readByte
    pha
    ldx #PRG_FILENUM
    jsr CHKOUT
    pla
    jsr CHROUT
    bra L1

    ; Is toGo zero?
L2: lda toGo
    ora toGo+1
    bne L3

    jsr updateOffset
    bra L1

    ; Copy a byte from the object file
L3: jsr readByte
    pha
    ldx #PRG_FILENUM
    jsr CHKOUT
    pla
    jsr CHROUT

    lda toGo
    sec
    sbc #1
    sta toGo
    lda toGo+1
    sbc #0
    sta toGo+1
    lda codePos
    clc
    adc #1
    sta codePos
    lda codePos+1
    adc #0
    sta codePos+1
    bra L1

    ; The module's BSS, then the runtime's
DN: ldx #PRG_FILENUM
    jsr CHKOUT
B1: lda bssLen
    ora bssLen+1
    beq B2
    lda #0
    jsr CHROUT
    lda bssLen
    bne :+
    dec bssLen+1
:   dec bssLen
    bra B1
B2: jsr writeRuntimeBss

    ; Close the output PRG file
    lda #PRG_FILENUM
    jsr CLOSE
    ; Fall through
.endproc

; This routine finishes linking: it closes and deletes the object file and
; frees what the linker allocated
.proc finish
    lda #OBJ_FILENUM
    jsr CLOSE
    jsr CLRCHN

    jsr deleteObjFile

    ldq tagsMemBuf
    jsr isQZero
    beq :+
    jsr freeMemBuf
:   jsr freeImports
    jsr freeLibraries
    jmp freeLinkerTags
.endproc

; This routine stops writing the PRG after an error and deletes it
.proc prgError
    lda #PRG_FILENUM
    jsr CLOSE
    jsr CLRCHN
    jsr deletePrgFile
    jmp finish
.endproc

; This routine reports a bad object file, then finishes
.proc objFileInvalid
    jsr CLRCHN
    lda #errObjFileInvalid
    ldx #0
    ldy #0
    jsr compilerError
    jmp finish
.endproc

; This routine reads the object file's header, up to its imports. The
; carry is set if it is bad: not an object file, another format version, a
; runtime other than RT_ABI_VERSION or a unit. The symbols are skipped,
; since nothing imports them.
.proc readObjHeader
    ; The magic number and the versions
    ldx #0
:   phx
    jsr readByte
    plx
    cmp objHeader,x
    bne BD2
    inx
    cpx #objHeader2-objHeader
    bne :-
    bra :+
BD2: jmp BD

    ; The kind and the flags, which aren't used yet
:
    jsr readByte
    cmp #OBJ_KIND_PROGRAM
    bne BD
    jsr readByte

    ; The features, the runtime mode and the stack size
    jsr readByte
    sta objFeatures
    jsr readByte
    sta objMode
    jsr readByte
    sta stackSize
    jsr readByte
    sta stackSize+1

    ; The name and the global slots, where the frames start (frames.s)
    jsr readName
    bcs BD
    jsr readByte
    pha
    jsr readByte
    tax
    pla
    jsr setGlobalSlots

    ; The code length and the BSS length
    jsr readByte
    sta codeLen
    jsr readByte
    sta codeLen+1
    jsr readByte
    sta bssLen
    jsr readByte
    sta bssLen+1

    ; The symbols
    jsr readByte
    sta skipCount
    jsr readByte
    sta skipCount+1
L1: lda skipCount
    ora skipCount+1
    beq OK
    lda readStatus
    bne BD
    jsr readName
    bcs BD
    jsr readByte                ; The offset and the flags
    jsr readByte
    jsr readByte
    lda skipCount
    bne :+
    dec skipCount+1
:   dec skipCount
    bra L1

OK: lda readStatus
    bne BD
    clc
    rts

BD: sec
    rts
.endproc

; This routine reads a name from the object file into symName, with a null
; after it. The carry is set if it's longer than OBJ_NAME_MAX.
.proc readName
    jsr readByte
    cmp #OBJ_NAME_MAX + 1
    bcs DN
    sta skipCount
    ldx #0
:   cpx skipCount
    beq :+
    phx
    jsr readByte
    plx
    sta symName,x
    inx
    bra :-
:   lda #0
    sta symName,x
    clc
DN: rts
.endproc

; This routine checks that the program fits in memory. The runtime stack
; grows down from the ceiling (codeCeiling) and the heap runs from the end
; of the image up to the heap's MAT, four bytes below the stack. If less
; than MIN_HEAP_SIZE bytes are left for the heap, errCodeSegmentOverflow
; (static) or errCodeSegmentOverflowDyn (dynamic) is reported, followed by
; a line saying how many bytes too large the program is, and the carry is
; set. Otherwise the carry is clear.
.proc checkCodeSize
    ; intOp1/intOp2 (32 bits) = the module's end + the runtime's BSS +
    ; the stack + 4 + MIN_HEAP_SIZE
    lda #0
    sta intOp2+1
    sta intOp32+2
    sta intOp32+3
    lda progBase
    clc
    adc codeLen
    sta intOp1
    lda progBase+1
    adc codeLen+1
    sta intOp1+1
    lda #0
    adc #0
    sta intOp2
    lda bssLen
    sta intOp32
    lda bssLen+1
    sta intOp32+1
    jsr addOp32
    lda stackSize
    sta intOp32
    lda stackSize+1
    sta intOp32+1
    jsr addOp32
    lda #<(RTBSS_LEN + 4 + MIN_HEAP_SIZE)
    sta intOp32
    lda #>(RTBSS_LEN + 4 + MIN_HEAP_SIZE)
    sta intOp32+1
    jsr addOp32

    ; intOp1/intOp2 = bytes over codeCeiling
    lda codeCeiling
    sta intOp32
    lda codeCeiling+1
    sta intOp32+1
    ldq intOp1
    sec
    sbcq intOp32
    stq intOp1
    bcc OK                      ; Below the ceiling
    lda intOp1
    ora intOp1+1
    ora intOp2
    ora intOp2+1
    bne ER                      ; Above the ceiling
OK: clc                         ; It fits
    rts

    ; The error logger uses intOp1, so save the count
ER: ldq intOp1
    stq bytesOver
    lda objMode
    cmp #RT_MODE_STATIC
    bne :+
    lda #errCodeSegmentOverflow
    bra :++
    ; A dynamic program has less room than a static one, so the error
    ; suggests $StaticRuntime
:   lda #errCodeSegmentOverflowDyn
:   ldx #0
    ldy #0
    jsr compilerError

    ; Report how many bytes too large the program is
    ldq bytesOver
    stq intOp1
    ldx #0
:   lda strTooLarge1,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #<intBuf
    ldx #>intBuf
    jsr writeInt32
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   ldx #0
:   lda strTooLarge2,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT
    sec
    rts
.endproc

; This routine adds intOp32 (16 bits; its high word is zero) to
; intOp1/intOp2
.proc addOp32
    ldq intOp1
    clc
    adcq intOp32
    stq intOp1
    rts
.endproc

; This routine reads a byte from file #2 (the object file).
; It updated readStatus with the latest I/O status.
; The byte is returned in A.
.proc readByte
    ldx #OBJ_FILENUM
    jsr CHKIN
    jsr CHRIN
    pha
    lda STATUS
    sta readStatus
    pla
    rts
.endproc

; This routine deletes the input object file
.proc deleteObjFile
    ; Copy strObjFile to strbuf (leaving off the ",p,r")
    ldx #0
L1: lda strObjFile,x
    cmp #','
    beq L2
    sta strbuf,x
    inx
    bne L1

L2: lda #0
    sta strbuf,x

    ; Delete the file
    lda #<strbuf
    sta ptr1
    lda #>strbuf
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr scratchFile

    rts
.endproc

; This routine formats the output PRG filename.
; The input is the source filename in A/X.
;
; If the source filename ends in ".pas",
; drop the extension and use that for the PRG filename.
.proc formatPrgFilename
    sta ptr1
    stx ptr1+1

    ; Copy the filename
    ldy #0
    ldx #0
L1: lda (ptr1),y
    sta prgFilename,x
    beq L2
    inx
    iny
    bne L1

L2: jsr doesFilenameEndWithPas
    bne L3
    jsr dropPasExtension
    rts

    ; Is the filename > 12 characters long?
L3: ldy #0
:   lda prgFilename,y
    beq :+
    iny
    bne :-
:   cpy #12
    bcc L4
    ldy #12
L4: ldx #0
:   lda prgExt,x
    sta prgFilename,y
    beq :+
    inx
    iny
    bne :-
:   rts
.endproc

; This routine looks at the null-terminated filename ptr1
; and determines whether it ends in ".pas". It does a
; case-insensitive comparison.
;
; The Z flag is set if the filename ends in ".pas"
.proc doesFilenameEndWithPas
    ldy #0
    ; Find the last character in the filename
:   lda prgFilename,y
    beq :+
    iny
    bne :-

:   dey
    ; Work backwards looking for the last dot
:   cpy #0
    beq L4
    lda prgFilename,y
    cmp #'.'
    beq L5
    dey
    bne :-

    ; No dot found
L4: lda #1
    rts

    ; Dot found - check the rest of the string
L5: iny
    ldx #1

    ; Loop through the characters in pasExt
:   lda prgFilename,y
    and #$7f            ; force to lower case
    beq :+
    cmp pasExt,x
    bne L8
    inx
    iny
    bne :-

:   cmp pasExt,x
L8: rts
.endproc

; This routine truncates prgFilename by looking for the
; last dot and setting it to 0.
.proc dropPasExtension
    ldy #0
    ; Find the last character in the filename
:   lda prgFilename,y
    beq :+
    iny
    bne :-

    ; Work backwards looking for the last dot
:   cpy #0
    beq DN
    lda prgFilename,y
    cmp #'.'
    beq :+
    dey
    bne :-

    ; Dot found - check the rest of the string
:   lda #0
    sta prgFilename,y
DN: rts
.endproc

.proc deletePrgFile
    ; First, see if the output PRG filename already exists
    lda #<prgFilename
    ldx #>prgFilename
    ldy #0
    ldz #0
    jsr doesFileExist
    beq :+
    ; The file does exist. Delete it.
    lda #<prgFilename
    sta ptr1
    lda #>prgFilename
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr scratchFile

:   rts
.endproc

.proc openPrgFile
    ; Copy the filename from prgFilename to strbuf
    ldx #0
L1: lda prgFilename,x
    beq L2
    sta strbuf,x
    inx
    bne L1

    ; Add the ",p,w" extension
L2: ldy #0
L3: lda writeExt,y
    beq L4
    sta strbuf,x
    inx
    iny
    bne L3

    ; Call SETLFS
L4: phx                 ; X contains length of filename (including ",p,w")
    ldx DEVNUM
    lda #PRG_FILENUM
    tay
    jsr SETLFS
    ; Call SETNAM
    ldx #<strbuf
    ldy #>strbuf
    pla
    jsr SETNAM
    ; Open the file
    jsr OPEN

    rts
.endproc

; This routine reads the next relocation into tagToFix and works out its
; address (resolveTag). toGo is set to the bytes before it, or $FFFF if
; there are no more.
.proc readTagToFix
    ldq tagsMemBuf
    jsr isMemBufAtEnd
    bne :+
    lda #$ff
    sta toGo
    sta toGo+1
    rts

:   ldq tagsMemBuf
    stq ptr1
    lda #<tagToFix
    sta ptr2
    lda #>tagToFix
    sta ptr2+1
    ldx #0
    stx ptr2+2
    stx ptr2+3
    lda #.sizeof(TAGTOFIX)
    jsr readFromMemBuf
    jsr resolveTag

    ldx #TAGTOFIX::offset
    lda tagToFix,x
    sta intOp1
    inx
    lda tagToFix,x
    sta intOp1+1
    lda codePos
    sta intOp2
    lda codePos+1
    sta intOp2+1
    jsr subInt16
    lda intOp1
    sta toGo
    lda intOp1+1
    sta toGo+1

    rts
.endproc

; This routine turns tagToFix's target into an address: an import's, or
; an offset in the module from progBase
.proc resolveTag
    ldx #TAGTOFIX::type
    lda tagToFix,x
    bpl LC
    .assert LINKADDR_IMPORT = $80, error, "LINKADDR_IMPORT must be bit 7"
    and #$7f
    sta tagToFix,x
    ldx #TAGTOFIX::address
    lda tagToFix,x
    pha
    lda tagToFix+1,x
    tax
    pla
    jsr importAddress
    bra ST

LC: ldx #TAGTOFIX::address
    lda tagToFix,x
    clc
    adc progBase
    pha
    lda tagToFix+1,x
    adc progBase+1
    tax
    pla
ST: ldy #TAGTOFIX::address
    sta tagToFix,y
    txa
    sta tagToFix+1,y
    rts
.endproc

; This routine writes the address of the relocation in tagToFix in place of
; the bytes at its offset, then reads the next one. readByte reads the bytes
; replaced, so readStatus says if they end the file.
.proc updateOffset
    jsr readByte        ; the current byte, which only a frame keeps
    sta curByte

    ldx #TAGTOFIX::type
    lda tagToFix,x
    cmp #LINKADDR_LOW
    beq LO
    cmp #LINKADDR_HIGH
    beq HI
    cmp #LINKADDR_FRAME
    beq FR

    ; Update both bytes
    ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #TAGTOFIX::address
    lda tagToFix,x
    jsr CHROUT
    jsr readByte        ; discard the next byte too
    ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #TAGTOFIX::address+1
    lda tagToFix,x
    jsr CHROUT
    lda #2
    bra RN

    ; Update just the low byte
LO: ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #TAGTOFIX::address
    lda tagToFix,x
    jsr CHROUT
    lda #1
    bra RN

    ; Add a frame's first slot to a level 1 offset (frames.s)
FR: lda curByte
    clc
    ldx #TAGTOFIX::address
    adc tagToFix,x
    pha
    ldx #PRG_FILENUM
    jsr CHKOUT
    pla
    jsr CHROUT
    lda #1
    bra RN

    ; Update just the high byte
HI: ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #TAGTOFIX::address+1
    lda tagToFix,x
    jsr CHROUT
    lda #1

    ; Update the codePos
RN: clc
    adc codePos
    sta codePos
    lda codePos+1
    adc #0
    sta codePos+1

    ; Read the next tag to fix
    jmp readTagToFix
.endproc
