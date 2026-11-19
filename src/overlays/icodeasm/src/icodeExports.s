;
; icodeExports.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; A module's entries: what code outside a unit or library can reach.
;
; A library's jump table slots and a Pascal unit's entries are numbered the
; same way: 0 is the module's init, 1 its cleanup, then from 2 each routine
; and variable of its interface, in order. A reference to one is named for
; the module and the number, "name.N" with N in decimal, rather than
; by a label made from an AST address. The module's own icode can define
; it and another module's can use it without either's AST. Code generation
; and the linker make the same names from the imports table.
;
; A unit's init block is its entry 0, a routine its body's LOC and a
; record or array variable its declaration block (DAT). A unit has no
; cleanup, and its scalar variables are slots in the level 1 frame, so
; those entries are numbered but never referenced.

.include "ast.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export entryStart, entryNext, entryNum, formatEntryLabel
.export icodeFormatDeclLabel, icodeFormatBlockLabel

.import units, icodeLabel, icodeFormatLabel

.bss

entryPtr: .res 4            ; the next interface declaration to look at
entryNum: .res 2            ; the number of the entry entryNext returned
entryDecl: .res 4           ; its declaration
key: .res 4                 ; for icodeFormatDeclLabel
prefix: .res 2
thisUnit: .res 4
blockOnly: .res 1            ; non-zero for icodeFormatBlockLabel
savedZp: .res 24            ; ptr1 to intOp2

.code

; This routine starts a walk of the entries of the module whose root
; declaration is in Q.
.proc entryStart
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
    stq entryPtr
    lda #1                  ; entryNext counts past it to 2
    sta entryNum
    lda #0
    sta entryNum+1
    rts
.endproc

; This routine returns the walk's next entry: its declaration in entryDecl
; and ptr1, its kind (OBJLIB_*) in A and its number in entryNum. The carry
; is set when there are no more. It changes ptr2.
.proc entryNext
L1: ldq entryPtr
    jsr isQZero
    bne :+
    sec
    rts

:   stq ptr1
    stq entryDecl
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq entryPtr
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L1
    stq ptr2

    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_FUNCTION
    beq RT
    cmp #TYPE_PROCEDURE
    beq RT
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_VARIABLE
    bne L1
    lda #OBJLIB_VARIABLE
    bra :+
RT: lda #OBJLIB_ROUTINE
:   inc entryNum
    bne :+
    inc entryNum+1
:   clc
    rts
.endproc

; This routine formats "name.N" in icodeLabel: the null-terminated name Q
; points to, a period, then entryNum in decimal. It changes ptr1, ptr2,
; tmp1 to tmp3 and intOp1 and intOp2.
.proc formatEntryLabel
    stq ptr1
    ldx #0
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    sta icodeLabel,x
    inx
    inz
    bne :-
:   lda #'.'
    sta icodeLabel,x
    inx
    lda entryNum
    sta intOp1
    lda entryNum+1
    sta intOp1+1
    txa
    clc
    adc #<icodeLabel
    pha
    lda #>icodeLabel
    adc #0
    tax
    pla
    jmp writeInt16
.endproc

; This routine formats the label of the declaration in intOp32 in
; icodeLabel, with the prefix in A/X, as icodeFormatLabel does. A routine
; or variable of a unit's or library's interface is an entry, so it is
; named for its module and number instead, whatever the prefix. A unit
; routine's symbol, and so its callers, name the routine's body, not its
; interface declaration. It keeps the zero page from ptr1 to intOp2, and
; intOp32.
.proc icodeFormatDeclLabel
    ldy #0
    bra formatLabel
.endproc

; As icodeFormatDeclLabel, for the label of a variable's declaration
; block (DAT), which DIR, DIA, DCC, DCF and SAL name. A unit's interface
; variable's block is its entry. A library's variables are the program's:
; its startup makes their blocks and puts only their addresses in the
; library's slots (SSP), so their blocks keep their own labels.
.proc icodeFormatBlockLabel
    ldy #1
    ; Fall through
.endproc

.proc formatLabel
    sty blockOnly
    sta prefix
    stx prefix+1
    ldq intOp32
    stq key
    ldx #23
:   lda ptr1,x
    sta savedZp,x
    dex
    bpl :-

    ldq units
L1: stq thisUnit
    jsr isQZero
    beq NF
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    ; A unit that wasn't parsed (icodetest's tests without units) has none
    jsr isQZero
    beq NX
    stq ptr2
    lda blockOnly
    beq :+
    ldz #decl::isLibrary
    nop
    lda (ptr2),z
    bne NX
:   ldq ptr2
    jsr entryStart

L2: jsr entryNext
    bcs NX
    ; The declaration the entry's symbol names
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr2
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr2),z
    bra :++
:   ldq entryDecl
:   cpq key
    bne L2
    ldq thisUnit            ; unit::name is its first member
    jsr formatEntryLabel
    bra DN

NX: ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L1

    ; Not an entry
NF: ldq key
    stq intOp32
    lda prefix
    ldx prefix+1
    jsr icodeFormatLabel

DN: ldq key
    stq intOp32
    ldx #23
:   lda savedZp,x
    sta ptr1,x
    dex
    bpl :-
    rts
.endproc
