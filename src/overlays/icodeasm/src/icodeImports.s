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
; each library the program or any of its units uses, in the units list's
; order, with the kinds of its jump table's slots in order: its init and
; cleanup, then a routine or variable for each of its interface's entries
; (icodeExports.s). The code
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

.import units, entryStart, entryNext, entryNum, moduleUnit, inModule

.bss

thisUnit: .res 4            ; the unit being looked at
unitName: .res 4
libRoot: .res 4             ; the library's AST root
libCount: .res 1
writing: .res 1             ; zero while counting, non-zero while writing
slotCount: .res 2
labelLen: .res 1
label: .res 24

.code

; This routine writes the imports table to the current output: the count,
; then each library and Pascal unit the module imports (inModule): the
; program imports the whole units list, so a library or unit only a unit
; uses is there too, and a unit those its Uses name and System. They're
; in the units list's order: each unit after the units it uses
; (orderUnits in the resolver), otherwise the order the parser met them.
.proc writeImports
    ; Count them, then write them
    lda #0
    sta writing
    jsr walkUses
    lda libCount
    jsr CHROUT
    inc writing
    ; Fall through
.endproc

; This routine counts the imports in libCount, or writes each one.
.proc walkUses
    lda #0
    sta libCount
    ldq units
L1: stq thisUnit
    jsr isQZero
    bne :+
    rts

:   stq unitName            ; unit::name is its first member
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

    ; Only what the module imports, not the module itself
    ldx #3
:   lda thisUnit,x
    cmp moduleUnit,x
    bne :+
    dex
    bpl :-
    bra NX
:   ldq thisUnit
    jsr inModule
    bcc NX

    inc libCount
    lda writing
    beq NX
    ldq libRoot
    stq ptr2
    ldz #decl::isLibrary
    nop
    lda (ptr2),z
    bne :+
    jsr writeUnit
    bra NX
:   jsr writeLibrary

NX: ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
.endproc

; This routine writes the Pascal unit in unitName: its kind
; (ICODE_IMPORT_UNIT) and name. Its code is in its own icode file.
.proc writeUnit
    lda #ICODE_IMPORT_UNIT
    jsr CHROUT
    jmp writeName
.endproc

; This routine writes the library in unitName and libRoot: its kind
; (ICODE_IMPORT_LIBRARY), name, slot count and each slot's kind.
.proc writeLibrary
    lda #ICODE_IMPORT_LIBRARY
    jsr CHROUT
    jsr writeName

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
; This routine writes the name of the unit in unitName: its length, then
; its characters
.proc writeName
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
    ; Fall through to writeLabel
.endproc

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

