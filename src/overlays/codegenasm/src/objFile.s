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
; Code generation writes the code to zzcode as it goes and keeps the linker
; tags in the heap (linkerTags.s in asmlib). When the code is done,
; writeObjFile writes the object file, zztmp: a header, the symbols, the
; imports, the libraries and a relocation for each tag, then the code,
; copied from zzcode (see linker.inc for the format). It deletes zzcode and
; frees the tags, so code generation leaves nothing in the heap for the
; linker.
;
; A label set in this module is a relocation's target as its offset in the
; code. A label that isn't set is an import: a library's slot or a linker
; symbol, which the linker resolves. Each import is added to the tags with
; its number, so a relocation finds it as it finds a label.

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
.export setRuntimeFeatures, setRuntimeMode, nameBuf, nameLen

.import runtimeStackSize, writeLibraries, freeImports

.data

objFilename: .asciiz "zztmp"
objFn: .byte "zztmp,s,w"
objFn2:
codeFilename: .asciiz "zzcode"
codeFn: .byte "zzcode,s,r"
codeFn2:

; The start of the header
objHeader:
    .byte OBJ_MAGIC0, OBJ_MAGIC1, OBJ_VERSION, RT_ABI_VERSION
    .byte OBJ_KIND_PROGRAM, 0
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

; This routine sets the runtime mode (RT_MODE_* in asm.inc) in A
.proc setRuntimeMode
    sta runtimeMode
    rts
.endproc

; This routine writes the object file. The module's
; name, runtime mode and stack size come from the icode file's header
; (readIcodeHeader) and the features from its EOM.
.proc writeObjFile
    jsr addImports

    ; Open the object file
    ldx DEVNUM
    lda #LFN_OBJ
    tay
    iny
    jsr SETLFS
    ldx #<objFn
    ldy #>objFn
    lda #objFn2-objFn
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

    ; The global slots, which only a unit has
:   lda #0
    jsr CHROUT
    lda #0
    jsr CHROUT

    ; The code length
    lda codeOffset
    jsr CHROUT
    lda codeOffset+1
    jsr CHROUT

    ; The BSS length and the symbols: none yet
    ldx #4
:   lda #0
    jsr CHROUT
    dex
    bne :-

    jsr writeImports
    jsr writeLibraries
    jsr writeRelocations
    jsr copyCode

    ; Delete the code file
    lda #<codeFilename
    ldx #>codeFilename
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile

    jsr freeImports
    jmp freeLinkerTags
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
