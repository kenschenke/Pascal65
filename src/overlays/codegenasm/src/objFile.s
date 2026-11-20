;
; objFile.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; writeObjFile routine
;
; Code generation writes each module's code to zzcode as it goes and keeps
; the linker tags in the heap (linkerTags.s in asmlib). When the module's
; code is done, writeObjFile writes its object file, zztmp for the program
; and <unit>.obj for a unit: a header, the symbols, the imports, the
; libraries, the frames, the units and a relocation for each tag, then the
; code, copied from zzcode (see linker.inc for the format). It deletes
; zzcode and frees the tags, so code generation leaves nothing in the heap
; for the linker.
;
; A label set in this module is a relocation's target as its offset in the
; code. A label that isn't set is an import: a library's slot or a linker
; symbol, which the linker resolves. Each import is added to the tags with
; its number, so a relocation finds it as it finds a label.
;
; A label with a period that the module sets is an entry, "name.N"
; (icodeExports.s in icodeasm): a unit's init block, routine or variable
; block, which another module imports. setLabel keeps each one, and the
; object file lists them as its exported symbols.

.include "c64.inc"
.include "asm.inc"
.include "asmlib.inc"
.include "ast.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

LFN_OBJ = 1                 ; logical file numbers
LFN_CODE = 2

TAG_SET = 1                 ; findLinkerTag's Y for a label that's set
TAG_IMPORT = 2              ; and for an import (see addImports)

; Adds one to the word at addr
.macro incWord addr
    .local skip
    inc addr
    bne skip
    inc addr+1
skip:
.endmacro

.export writeObjFile, objFilename, codeFilename
.export setObjModule, setLabel, initExports, freeExports
.export setRuntimeFeatures, setRuntimeMode, nameBuf, nameLen, addRuntimeFeatures

.import runtimeStackSize, writeLibraries, writeUnits, deleteIfExists
.import writeFrames, freeFrames, globalSlots, keyValid, keySrc

.data

objFilename: .asciiz "zztmp"
strSeqWrite: .asciiz ",s,w"
codeFilename: .asciiz "zzcode"
codeFn: .byte "zzcode,s,r"
codeFn2:

; The start of the header
objHeader:
    .byte OBJ_MAGIC0, OBJ_MAGIC1, OBJ_VERSION, RT_ABI_VERSION
objHeader2:

.bss

runtimeFeatures: .res 1     ; RTF_* (asm.inc) for the packages to link
runtimeMode: .res 1         ; RT_MODE_* (asm.inc)
tagsToFind: .res 4
tagToFind: .res .sizeof(TAGTOFIND)
relocCount: .res 2
importCount: .res 2
importsWritten: .res 2
target: .res 2              ; the target of the relocation being written
kind: .res 1                ; and its kind
nameLen: .res 1
importLen: .res 1
nameBuf: .res NAMELEN
copyLen: .res 1             ; bytes in copyBuf, 0 for 256
copyStatus: .res 1          ; STATUS after the last byte read
copyBuf: .res 256
objName: .res 2             ; the object file's name (setObjModule)
objModule: .res 1           ; $FF for the program, or the unit's number
objFn: .res 21              ; the name, then ",s,w"
objFnLen: .res 1
exports: .res 4             ; the entries set (setLabel), a membuf, or 0
exportCount: .res 2
labelPtr: .res 2
expName: .res OBJ_NAME_MAX+1

.code

; This routine sets the runtime features (RTF_* in asm.inc) in A. The
; linker links the runtime packages for them. A build with ALLPKGS defined
; (make ALLPKGS=1) links every package, for debugging.
.proc setRuntimeFeatures
.ifdef ALLPKGS
    lda #RTF_ALL
.endif
    sta runtimeFeatures
    rts
.endproc

; This routine adds the runtime features in A, a module's (its EOM), to
; the program's. genObjCode starts them at 0 (setRuntimeFeatures).
.proc addRuntimeFeatures
    ora runtimeFeatures
    jmp setRuntimeFeatures
.endproc

; This routine sets the runtime mode (RT_MODE_* in asm.inc) in A
.proc setRuntimeMode
    sta runtimeMode
    rts
.endproc

; This routine sets the module whose object file writeObjFile writes: its
; name at A/X (null-terminated) and in Y $FF for the program or the unit's
; number, from 0
.proc setObjModule
    sta objName
    stx objName+1
    sty objModule
    rts
.endproc

; This routine writes the module's object file (setObjModule). The
; module's name, runtime mode and stack size come from the icode file's
; header (readIcodeHeader) and the features from its EOM. No file may be
; open: the old object file is deleted first.
.proc writeObjFile
    jsr addImports

    ; The file's name, then ",s,w". An old one is deleted first.
    lda objName
    ldx objName+1
    jsr deleteIfExists
    lda objName
    sta ptr1
    lda objName+1
    sta ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    sta objFn,y
    iny
    bra :-
:   ldx #0
:   lda strSeqWrite,x
    beq :+
    sta objFn,y
    iny
    inx
    bra :-
