;
; icodeImports.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; writeImports routine
;
; The icode file's imports table follows its header (icode.inc). It lists
; each library the program uses, in its Uses order, with the kinds of its
; jump table's slots in order: its init and cleanup, then a routine or
; variable for each of its interface's entries (icodeExports.s). The code
; names a slot by the library and its number ("name.N"), so the table
; needs no labels. Code generation calls each library's init and cleanup
; (slots 0 and 1) and copies each entry into the object file, where the
; linker defines a symbol at each slot (linker.inc and loadLibrary.s in
; linkerasm).

.include "ast.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.include "icode.inc"

.export writeImports

.import findUnit, entryStart, entryNext, entryNum

.bss

firstDecl: .res 4           ; the program's first declaration
usesDecl: .res 4            ; the Uses declaration being looked at
unitName: .res 4
libRoot: .res 4             ; the library's AST root
libCount: .res 1
writing: .res 1             ; zero while counting, non-zero while writing
slotCount: .res 2
labelLen: .res 1
label: .res 24

.code

; This routine writes the imports table to the current output: the count,
; then each library the program uses. The AST root is in Q.
.proc writeImports
    ; The first declaration of the program's code block
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq firstDecl

    ; Count them, then write them
    lda #0
    sta writing
    jsr walkUses
    lda libCount
    jsr CHROUT
    inc writing
    ; Fall through
.endproc

; This routine counts the libraries in the program's Uses declarations in
; libCount, or writes each one.
.proc walkUses
    lda #0
    sta libCount
    ldq firstDecl
L1: stq usesDecl
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    bne NX

    ldq ptr1
    ldz #decl::name
    jsr calcNamePtr
    stq unitName
    jsr findUnit
    jsr isQZero
    beq NX

    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq libRoot
    ; A unit that wasn't parsed (icodetest's tests without units) has none
    jsr isQZero
    beq NX
    ldq libRoot
    stq ptr2
    ldz #decl::isLibrary
    nop
    lda (ptr2),z
    beq NX

    inc libCount
    lda writing
    beq NX
    jsr writeLibrary

NX: ldq usesDecl
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
.endproc

; This routine writes the library in unitName and libRoot: its kind
; (ICODE_IMPORT_LIBRARY), name, slot count and each slot's kind.
.proc writeLibrary
    lda #ICODE_IMPORT_LIBRARY
    jsr CHROUT

    ; The name
    ldq unitName
    stq ptr1
    ldz #0
    ldx #0
:   nop
    lda (ptr1),z
    beq :+
    sta label,x
    inz
    inx
    cpx #OBJ_NAME_MAX
    bne :-
:   stx labelLen
    jsr writeLabel

    ; The slot count: init and cleanup, then the entries, which end one
    ; less
    ldq libRoot
    jsr entryStart
:   jsr entryNext
    bcc :-
    lda entryNum
    clc
    adc #1
    sta slotCount
    lda entryNum+1
    adc #0
    sta slotCount+1
    lda slotCount
    jsr CHROUT
    lda slotCount+1
    jsr CHROUT

    ; The slots' kinds
    lda #OBJLIB_ROUTINE         ; init
    jsr CHROUT
    lda #OBJLIB_ROUTINE         ; cleanup
    jsr CHROUT
    ldq libRoot
    jsr entryStart
:   jsr entryNext
    bcs :+
    jsr CHROUT
    bra :-
:   rts
.endproc

; This routine writes the name in label, labelLen characters long
.proc writeLabel
    lda labelLen
    jsr CHROUT
    ldx #0
:   cpx labelLen
    beq :+
    lda label,x
    jsr CHROUT
    inx
    bra :-
:   rts
.endproc


; This routine adds the offset in Z to the pointer in A/X/Y and returns the
; sum in Q (as calcNamePtr in codegenasm).
.proc calcNamePtr
    stz intOp32
    ldz #0
    stz intOp32+1
    stz intOp32+2
    stz intOp32+3
    clc
    adcq intOp32
    rts
.endproc
