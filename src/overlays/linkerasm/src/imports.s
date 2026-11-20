;
; imports.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The object files' imports
;
; Each object file names each of its imports once, and a relocation for
; one gives its number in that file (linker.inc). readImports gives each
; name a number for the whole link, in the linker tags tree (linkerTags.s
; in asmlib), the first time a module imports it, and makes the module a
; map from its numbers to those. Laying out the program defines the
; symbols: each library slot (loadLibrary.s), each linker symbol
; (runtimeBss.s), and the frames and the modules' exports, which are read
; before the layout and kept until then (deferSymbol, defineDeferred).
; defineSymbol looks the name up and, if a module imports it, keeps its
; address under its number. checkImports then reports any import that
; nothing defined.
;
; The addresses are a block in the heap, IMP_SIZE bytes for each import by
; number, so a relocation finds its import's at once. The names are in a
; membuf, read in order only to report an import nothing defined.
;
; A deferred symbol is a record in a membuf: its name, the module whose
; code it is in (or $FF for an address) and its offset there.

.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "error.inc"

IMP_FLAG = 0                ; an import's record: non-zero once defined
IMP_ADDR = 1                ; and its address
IMP_SIZE = 3

DEF_NAME = 0                ; a deferred symbol's record
DEF_MODULE = OBJ_NAME_MAX + 1
DEF_VALUE = DEF_MODULE + 1
DEF_SIZE = DEF_VALUE + 2

.export readImports, defineSymbol, importAddress, checkImports, mapImport
.export setImportMap
.export initImports, freeImports, symName, allocImports
.export deferSymbol, defineDeferred

.import readByte, readName, readStatus, modBase

.bss

impAddrs: .res 4            ; the block of address records, by number
impNames: .res 4            ; membuf of the names, OBJ_NAME_MAX + 1 each
impCount: .res 2
impNum: .res 2              ; an import's number
impAddr: .res 2             ; the address to define
symName: .res OBJ_NAME_MAX + 1  ; the symbol to define, null-terminated
undefined: .res 1           ; non-zero if checkImports found one
impMap: .res 4              ; the module being read's map
impLeft: .res 2
localNum: .res 2            ; an import's number in its module
deferred: .res 4            ; the deferred symbols, a membuf, or 0
defRec: .res DEF_SIZE

.code

; This routine starts with no imports
.proc initImports
    lda #0
    tax
    tay
    taz
    stq impAddrs
    stq impNames
    stq deferred
    sta impCount
    sta impCount+1
    rts
.endproc

; This routine frees the imports' block and membuf, if they were allocated
.proc freeImports
    ldq impAddrs
    jsr isQZero
    beq :+
    jsr heapFree
:   ldq impNames
    jsr isQZero
    beq :+
    jsr freeMemBuf
:   ldq deferred
    jsr isQZero
    beq :+
    jsr freeMemBuf
:   jmp initImports
.endproc

; This routine reads a module's imports and returns its map in Q: a heap
; block of a word for each, the import's number for the whole link. A
; name another module imported already keeps its number. The carry is set
; if the file is bad.
.proc readImports
    ldq impNames
    jsr isQZero
    bne :+
    jsr allocMemBuf
    stq impNames

:   jsr readByte
    sta impLeft
    jsr readByte
    sta impLeft+1

    ; The map, which has a word more than needed, so it isn't empty
    lda impLeft
    asl a
    tay
    lda impLeft+1
    rol a
    tax
    tya
    clc
    adc #2
    bcc :+
    inx
:   jsr heapAlloc
    stq impMap

    lda #0
    sta localNum
    sta localNum+1
L1: lda localNum
    cmp impLeft
    bne :+
    lda localNum+1
    cmp impLeft+1
    bne :+
    ldq impMap                  ; All read
    clc
    rts

:   jsr readName                ; Into symName
    bcc :+
    rts
:   lda readStatus
    beq :+
    sec
    rts

    ; Its number: another module's import's, or the next
:   lda #<symName
    ldx #>symName
    jsr findLinkerTag
    cpy #0
    bne MP
    jsr addImport
    lda impNum
    ldx impNum+1

    ; The map's word for it
MP: pha
    phx
    lda localNum
    asl a
    sta intOp32
    lda localNum+1
    rol a
    sta intOp32+1
    lda #0
    sta intOp32+2
    sta intOp32+3
    ldq impMap
    clc
    adcq intOp32
    stq ptr1
    ldz #1
    pla
    nop
    sta (ptr1),z
    dez
    pla
    nop
    sta (ptr1),z

    inc localNum
    bne L1
    inc localNum+1
    bra L1
.endproc

; This routine gives the name in symName the next number, impCount, in
; impNum, and adds one to impCount
.proc addImport
    lda impCount
    sta impNum
    lda impCount+1
    sta impNum+1

    ; Its name, for checkImports
    ldq impNames
    stq ptr1
    jsr ptr2ToName
    lda #OBJ_NAME_MAX + 1
    ldx #0
    jsr writeToMemBuf

    ; The tag, with its number and a flag of 1
    lda impNum
    sta ptr3
    lda impNum+1
    sta ptr3+1
    lda #1
    sta ptr3+2
    lda #<symName
    ldx #>symName
    jsr linkTagSet

    inc impCount
    bne :+
    inc impCount+1
:   rts
.endproc

; This routine allocates the block of the imports' addresses, once every
; module's imports are read. heapAlloc zeros it. It has a record more than
; needed, so it isn't empty.
.proc allocImports
    lda impCount
    ldx impCount+1
    jsr recordOffset
    clc
    adc #IMP_SIZE
    bcc :+
    inx