:   sty objFnLen

    ; Open the object file
    ldx DEVNUM
    lda #LFN_OBJ
    tay
    iny
    jsr SETLFS
    lda objFnLen
    ldx #<objFn
    ldy #>objFn
    jsr SETNAM
    jsr OPEN
    ldx #LFN_OBJ
    jsr CHKOUT

    ; The header: magic number, versions, kind and flags
    ldx #0
:   lda objHeader,x
    jsr CHROUT
    inx
    cpx #objHeader2-objHeader
    bne :-
    lda #OBJ_KIND_PROGRAM
    ldx objModule
    inx
    beq :+
    lda #OBJ_KIND_UNIT
:   jsr CHROUT

    ; The flags, and the key of the TPU a unit's object was made from
    ; (objcache.s), so the next build can keep it
    lda #0
    ldx keyValid
    beq :+
    lda #OBJ_FLAG_CACHED
:   jsr CHROUT
    ldx #0
:   lda keySrc,x
    jsr CHROUT
    inx
    cpx #4
    bne :-

    ; The runtime features and mode and the stack size
    lda runtimeFeatures
    jsr CHROUT
    lda runtimeMode
    jsr CHROUT
    lda runtimeStackSize
    jsr CHROUT
    lda runtimeStackSize+1
    jsr CHROUT

    ; The module's name
    lda nameLen
    jsr CHROUT
    ldx #0
:   cpx nameLen
    beq :+
    lda nameBuf,x
    jsr CHROUT
    inx
    bra :-

    ; The module's own level 1 slots
:   lda globalSlots
    jsr CHROUT
    lda globalSlots+1
    jsr CHROUT

    ; The code length
    lda codeOffset
    jsr CHROUT
    lda codeOffset+1
    jsr CHROUT

    ; The BSS length: none
    lda #0
    jsr CHROUT
    jsr CHROUT

    jsr writeSymbols
    jsr writeImports

    ; The libraries, the frames and the units are the program's
    lda objModule
    cmp #$ff
    beq :+
    lda #0
    jsr CHROUT
    jsr CHROUT
    jsr CHROUT
    bra :++
:   jsr writeLibraries
    jsr writeFrames
    jsr writeUnits
:   jsr writeRelocations
    jsr copyCode

    ; Delete the code file
    lda #<codeFilename
    ldx #>codeFilename
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile

    jsr freeFrames
    jsr freeExports
    jmp freeLinkerTags
.endproc

; This routine starts with no exports
.proc initExports
    lda #0
    sta exportCount
    sta exportCount+1
    tax
    tay
    taz
    stq exports
    rts
.endproc

; This routine frees the exports' membuf, if there is one
.proc freeExports
    ldq exports
    jsr isQZero
    beq :+
    jsr freeMemBuf
:   jmp initExports
.endproc

; This routine sets the label at A/X (null-terminated) at codeOffset
; (linkAddressSet). A label with a period is an entry, which the object
; file exports: its name is kept, in OBJ_NAME_MAX + 1 bytes.
.proc setLabel
    sta labelPtr
    stx labelPtr+1
    jsr linkAddressSet
    lda labelPtr
    sta ptr1
    lda labelPtr+1
    sta ptr1+1
    ldy #0
:   lda (ptr1),y
    beq DN
    cmp #'.'
    beq :+
    iny
    bra :-

    ; Copy it, zero-filled
:   ldy #0
:   lda (ptr1),y
    sta expName,y
    beq :+
    iny
    cpy #OBJ_NAME_MAX
    bne :-
:   lda #0
:   sta expName,y
    iny
    cpy #OBJ_NAME_MAX+1
    bcc :-

    ldq exports
    jsr isQZero
    bne :+
    jsr allocMemBuf
    stq exports
:   ldq exports
    stq ptr1
    jsr ptr2ToExpName
    lda #OBJ_NAME_MAX+1
    ldx #0
    jsr writeToMemBuf
    incWord exportCount
DN: rts
.endproc

; This routine points ptr2 at expName
.proc ptr2ToExpName
    lda #<expName
    sta ptr2
    lda #>expName
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    rts
.endproc

; This routine writes the symbols: their count, then each export's name,
; its offset in the code and OBJSYM_EXPORTED.
.proc writeSymbols
    lda exportCount
    jsr CHROUT
    lda exportCount+1
    jsr CHROUT
    ldq exports
    jsr isQZero
    bne :+
    rts
:   ldq exports
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos
L1: ldq exports
    jsr isMemBufAtEnd
    bne :+
    rts
:   ldq exports
    stq ptr1
    jsr ptr2ToExpName
    lda #OBJ_NAME_MAX+1
    ldx #0
    jsr readFromMemBuf

    ; The name
    ldx #0
:   lda expName,x
    beq :+
    inx
    bra :-
:   stx importLen
    ldx #LFN_OBJ
    jsr CHKOUT
    lda importLen
    jsr CHROUT
    ldx #0
:   cpx importLen
    beq :+
    lda expName,x
    jsr CHROUT
    inx
    bra :-

    ; Its offset and flags
