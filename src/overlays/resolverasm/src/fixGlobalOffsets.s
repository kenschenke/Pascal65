;
; fixGlobalOffsets.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; fixGlobalOffsets routine

.include "ast.inc"
.include "tree.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

symtabOffset = 0

.export fixGlobalOffsets

.import units, calcNamePtr

.bss

name: .res 4
currentUnit: .res 4
leftNode: .res 4
rightNode: .res 4

.code

; This routine fixes offsets for unit interface variables that 
; have been injected into the global namespace. Since these injected
; symbol table entries were done with a declaration, their offsets are
; set by setDeclOffsets.
;
; This routine walks the global symbol table and if it finds any symbols
; with level and offset values of 0 it looks through the units for any
; matching variables in the interface declaration. If it finds a match
; it updates the offset and level.
;
; Input: unit astRoot in Q
;
; A table whose names were added in order is a chain as long as the table,
; so the walk keeps the nodes still to visit on the runtime stack, not in
; calls: a recursive walk on a long chain ran out of CPU stack. A zero
; below them marks the end.
.proc fixGlobalOffsets
    stq ptr1
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    rts
:   stq name
    jsr pushQZero           ; the end marker
    ldq name
    jsr pushQ

    ; The node on top of the stack
L1: jsr loadSymtab
    ldq ptr1
    jsr isQZero
    bne :+
    jmp popQ                ; the end marker

:   ldz #TREENODE::data
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq L2

    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_FUNCTION
    beq L2
    cmp #TYPE_PROCEDURE
    beq L2
    ldz #symbol::offset
    nop
    lda (ptr1),z
    bne L2
    ldz #symbol::level
    nop
    lda (ptr1),z
    bne L2

    jsr fixOffsets

    ; Replace the node with its children
L2: jsr loadSymtab
    ldz #TREENODE::left
    neg
    neg
    nop
    lda (ptr1),z
    stq leftNode
    ldz #TREENODE::right
    neg
    neg
    nop
    lda (ptr1),z
    stq rightNode
    jsr popQ
    ldq leftNode
    jsr isQZero
    beq :+
    jsr pushQ
:   ldq rightNode
    jsr isQZero
    bne :+
    jmp L1
:   jsr pushQ
    jmp L1
.endproc

; Loop through the units
; Input expectations:
;    ptr1 points to current symbol table node
.proc fixOffsets
    ldq units
    stq currentUnit

    ; The symbol's name is the key of the symbol table node on the stack
    jsr loadSymtab
    ldq ptr1
    ldz #TREENODE::key
    jsr calcNamePtr
    stq name

L1: ldq currentUnit
    jsr isQZero
    beq L3

    stq ptr2
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr1
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldq name
    stq ptr4
    jsr symtabLookup
    jsr isQZero
    beq L2
    stq ptr2
    jsr loadSymtab
    ldz #TREENODE::data
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symbol::level
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    ldz #symbol::offset
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    bra L3

L2: ldq currentUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq currentUnit
    jmp L1

L3: rts
.endproc

; This routine loads the symtab pointer on the stack into ptr1
.proc loadSymtab
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    rts
.endproc
