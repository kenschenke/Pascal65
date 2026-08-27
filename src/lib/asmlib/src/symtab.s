;
; symtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Symbol table - implemented using binary tree in ASMLIB

.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

MAX_STACK_DEPTH = 8

.export initScopeStack, scopeEnter, scopeEnterSymtab, scopeExit, scopeLevel
.export scopeLookup, scopeLookupParent, scopeLookupCurrent, symtabLookup
.export scopeBind, scopeBindSymtab

.import isQZero, rtPopQ, rtPushQ, rtCompilerError, findInTree, addTreeNode

.bss

; Pointers to symbol trees
symbolStack: .res MAX_STACK_DEPTH * 4
currentStackLevel: .res 1
tmpSymtab: .res 4

; Used by scopeLookup
level: .res 1

.code

; Look up node in tree
; Inputs:
;    ptr1 - tree root
;    ptr4 - key
; Returns:
;    symbol table node's data in Q or NULL if not found
.proc lookupSymbol
    jmp findInTree
.endproc

; Adds a symbol table node to the current scope's symtab
; Inputs:
;    ptr2 - key
;    ptr3 - data to be stored in the node
;    carry flag - set if failure on key already existing in symtab
; Returns:
;    The symtab tree root is returned in Q
;    carry flag is set on failure
;
; Note: The carry flag is only set on exit if the key already existed
;       in the symbol table AND the carry flag was set on entry.
.proc scopeBind
    php
    lda currentStackLevel
    asl a
    asl a
    tax
    ldy #0
:   lda symbolStack,x
    sta ptr1,y
    inx
    iny
    cpy #4
    bne :-
    plp
    jsr scopeBindSymtab
    php
    ; Copy the root back to the symtabStack
    stq ptr1
    lda currentStackLevel
    asl a
    asl a
    tax
    ldy #0
:   lda ptr1,y
    sta symbolStack,x
    inx
    iny
    cpy #4
    bne :-
    ldq ptr1
    plp
    rts
.endproc

; Adds a symbol table node to the symtab in ptr1
; Inputs:
;    ptr1 - symbol table (or NULL on empty table)
;    ptr2 - key
;    ptr3 - data to be stored in the node
;    carry flag - set if failure on key already existing in symtab
; Returns:
;    The symtab tree root is returned in Q
;    carry flag is set on failure
;
; Note: The carry flag is only set on exit if the key already existed
;       in the symbol table AND the carry flag was set on entry.
.proc scopeBindSymtab
    php             ; Save CPU flags
    ldq ptr1
    jsr isQZero
    bne L1          ; Branch if current symtab is non-NULL

    ; Tree is empty - add the root node
    plp             ; Discard CPU flags
    clc             ; Clear the carry flag
    jsr addTreeNode
    ldq ptr4
    rts

    ; Tree is non-empty
L1: ldq ptr2
    stq ptr4
    ldq ptr1
    jsr rtPushQ
    jsr findInTree
    jsr isQZero
    beq L2
    ; Key already exists in tree
    plp             ; Restore the CPU flags
    jsr rtPopQ
    rts

    ; Key does not exist in tree - so add it
L2: jsr rtPopQ      ; Pop the tree root back off the stack
    stq ptr1        ; and store it in ptr1.
    jsr rtPushQ     ; Keep the tree root
    clc             ; Clear the carry flag
    plp             ; Restore the CPU flags
    jsr addTreeNode
    jsr rtPopQ      ; Pop the tree root
    rts
.endproc

; Look up symbol node in current scope and all inherited scopes
; Inputs:
;    ptr4 - key
; Returns:
;    symbol table node in Q or NULL if not found
.proc scopeLookup
    lda currentStackLevel
    sta level
    jmp scopeLookupLoop
.endproc

; Look up symbol node in parent scope and all inherited scopes
; Inputs:
;    ptr4 - key
; Returns:
;    symbol table node in Q or NULL if not found
.proc scopeLookupParent
    lda currentStackLevel
    sta level
    dec level
    jmp scopeLookupLoop
.endproc

; Look up symbol node in current scope
; Inputs:
;    ptr4 - key
; Returns:
;    symbol table node's data in Q or NULL if not found
.proc scopeLookupCurrent
    lda currentStackLevel
    asl a
    asl a
    tax
    ldy #0
:   lda symbolStack,x
    sta ptr1,y
    inx
    iny
    cpy #4
    bne :-

    jmp lookupSymbol
.endproc

; Look up symbol node in symbol table
; Inputs:
;    ptr1 - tree root
;    ptr4 - key
; Returns:
;    symbol table node's data in Q or NULL if not found
.proc symtabLookup
    jmp lookupSymbol
.endproc

; Look up symbol node in tree (called by scopeLookup and scopeLookupParent)
; Inputs:
;    ptr4 - key
; Returns:
;    symbol table node's data in Q or NULL if not found
.proc scopeLookupLoop
L1: lda level
    bmi L2

    asl a
    asl a
    tax
    ldy #0
:   lda symbolStack,x
    sta ptr1,y
    inx
    iny
    cpy #4
    bne :-

    jsr lookupSymbol
    jsr isQZero
    bne L3

    dec level
    bpl L1

L2: lda #0
    tax
    tay
    taz

L3: rts
.endproc

.proc initScopeStack
    lda #0
    sta currentStackLevel

    tax
    tay
    taz
    stq symbolStack

    rts
.endproc

.proc scopeEnter
    inc currentStackLevel
    lda currentStackLevel
    cmp #MAX_STACK_DEPTH
    bne :+

    lda #errNestingTooDeep
    ldx #0
    ldy #0
    jsr rtCompilerError
    rts

:   lda currentStackLevel
    asl a
    asl a
    tay

    lda #0
    tax
:   sta symbolStack,y
    iny
    inx
    cpx #4
    bne :-

    rts
.endproc

.proc scopeEnterSymtab
    stq tmpSymtab
    inc currentStackLevel
    lda currentStackLevel
    asl a
    asl a
    tax
    ldy #0
:   lda tmpSymtab,y
    sta symbolStack,x
    inx
    iny
    cpy #4
    bne :-
    rts
.endproc

.proc scopeExit
    lda currentStackLevel
    asl a
    asl a
    tax
    ldy #0
:   lda symbolStack,x
    sta tmpSymtab,y
    inx
    iny
    cpy #4
    bne :-

    dec currentStackLevel
    ldq tmpSymtab
    rts
.endproc

.proc scopeLevel
    lda currentStackLevel
    rts
.endproc