:   jsr heapAlloc
    stq impAddrs
    rts
.endproc

; This routine keeps the symbol named in symName, to define once the
; modules are placed (defineDeferred): at the offset in A/X in the module
; numbered in Y, or at the address in A/X if Y is $FF
.proc deferSymbol
    sta defRec+DEF_VALUE
    stx defRec+DEF_VALUE+1
    sty defRec+DEF_MODULE
    ldx #0
:   lda symName,x
    sta defRec+DEF_NAME,x
    inx
    cpx #OBJ_NAME_MAX+1
    bne :-
    ldq deferred
    jsr isQZero
    bne :+
    jsr allocMemBuf
    stq deferred
:   ldq deferred
    stq ptr1
    jsr ptr2ToRec
    lda #DEF_SIZE
    ldx #0
    jmp writeToMemBuf
.endproc

; This routine defines each deferred symbol: an offset in a module from
; the module's address (modBase), or an address
.proc defineDeferred
    ldq deferred
    jsr isQZero
    bne :+
    rts
:   ldq deferred
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos
L1: ldq deferred
    jsr isMemBufAtEnd
    bne :+
    rts
:   ldq deferred
    stq ptr1
    jsr ptr2ToRec
    lda #DEF_SIZE
    ldx #0
    jsr readFromMemBuf
    ldx #0
:   lda defRec+DEF_NAME,x
    sta symName,x
    inx
    cpx #OBJ_NAME_MAX+1
    bne :-
    lda defRec+DEF_VALUE
    ldx defRec+DEF_VALUE+1
    ldy defRec+DEF_MODULE
    cpy #$ff
    beq DF
    pha
    tya
    asl a
    tay
    pla
    clc
    adc modBase,y
    pha
    txa
    adc modBase+1,y
    tax
    pla
DF: jsr defineSymbol
    bra L1
.endproc

; This routine points ptr2 at defRec
.proc ptr2ToRec
    lda #<defRec
    sta ptr2
    lda #>defRec
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    rts
.endproc

; This routine defines the symbol named in symName at the address in A/X.
; If the module imports it, the import gets the address.
.proc defineSymbol
    sta impAddr
    stx impAddr+1
    lda #<symName
    ldx #>symName
    jsr findLinkerTag
    cpy #0
    bne :+
    rts                         ; Not imported
:   jsr pointAtRecord
    ldz #IMP_FLAG
    lda #1
    nop
    sta (ptr1),z
    ldz #IMP_ADDR
    lda impAddr
    nop
    sta (ptr1),z
    inz
    lda impAddr+1
    nop
    sta (ptr1),z
    rts
.endproc

; This routine sets the map (readImports) that mapImport uses, from Q
.proc setImportMap
    stq impMap
    rts
.endproc

; This routine returns the address of the import numbered in A/X in the
; module whose map setImportMap set, in A/X
.proc mapImport
    sta intOp32
    stx intOp32+1
    asl intOp32
    rol intOp32+1
    lda #0
    sta intOp32+2
    sta intOp32+3
    ldq impMap
    clc
    adcq intOp32
    stq ptr1
    ldz #1
    nop
    lda (ptr1),z
    tax
    dez
    nop
    lda (ptr1),z
    ; Fall through
.endproc

; This routine returns the address of the import numbered in A/X (for the
; whole link), in A/X
.proc importAddress
    jsr pointAtRecord
    ldz #IMP_ADDR+1
    nop
    lda (ptr1),z
    tax
    dez
    nop
    lda (ptr1),z
    rts
.endproc

; This routine points ptr1 at the record of the import numbered in A/X
.proc pointAtRecord
    jsr recordOffset
    sta intOp32
    stx intOp32+1
    lda #0
    sta intOp32+2
    sta intOp32+3
    ldq impAddrs
    clc
    adcq intOp32
    stq ptr1
    rts
.endproc

; This routine returns A/X * IMP_SIZE in A/X
.proc recordOffset
    sta tmp1
    stx tmp2
    asl a
    pha
    txa
    rol a
    tax
    pla
    clc
    adc tmp1
    pha
    txa
    adc tmp2
    tax
    pla
    rts
    .assert IMP_SIZE = 3, error, "recordOffset multiplies by 3"
.endproc

; This routine points ptr2 at symName
.proc ptr2ToName
    lda #<symName
    sta ptr2
    lda #>symName
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    rts
.endproc

; This routine reports each import that nothing defined as
; errUndefinedLabel, followed by its name. The carry is set if there was
; one.
.proc checkImports
    lda #0
    sta undefined
    sta impNum
    sta impNum+1
    ldq impNames
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

L1: lda impNum
    cmp impCount
    bne :+
    lda impNum+1
    cmp impCount+1
    bne :+
    lda undefined
    cmp #1                      ; The carry is set if there was one
    rts

:   ldq impNames
    stq ptr1
    jsr ptr2ToName
    lda #OBJ_NAME_MAX + 1
    ldx #0
    jsr readFromMemBuf
    lda impNum
    ldx impNum+1
    jsr pointAtRecord
    ldz #IMP_FLAG
    nop
    lda (ptr1),z
    bne NX                      ; Branch if it's defined

    lda #1
    sta undefined
    jsr CLRCHN
    lda #errUndefinedLabel
    ldx #0
    ldy #0
    jsr compilerError
    ldx #0
:   lda symName,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT

NX: inc impNum
    bne L1
    inc impNum+1
    bra L1
.endproc
