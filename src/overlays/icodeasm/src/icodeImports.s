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
; each library the program uses, in its Uses order, with the labels of its
; jump table's slots in order: its init and cleanup, then a routine or
; variable for each of its interface declarations. The code reaches a
; library through those labels, which are made from AST addresses, so code
; generation reads them here rather than from the AST. It calls each
; library's init and cleanup (slots 0 and 1) and copies each entry into the
; object file, where the linker defines each label at its slot (see
; linker.inc and loadLibrary.s in linkerasm).

.include "ast.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.include "icode.inc"

.export writeImports

.import findUnit

.data

strInit: .asciiz "init"
strCleanup: .asciiz "cleanup"
strRtnEnter: .asciiz "rtnenter"
strLibDecl: .asciiz "libdecl"

.bss

firstDecl: .res 4           ; the program's first declaration
usesDecl: .res 4            ; the Uses declaration being looked at
unitName: .res 4
libRoot: .res 4             ; the library's AST root
currentDecl: .res 4         ; its interface declaration being looked at
libCount: .res 1
writing: .res 1             ; zero while counting, non-zero while writing
slotCount: .res 2
slotKind: .res 1
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
; (ICODE_IMPORT_LIBRARY), name, slot count and slots.
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

    ; Count the slots, then write them
    lda #2                      ; init and cleanup
    sta slotCount
    lda #0
    sta slotCount+1
    sta writing
    jsr walkInterface
    lda slotCount
    jsr CHROUT
    lda slotCount+1
    jsr CHROUT
    inc writing

    ; Init and cleanup are labeled by the library's AST root
    ldq libRoot
    stq intOp32
    lda #OBJLIB_ROUTINE
    ldx #<strInit
    ldy #>strInit
    jsr writeSlot
    ldq libRoot
    stq intOp32
    lda #OBJLIB_ROUTINE
    ldx #<strCleanup
    ldy #>strCleanup
    jsr writeSlot
    ; Fall through
.endproc

; This routine counts the library's routines and variables in slotCount, or
; writes a slot for each.
.proc walkInterface
    ldq libRoot
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
L1: stq currentDecl
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2

    ; A routine is labeled by its declaration
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_FUNCTION
    beq RT
    cmp #TYPE_PROCEDURE
    beq RT

    ; A variable is labeled by its type
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_VARIABLE
    bne NX
    ldq ptr2
    stq intOp32
    lda #OBJLIB_VARIABLE
    ldx #<strLibDecl
    ldy #>strLibDecl
    bra SL
RT: ldq ptr1
    stq intOp32
    lda #OBJLIB_ROUTINE
    ldx #<strRtnEnter
    ldy #>strRtnEnter
SL: jsr slot

NX: ldq currentDecl
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
.endproc

; This routine counts a slot, or writes it while writing (see writeSlot)
.proc slot
    pha
    lda writing
    bne WR
    pla
    inc slotCount
    bne :+
    inc slotCount+1
:   rts
WR: pla
    jmp writeSlot
.endproc

; This routine writes a slot: its kind (OBJLIB_*) in A, then its label: the
; prefix in X/Y followed by intOp32 in hex.
.proc writeSlot
    sta slotKind
    stx ptr2
    sty ptr2+1
    ldy #0
:   lda (ptr2),y
    beq :+
    sta label,y
    iny
    bne :-
:   tya
    clc
    adc #<label
    pha
    lda #>label
    adc #0
    tax
    pla
    jsr hexstr

    ldx #0
:   lda label,x
    beq :+
    inx
    bne :-
:   stx labelLen
    lda slotKind
    jsr CHROUT
    ; Fall through
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
