;
; imports.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The object file's imports
;
; The object file names each import once, and a relocation for one gives
; its number (linker.inc). readImports puts each name in the linker tags
; tree (linkerTags.s in asmlib) with its number. Laying out the program
; defines the symbols: each library slot (loadLibrary.s) and each linker
; symbol (runtimeBss.s). defineSymbol looks the name up and, if the module
; imports it, keeps its address under the import's number. checkImports
; then reports any import that nothing defined.
;
; The addresses are a block in the heap, IMP_SIZE bytes for each import by
; number, so a relocation finds its import's at once. The names are in a
; membuf, read in order only to report an import nothing defined.

.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "error.inc"

IMP_FLAG = 0                ; an import's record: non-zero once defined
IMP_ADDR = 1                ; and its address
IMP_SIZE = 3

.export readImports, defineSymbol, importAddress, checkImports
.export initImports, freeImports, symName

.import readByte, readName, readStatus

.bss

impAddrs: .res 4            ; the block of address records, by number
impNames: .res 4            ; membuf of the names, OBJ_NAME_MAX + 1 each
impCount: .res 2
impNum: .res 2              ; an import's number
impAddr: .res 2             ; the address to define
symName: .res OBJ_NAME_MAX + 1  ; the symbol to define, null-terminated
undefined: .res 1           ; non-zero if checkImports found one

.code

; This routine starts with no imports
.proc initImports
    lda #0
    tax
    tay
    taz
    stq impAddrs
    stq impNames
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
:   jmp initImports
.endproc

; This routine reads the object file's imports. The carry is set if the
; file is bad.
.proc readImports
    jsr allocMemBuf
    stq impNames

    jsr readByte
    sta impCount
    jsr readByte
    sta impCount+1

    ; The block, which heapAlloc zeros. It has a record more than needed,
    ; so it isn't empty.
    lda impCount
    ldx impCount+1
    jsr recordOffset
    clc
    adc #IMP_SIZE
    bcc :+
    inx
:   jsr heapAlloc
    stq impAddrs

    lda #0
    sta impNum
    sta impNum+1
L1: lda impNum
    cmp impCount
    bne :+
    lda impNum+1
    cmp impCount+1
    bne :+
    clc                         ; All read
    rts

:   jsr readName                ; Into symName
    bcc :+
    rts
:   lda readStatus
    beq :+
    sec
    rts

    ; Its name, for checkImports
:   ldq impNames
    stq ptr1
    jsr ptr2ToName
    lda #OBJ_NAME_MAX + 1
    ldx #0
    jsr writeToMemBuf

    ; The tag, with the import's number and a flag of 1
    lda impNum
    sta ptr3
    lda impNum+1
    sta ptr3+1
    lda #1
    sta ptr3+2
    lda #<symName
    ldx #>symName
    jsr linkTagSet

    inc impNum
    bne L1
    inc impNum+1
    bra L1
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

; This routine returns the address of the import numbered in A/X, in A/X
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
