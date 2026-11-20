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
; The linker reads the object files that code generation wrote (see
; linker.inc): the program's, zztmp, then each unit's, <unit>.obj, in the
; order the program's lists them. It lays out the program (rtlayout.inc)
; and writes the PRG:
;
;   1. Read. Each module's header, exports, imports (imports.s) and
;      relocations, sorted by offset (sortLinkerTags.s), and the program's
;      libraries (loadLibrary.s), frames (frames.s) and units. The code is
;      read last, in step 3.
;   2. Lay out. Place the runtime (runtime.s), then each library, which
;      defines a symbol at each of its slots, then the modules, the program
;      first, then the runtime's BSS (runtimeBss.s). The modules' exports
;      and the frames are defined once the modules are placed. Every import
;      must then have an address, and the program must fit below the
;      ceiling.
;   3. Write. The BASIC line, the runtime and the libraries, then each
;      module's code, patching each relocation with its address, then the
;      BSS.
;
; A bad object file is errObjFileInvalid. Any error stops the link. The
; program's object file is deleted, and an error leaves no PRG. A unit's
; stays beside its TPU, for the next build.

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

MAX_UNITS = 16              ; as code generation's (imports.s there)
MAX_MODULES = MAX_UNITS + 1 ; the program, then its units
UNIT_NAME_SIZE = 13         ; a unit's name and a zero

.export genObjCode, readByte, readStatus, readName
.export objMode, objFeatures, stackSize, progBase, modBase

.import sortLinkerTags
.import initImports, readImports, importAddress, checkImports, freeImports
.import symName, allocImports, deferSymbol, defineDeferred
.import mapImport, setImportMap
.import initLibraries, readLibraryList, layoutLibraries, writeLibraries
.import freeLibraries
.import readFrames, setGlobalSlots, checkSlots
.import layoutRuntime, writeRuntime, codeCeiling
.import defineLinkerSymbols, writeRuntimeBss, RTBSS_LEN: zp

.bss

curByte: .res 1             ; the byte a relocation patches

objMode: .res 1             ; RT_MODE_* from the program's object file
objFeatures: .res 1         ; RTF_*, every module's
stackSize: .res 2           ; the runtime stack's size
progBase: .res 2            ; the program module's address
modEnd: .res 2              ; the address after the last module
skipCount: .res 2           ; for readObjHeader and readName
bytesOver: .res 4           ; for checkCodeSize
intBuf: .res 12

; The modules: the program (0), then its units
numUnits: .res 1
unitNames: .res MAX_UNITS * UNIT_NAME_SIZE
curMod: .res 1              ; the module being read or written
modCode: .res MAX_MODULES * 2   ; its code's length
modBss: .res MAX_MODULES * 2    ; its BSS's
modBase: .res MAX_MODULES * 2   ; its address
modStart: .res MAX_MODULES * 2  ; the offset of its code in its file
modTags: .res MAX_MODULES * 4   ; its relocations, sorted (a membuf)
modMap: .res MAX_MODULES * 4    ; its imports' numbers (imports.s)
filePos: .res 2             ; bytes read from the object file
bssLeft: .res 2
qTmp: .res 4

toGo: .res 2
codePos: .res 2
tagsMemBuf: .res 4
tagToFix: .res .sizeof(TAGTOFIX)
prgFilename: .res 17
strbuf: .res 22
readStatus: .res 1

.data

; The start of the object file's header
objHeader: .byte OBJ_MAGIC0, OBJ_MAGIC1, OBJ_VERSION, RT_ABI_VERSION
objHeader2:

pasExt: .asciiz ".pas"
prgExt: .asciiz ".prg"
strProgObj: .asciiz "zztmp"
strObjExt: .asciiz ".obj"
strRead: .asciiz ",s,r"
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

; This routine links the object files into the PRG.
; Source filename passed in A/X
.proc genObjCode
    jsr formatPrgFilename

    ; Delete the output PRG file if it exists
    jsr deletePrgFile

    jsr initLinkerTags
    jsr initImports
    jsr initLibraries
    lda #0
    sta numUnits
    sta objFeatures
    ldx #MAX_MODULES * 4 - 1