:   lda #<expName
    ldx #>expName
    jsr findLinkerTag
    pha
    phx
    ldx #LFN_OBJ
    jsr CHKOUT
    plx
    pla
    jsr CHROUT
    txa
    jsr CHROUT
    lda #OBJSYM_EXPORTED
    jsr CHROUT
    bra L1
.endproc

; This routine counts the relocations and finds the imports: the labels
; that aren't set. Each is added to the tags with its number, in the order
; first referenced, and flag TAG_IMPORT.
.proc addImports
    jsr getLinkerTagsToFind
    stq tagsToFind

    lda #0
    sta relocCount
    sta relocCount+1
    sta importCount
    sta importCount+1
    jsr rewindTags
L1: ldq tagsToFind
    jsr isMemBufAtEnd
    bne :+
    rts
:   jsr readTag
    incWord relocCount
    lda #<tagToFind
    ldx #>tagToFind
    jsr findLinkerTag
    cpy #0
    bne L1                      ; Branch if set, or already an import
    lda importCount
    sta ptr3
    lda importCount+1
    sta ptr3+1
    lda #TAG_IMPORT
    sta ptr3+2
    lda #<tagToFind
    ldx #>tagToFind
    jsr linkTagSet
    incWord importCount
    bra L1
.endproc

; This routine writes the imports: their count, then their names, in the
; order of their numbers.
.proc writeImports
    ldx #LFN_OBJ
    jsr CHKOUT
    lda importCount
    jsr CHROUT
    lda importCount+1
    jsr CHROUT

    lda #0
    sta importsWritten
    sta importsWritten+1
    jsr rewindTags
L1: ldq tagsToFind
    jsr isMemBufAtEnd
    bne :+
    rts
:   jsr readTag
    lda #<tagToFind
    ldx #>tagToFind
    jsr findLinkerTag
    cpy #TAG_IMPORT
    bne L1
    cmp importsWritten          ; The next one to write?
    bne L1
    cpx importsWritten+1
    bne L1
    incWord importsWritten

    ; The name
    ldx #LFN_OBJ
    jsr CHKOUT
    ldx #0
:   lda tagToFind,x
    beq :+
    inx
    cpx #OBJ_NAME_MAX
    bne :-
:   stx importLen
    txa
    jsr CHROUT
    ldx #0
:   cpx importLen
    beq L1
    lda tagToFind,x
    jsr CHROUT
    inx
    bra :-
.endproc

; This routine writes the relocations: their count, then one for each
; linker tag to find. An import's has LINKADDR_IMPORT in its kind and the
; import's number as its target.
.proc writeRelocations
    ldx #LFN_OBJ
    jsr CHKOUT
    lda relocCount
    jsr CHROUT
    lda relocCount+1
    jsr CHROUT

    ; Write each
    jsr rewindTags
L1: ldq tagsToFind
    jsr isMemBufAtEnd
    bne :+
    rts
:   jsr readTag
    lda #<tagToFind
    ldx #>tagToFind
    jsr findLinkerTag
    sta target
    stx target+1
    ldx #TAGTOFIND::type
    lda tagToFind,x
    cpy #TAG_IMPORT
    bne :+
    ora #LINKADDR_IMPORT
:   sta kind

    ldx #LFN_OBJ
    jsr CHKOUT
    ldx #TAGTOFIND::offset
    lda tagToFind,x
    jsr CHROUT
    lda tagToFind+1,x
    jsr CHROUT
    lda kind
    jsr CHROUT
    lda target
    jsr CHROUT
    lda target+1
    jsr CHROUT
    bra L1
.endproc

; This routine moves to the start of the tags to find
.proc rewindTags
    ldq tagsToFind
    stq ptr1
    lda #0
    tax
    jmp setMemBufPos
.endproc

; This routine reads the next tag to find into tagToFind
.proc readTag
    ldq tagsToFind
    stq ptr1
    lda #<tagToFind
    sta ptr2
    lda #>tagToFind
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #.sizeof(TAGTOFIND)
    ldx #0
    jmp readFromMemBuf
.endproc

; This routine copies the code file to the end of the object file, in
; blocks of up to 256 bytes so the channels change once a block. Both files
; are closed after.
.proc copyCode
    ldx DEVNUM
    lda #LFN_CODE
    tay
    iny
    jsr SETLFS
    ldx #<codeFn
    ldy #>codeFn
    lda #codeFn2-codeFn
    jsr SETNAM
    jsr OPEN

    ; Read a block. It ends at 256 bytes, or at the byte that sets STATUS:
    ; the last byte of the file, or the one that failed.
L1: ldx #LFN_CODE
    jsr CHKIN
    ldx #0
L2: phx
    jsr CHRIN
    plx
    sta copyBuf,x
    inx
    lda STATUS
    bne L3
    cpx #0
    bne L2
L3: sta copyStatus
    stx copyLen

    ; Write it
    ldx #LFN_OBJ
    jsr CHKOUT
    ldx #0
:   lda copyBuf,x
    jsr CHROUT
    inx
    cpx copyLen
    bne :-

    lda copyStatus
    beq L1                      ; Branch if there's more

    lda #LFN_CODE
    jsr CLOSE
    lda #LFN_OBJ
    jsr CLOSE
    jmp CLRCHN
.endproc
