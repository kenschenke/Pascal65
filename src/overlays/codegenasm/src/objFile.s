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
; imports and a relocation for each tag, then the code, copied from zzcode
; (see linker.inc for the format). It deletes zzcode and frees the tags, so
; code generation leaves nothing in the heap for the linker.
;
; Every label is in this module, so a relocation's target is the label's
; offset in the code. The object file has no symbols or imports yet.

.include "c64.inc"
.include "asm.inc"
.include "asmlib.inc"
.include "ast.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "error.inc"

LFN_OBJ = 1                 ; logical file numbers
LFN_CODE = 2

.export writeObjFile, objFilename, codeFilename

.import runtimeFeatures

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

tagsToFind: .res 4
tagToFind: .res .sizeof(TAGTOFIND)
relocCount: .res 2
target: .res 2              ; the target of the relocation being written
nameLen: .res 1
nameBuf: .res NAMELEN
copyLen: .res 1             ; bytes in copyBuf, 0 for 256
copyStatus: .res 1          ; STATUS after the last byte read
copyBuf: .res 256

.code

; This routine writes the object file. The AST root is in Q.
.proc writeObjFile
    stq ptr1
    jsr copyModuleName

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

    ; The runtime features
    lda runtimeFeatures
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

    ; The BSS length, the symbols and the imports: none yet
    ldx #6
:   lda #0
    jsr CHROUT
    dex
    bne :-

    jsr writeRelocations
    jsr copyCode

    ; Delete the code file
    lda #<codeFilename
    ldx #>codeFilename
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile

    jmp freeLinkerTags
.endproc

; This routine copies the name of the module (decl::name) at ptr1 to
; nameBuf and sets nameLen.
.proc copyModuleName
    ldz #decl::name
    ldx #0
:   nop
    lda (ptr1),z
    beq :+
    sta nameBuf,x
    inz
    inx
    cpx #NAMELEN
    bne :-
:   stx nameLen
    rts
.endproc

; This routine writes the relocations: their count, then one for each
; linker tag to find. A label that was never set is a compiler error,
; errUndefinedLabel, and its name is printed after it.
.proc writeRelocations
    jsr getLinkerTagsToFind
    stq tagsToFind

    ; Count them
    lda #0
    sta relocCount
    sta relocCount+1
    jsr rewindTags
L1: ldq tagsToFind
    jsr isMemBufAtEnd
    beq L2
    jsr readTag
    inc relocCount
    bne L1
    inc relocCount+1
    bra L1

L2: ldx #LFN_OBJ
    jsr CHKOUT
    lda relocCount
    jsr CHROUT
    lda relocCount+1
    jsr CHROUT

    ; Write each
    jsr rewindTags
L3: ldq tagsToFind
    jsr isMemBufAtEnd
    bne :+
    rts
:   jsr readTag
    lda #<tagToFind
    ldx #>tagToFind
    jsr findLinkerTag
    sta target
    stx target+1
    cpy #0
    bne L4                      ; Branch if the label is set
    jsr undefinedLabel

L4: ldx #LFN_OBJ
    jsr CHKOUT
    ldx #TAGTOFIND::offset
    lda tagToFind,x
    jsr CHROUT
    lda tagToFind+1,x
    jsr CHROUT
    ldx #TAGTOFIND::type
    lda tagToFind,x
    jsr CHROUT
    lda target
    jsr CHROUT
    lda target+1
    jsr CHROUT
    bra L3
.endproc

; This routine reports the label in tagToFind, which was never set
.proc undefinedLabel
    jsr CLRCHN
    lda #errUndefinedLabel
    ldx #0
    ldy #0
    jsr compilerError
    ldx #0
:   lda tagToFind,x
    beq :+
    jsr CHROUT
    inx
    cpx #TAGTOFIND::type        ; the label's size
    bne :-
:   lda #13
    jmp CHROUT
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