:   sta modTags,x
    sta modMap,x
    dex
    bpl :-

    ; 1. Read everything but the code: the program's object file, then
    ; each unit's
    lda #0
    sta curMod
L1: jsr readModule
    bcs BD
    lda curMod
    cmp numUnits
    beq :+
    inc curMod
    bra L1
:   jsr allocImports
    bra :+
BD: jmp objFileInvalid

    ; 2. Lay out: the runtime, the libraries, the modules and the BSS. The
    ; level 1 slots must fit first (frames.s).
:   jsr checkSlots
    bcs ER
    jsr layoutRuntime
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
    jsr layoutModules
    jsr defineDeferred
    lda modEnd
    ldx modEnd+1
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

    ; Each module's code and BSS
    lda #0
    sta curMod
L2: jsr writeModule
    lda curMod
    cmp numUnits
    beq :+
    inc curMod
    bra L2

    ; The runtime's BSS
:   ldx #PRG_FILENUM
    jsr CHKOUT
    jsr writeRuntimeBss

    ; Close the output PRG file
    lda #PRG_FILENUM
    jsr CLOSE
    ; Fall through
.endproc

; This routine finishes linking: it closes the object files, deletes the
; program's and frees what the linker allocated
.proc finish
    lda #OBJ_FILENUM
    jsr CLOSE
    jsr CLRCHN

    jsr deleteObjFiles

    lda #0
    sta curMod
L1: jsr modOffset4
    lda modTags,x
    ora modTags+1,x
    ora modTags+2,x
    ora modTags+3,x
    beq :+
    lda modTags,x
    ldy modTags+2,x
    ldz modTags+3,x
    pha
    lda modTags+1,x
    tax
    pla
    jsr freeMemBuf
:   jsr modOffset4
    lda modMap,x
    ora modMap+1,x
    ora modMap+2,x
    ora modMap+3,x
    beq :+
    lda modMap,x
    ldy modMap+2,x
    ldz modMap+3,x
    pha
    lda modMap+1,x
    tax
    pla
    jsr heapFree
:   inc curMod
    lda curMod
    cmp #MAX_MODULES
    bne L1

    jsr freeImports
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
    lda #OBJ_FILENUM
    jsr CLOSE
    jsr CLRCHN
    lda #errObjFileInvalid
    ldx #0
    ldy #0
    jsr compilerError
    jmp finish
.endproc

; This routine returns in X curMod times 2
.proc modOffset2
    lda curMod
    asl a
    tax
    rts
.endproc

; This routine returns in X curMod times 4
.proc modOffset4
    lda curMod
    asl a
    asl a
    tax
    rts
.endproc

; This routine puts the name of module curMod's object file in strbuf,
; null-terminated: zztmp for the program, or the unit's name and ".obj".
; Its length is returned in X.
.proc modFilename
    lda curMod
    bne UN
    ldx #0
:   lda strProgObj,x
    sta strbuf,x
    beq DN
    inx
    bra :-

    ; ptr1 = unitNames + (curMod - 1) * UNIT_NAME_SIZE
UN: lda #<unitNames
    sta ptr1
    lda #>unitNames
    sta ptr1+1
    ldx curMod
:   dex
    beq :+
    lda ptr1
    clc
    adc #UNIT_NAME_SIZE
    sta ptr1
    bcc :-
    inc ptr1+1
    bra :-
:   ldy #0
:   lda (ptr1),y
    beq :+
    sta strbuf,x
    inx
    iny
    bra :-
:   ldy #0
:   lda strObjExt,y
    sta strbuf,x
    beq DN
    inx
    iny
    bra :-
DN: rts
.endproc

; This routine opens module curMod's object file to read, on OBJ_FILENUM,
; from its first byte
.proc openModule
    jsr modFilename
    ldy #0
:   lda strRead,y
    sta strbuf,x
    beq :+
    inx
    iny
    bra :-
:   phx
    ldx DEVNUM
    lda #OBJ_FILENUM
    tay
    jsr SETLFS
    pla
    ldx #<strbuf
    ldy #>strbuf
    jsr SETNAM
    jsr OPEN
    lda #0
    sta readStatus
    sta filePos
    sta filePos+1
    rts
.endproc

