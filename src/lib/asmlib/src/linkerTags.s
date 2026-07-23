;
; linkerTags.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "tree.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "4510macros.inc"

codeBase = $2001

; This file implements the linker tags system. This is used by the object
; code generator and the linker to resolve addresses in the program file.
;
; The linker tags system works by marking a location in the object code
; that needs an address resolved. Sometimes it only needs to know the
; low-order byte, or the high-order byte. Other times it needs to know
; the entire 16-bit address.
;
; The locations are identified by a label - an alpha-numeric string.
; When an address is needed, the label and an indicator for the low-order,
; high-order, or both are written to a memory buffer (membuf).
;
; When an identifiable location is being written to the object file,
; the label and the location are saved in a binary tree.
;
; Once all the object code is written, the linker goes through the list of
; requested locations (from the membuf) and finds each in the binary tree
; by the label. The requested address is then written back to the object file.

.export linkAddressLookup, linkAddressSet, initLinkerTags, freeLinkerTags
.export getLinkerTagsToFind, findLinkerTag

.import isQZero, addTreeNode, writeToMemBuf, addInt16, allocMemBuf, findInTree
.import heapFree, rtPushQ, rtPopQ, loadPtr, freeMemBuf

.bss

; Temporary storage for writing to membuf
linkerTag: .res .sizeof(TAGTOFIND)

; This is a binary tree of the linker tags. That is, locations in the object code
; that are identified with a label. These can be routines or data.
linkerTags: .res 4

; This is a memory buffer of linker tags that need to be resolved by the linker.
tagsToFind: .res 4

; These are for freeing linker tags
tagTreeNode: .res 4
tagTreeStackSize: .res 2

.code

; Finds a label in the binary tree.
; Null-terminated label in A/X
; Code offset returned in A/X.
.proc findLinkerTag
    sta ptr4
    stx ptr4+1
    lda #0
    sta ptr4+2
    sta ptr4+3

    ldq linkerTags
    stq ptr1
    jsr findInTree
    rts
.endproc

.proc freeLinkerTags
    ldq tagsToFind
    jsr freeMemBuf

    ldq linkerTags
    jsr freeLinkerTagsTree

    lda #0
    tax
    tay
    taz
    stq tagsToFind
    stq linkerTags

    rts
.endproc

.proc freeLinkerTagsTree
    jsr isQZero
    bne :+
    rts

:   stq tagTreeNode
    lda #0
    sta tagTreeStackSize
    sta tagTreeStackSize+1

    ; Loop until done
L1: ldq tagTreeNode
    jsr isQZero
    beq L2                  ; Branch if we don't have a current tree node.

    ; We have a current tree node. Push it onto the stack.
    jsr pushTagTreeStack
    ldq tagTreeNode
    stq ptr1
    ldz #TREENODE::left
    neg
    neg
    nop
    lda (ptr1),z
    stq tagTreeNode
    bra L1

    ; Current tree node is null.
L2: lda tagTreeStackSize
    ora tagTreeStackSize+1
    bne L3                  ; Branch if the stack is not empty.
    rts

L3: jsr popTagTreeStack
    ldq tagTreeNode
    stq ptr1
    ldz #TREENODE::right
    neg
    neg
    nop
    lda (ptr1),z
    stq tagTreeNode
    jsr isQZero
    beq L1

    jsr heapFree
    jmp L1
.endproc

.proc pushTagTreeStack
    ldq tagTreeNode
    jsr rtPushQ
    lda tagTreeStackSize
    clc
    adc #1
    sta tagTreeStackSize
    lda tagTreeStackSize+1
    adc #0
    sta tagTreeStackSize+1
    rts
.endproc

.proc popTagTreeStack
    jsr rtPopQ
    stq tagTreeNode
    lda tagTreeStackSize
    sec
    sbc #1
    sta tagTreeStackSize
    lda tagTreeStackSize+1
    sbc #0
    sta tagTreeStackSize+1
    rts
.endproc

.proc getLinkerTagsToFind
    ldq tagsToFind
    rts
.endproc

.proc initLinkerTags
    lda #0
    tax
    tay
    taz
    stq linkerTags

    jsr allocMemBuf
    stq tagsToFind

    rts
.endproc

; This routine adds a label to be resolved at link time.
; Inputs:
;    A/X: pointer to null-terminated label
;    Y: one of LINKADDR_LOW, LINKADDR_HIGH, or LINKADDR_BOTH
;    Z: offset from codeOffset where result is to be stored
.proc linkAddressLookup
    sta ptr1
    stx ptr1+1
    stz intOp2
    lda #0
    sta intOp2+1

    lda codeOffset
    sta intOp1
    lda codeOffset+1
    sta intOp1+1

    ; Zero out the linkerTag structure
    lda #0
    tax
:   sta linkerTag,x
    inx
    cpx #.sizeof(TAGTOFIND)
    bne :-

    ldx #TAGTOFIND::type
    tya
    sta linkerTag,x

    ; Copy the tag to the structure
    ldy #0
    ldx #0
:   lda (ptr1),y
    beq :+
    sta linkerTag,x
    inx
    iny
    bne :-

:   jsr addInt16
    ldx #TAGTOFIND::offset
    lda intOp1
    sta linkerTag,x
    inx
    lda intOp1+1
    sta linkerTag,x

    ; Write the linker tag to the membuf
    ldq tagsToFind
    stq ptr1
    lda #<linkerTag
    sta ptr2
    lda #>linkerTag
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #.sizeof(TAGTOFIND)
    ldx #0
    jsr writeToMemBuf

    rts
.endproc

; This routine adds a linker tag to the binary tree.
; A/X contains the pointer to the null-terminated tag string.
; codeOffset is used as the location for the tag.
.proc linkAddressSet
    sta ptr2
    stx ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ; Add codeOffset and codeBase and store in ptr3
    lda codeOffset
    clc
    adc #.lobyte(codeBase)
    sta ptr3
    lda codeOffset+1
    adc #.hibyte(codeBase)
    sta ptr3+1
    lda #0
    sta ptr3+2
    sta ptr3+3

    ldq linkerTags
    stq ptr1
    jsr addTreeNode

    ldq linkerTags
    jsr isQZero
    bne :+
    ldq ptr4
    stq linkerTags

:   rts
.endproc