; This routine reads module curMod's object file up to its code, which
; writeModule reads, and closes it. The carry is set if it is bad.
.proc readModule
    jsr openModule
    jsr readObjHeader
    bcs BD
    jsr readImports             ; its map in Q
    bcs BD
    stq qTmp
    jsr modOffset4
    ldy #0
:   lda qTmp,y
    sta modMap,x
    inx
    iny
    cpy #4
    bne :-

    ; The libraries, the frames and the units are the program's
    lda curMod
    bne UN
    jsr readLibraryList
    bcs BD
    jsr readFrames
    bcs BD
    jsr readUnits
    bcs BD
    bra RL
UN: jsr readByte
    jsr checkZero
    bcs BD
    jsr readByte
    jsr checkZero
    bcs BD
    jsr readByte
    jsr checkZero
    bcs BD

    ; The relocations, sorted, then the code, which starts here
RL: jsr sortLinkerTags
    stq qTmp
    jsr modOffset4
    ldy #0
:   lda qTmp,y
    sta modTags,x
    inx
    iny
    cpy #4
    bne :-
    lda readStatus
    bne BD
    jsr modOffset2
    lda filePos
    sta modStart,x
    lda filePos+1
    sta modStart+1,x
    lda #OBJ_FILENUM
    jsr CLOSE
    clc
    rts

BD: sec
    rts
.endproc

; This routine checks that the byte in A, a count a unit's object file
; must have as 0 (libraries, frames, units), is 0. The carry is set if it
; isn't.
.proc checkZero
    cmp #1
    rts
.endproc

; This routine reads the program's units: their count, then each one's
; name, into unitNames. The carry is set if there are too many or a name
; is too long.
.proc readUnits
    jsr readByte
    cmp #MAX_UNITS + 1
    bcs DN
    sta numUnits
    lda #<unitNames
    sta ptr1
    lda #>unitNames
    sta ptr1+1
    lda numUnits
    sta skipCount
L1: lda skipCount
    bne :+
    clc
    rts
:   dec skipCount
    jsr readByte
    cmp #UNIT_NAME_SIZE
    bcs DN
    sta skipCount+1
    ldy #0
:   cpy skipCount+1
    beq :+
    phy
    jsr readByte
    ply
    sta (ptr1),y
    iny
    bra :-
:   lda #0
    sta (ptr1),y
    lda ptr1
    clc
    adc #UNIT_NAME_SIZE
    sta ptr1
    bcc L1
    inc ptr1+1
    bra L1
DN: sec
    rts
.endproc

; This routine lays out the modules from the address in A/X: each one's
; code, then its BSS, the program first. Their addresses go in modBase and
; the address after them in modEnd.
.proc layoutModules
    sta modEnd
    stx modEnd+1
    sta progBase
    stx progBase+1
    lda #0
    sta curMod
L1: jsr modOffset2
    lda modEnd
    sta modBase,x
    clc
    adc modCode,x
    sta modEnd
    lda modEnd+1
    sta modBase+1,x
    adc modCode+1,x
    sta modEnd+1
    lda modEnd
    clc
    adc modBss,x
    sta modEnd
    lda modEnd+1
    adc modBss+1,x
    sta modEnd+1
    lda curMod
    cmp numUnits
    beq :+
    inc curMod
    bra L1
:   rts
.endproc

; This routine writes module curMod's code to the PRG, patching each
; relocation with its address, then its BSS. It opens the module's object
; file and skips to the code.
.proc writeModule
    jsr openModule
L0: jsr modOffset2
    lda filePos
    cmp modStart,x
    bne :+
    lda filePos+1
    cmp modStart+1,x
    beq :++
:   jsr readByte
    bra L0

    ; Its relocations and its imports' map
:   jsr modOffset4
    lda modMap,x
    ldy modMap+2,x
    ldz modMap+3,x
    pha
    lda modMap+1,x
    tax
    pla
    jsr setImportMap
    jsr modOffset4
    lda modTags,x
    sta tagsMemBuf
    lda modTags+1,x
    sta tagsMemBuf+1
    lda modTags+2,x
    sta tagsMemBuf+2
    lda modTags+3,x
    sta tagsMemBuf+3

    ; Read the first tagToFix (initializes toGo)
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

    ; The module's BSS
DN: lda #OBJ_FILENUM
    jsr CLOSE
    ldx #PRG_FILENUM
    jsr CHKOUT
    jsr modOffset2
    lda modBss,x
    sta bssLeft
    lda modBss+1,x
    sta bssLeft+1
B1: lda bssLeft
    ora bssLeft+1
    beq B2
    lda #0
    jsr CHROUT
    lda bssLeft
    bne :+
    dec bssLeft+1
:   dec bssLeft
    bra B1
B2: rts
.endproc

; This routine reads the object file's header, up to its imports. The
; carry is set if it is bad: not an object file, another format version, a
; runtime other than RT_ABI_VERSION, or a kind other than the module's
; (the program first, then units). The exports are kept, to define once
; the module is placed (deferSymbol).
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
:   jsr readByte
    ldx curMod
    beq :+
    cmp #OBJ_KIND_UNIT
    bne BD2
    bra :++
:   cmp #OBJ_KIND_PROGRAM
    bne BD2
:   jsr readByte

    ; A unit's TPU's key, which only code generation reads
    ldx #4
:   phx
    jsr readByte
    plx
    dex
    bne :-

    ; The features, which add to the program's, then the runtime mode
    ; and the stack size, which are the program's
    jsr readByte
    ora objFeatures
    sta objFeatures
    jsr readByte
    ldx curMod
    bne :+
    sta objMode
:   jsr readByte
    ldx curMod
    bne :+
    sta stackSize
:   jsr readByte
    ldx curMod
    bne :+
    sta stackSize+1

    ; The name and the global slots, where the frames start (frames.s)
:   jsr readName
    bcs BD2
    jsr readByte
    pha
    jsr readByte
    tax
    pla
    ldy curMod
    bne :+
    jsr setGlobalSlots

    ; The code length and the BSS length
:   jsr modOffset2
    phx
    jsr readByte
    plx
    sta modCode,x
    phx
    jsr readByte
    plx
    sta modCode+1,x
    phx
    jsr readByte
    plx
    sta modBss,x
    phx
    jsr readByte
    plx
    sta modBss+1,x

    ; The symbols: each export is defined once the module is placed
    jsr readByte
    sta skipCount
    jsr readByte
    sta skipCount+1
L1: lda skipCount
    ora skipCount+1
    beq OK
    lda readStatus
    bne BD
    lda skipCount               ; readName uses skipCount
    pha
    lda skipCount+1
    pha
    jsr readName
    pla
    sta skipCount+1
    pla
    sta skipCount
    bcs BD
    jsr readByte                ; The offset
    pha
    jsr readByte
    tax
    pla
    ldy curMod
    jsr deferSymbol
    jsr readByte                ; The flags
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
    ; intOp1/intOp2 (32 bits) = the modules' end + the runtime's BSS +
    ; the stack + 4 + MIN_HEAP_SIZE
    lda #0
    sta intOp2
    sta intOp2+1
    sta intOp32+2
    sta intOp32+3
    lda modEnd
    sta intOp1
    lda modEnd+1
    sta intOp1+1
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
; It updated readStatus with the latest I/O status and counts the bytes
; read in filePos. The byte is returned in A.
.proc readByte
    ldx #OBJ_FILENUM
    jsr CHKIN
    jsr CHRIN
    pha
    lda STATUS
    sta readStatus
    inc filePos
    bne :+
    inc filePos+1
:   pla
    rts
.endproc

; This routine deletes the program's object file. Each unit's stays beside
; its TPU for the next build (objcache.s in codegen).
.proc deleteObjFiles
    lda #0
    sta curMod
    jsr modFilename
    lda #<strbuf
    sta ptr1
    lda #>strbuf
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jmp scratchFile
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

; This routine turns tagToFix's target into an address: an import's,
; through the module's map (mapImport), or an offset in the module from
; its address
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
    jsr mapImport
    bra ST

LC: jsr modOffset2
    txa
    tay
    ldx #TAGTOFIX::address
    lda tagToFix,x
    clc
    adc modBase,y
    pha
    lda tagToFix+1,x
    adc modBase+1,y
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
