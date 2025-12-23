;
; binaryTree.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines to add to and search binary trees

.include "tree.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

TREESTACK_SIZE = 1

.export addTreeNode, freeTree, findInTree

.import loadPtr, isQZero, heapAlloc, heapFree, rtPopQ, rtPushQ
.import runtimeError

.bss

freeData: .res 2
freeNode: .res 4
treeStack: .res TREESTACK_SIZE * 4
treeStackTop: .res 1
treeStackItems: .res 1

.code

; Stores a new node in a binary tree.
; Inputs:
;    Tree root in ptr1
;    Name in ptr2 (must be null-terminated and 23 chars or less)
;    Data in ptr3
;
; The new node is returned in ptr4. If the tree root is null,
; the caller needs to copy ptr4 to become the new tree root.
;
; Note: ptr1 is modified.
.proc addTreeNode
    ; Save ptr1, ptr2, and ptr3
    ldq ptr1
    jsr rtPushQ
    ldq ptr2
    jsr rtPushQ
    ldq ptr3
    jsr rtPushQ

    ; Allocate a new tree node
    lda #.sizeof(TREENODE)
    ldx #0
    jsr heapAlloc
    stq ptr4

    ; Zero out the new node
    lda #0
    ldz #0
:   nop
    sta (ptr4),z
    inz
    cpz #.sizeof(TREENODE)
    bne :-

    ; Restore ptr1, ptr2, and ptr3
    jsr rtPopQ
    stq ptr3
    jsr rtPopQ
    stq ptr2
    jsr rtPopQ
    stq ptr1

    ; Copy the name of the node
    ldz #0
:   nop
    lda (ptr2),z
    beq :+
    nop
    sta (ptr4),z
    inz
    bne :-

    ; Copy the data pointer
:   ldx #0
    ldz #TREENODE::data
:   lda ptr3,x
    nop
    sta (ptr4),z
    inx
    inz
    cpx #4
    bne :-

    ; Is ptr1 null?
    ldq ptr1
    jsr isQZero
    bne :+
    rts

:   jmp saveInTree
.endproc

; This routine is called by addTreeNode.
; Inputs:
;    ptr1 tree root
;    ptr4 new node to add
;
; Note: This routine assumes the tree is not empty.
;       There is no need to call this routine on an
;       empty tree since the first node is the root.
;
; Note: ptr1 is modified
.proc saveInTree
L1: ldq ptr1
    jsr isQZero
    beq L5

    ldq ptr1            ; Set ptr2 to the last node
    stq ptr2

    lda #0
    sta tmp1

    jsr compareKeys
    bmi L2
    bne L3

    ; ptr1 < ptr4
L2: ldz #TREENODE::right
    bra L4

    ; ptr1 > ptr4
L3: ldz #TREENODE::left
    lda #1
    sta tmp1

L4: neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L5: lda tmp1
    bne L6          ; Branch if appending to the left side of the tree
    ldz #TREENODE::right
    bra L7

L6: ldz #TREENODE::left

L7: ldx #0
:   lda ptr4,x
    nop
    sta (ptr2),z
    inx
    inz
    cpx #4
    bne :-

    rts
.endproc

; This routine compares the keys for two nodes
; and sets CPU flags to indicate sort order.
; If the N flag is set, the key in ptr1 < ptr4.
; If the Z flag is set, key in ptr1 == ptr4.
; If the Z flag is cleared, the key in ptr1 > ptr4.
.proc compareKeys
    ldz #0
L1: nop
    lda (ptr1),z
    beq L2
    nop
    cmp (ptr4),z
    bne L3
    inz
    bne L1
L2: nop
    lda (ptr4),z
    beq L3
    lda #$80            ; Set the N flag
L3: rts
.endproc

; This routine frees a tree 
; Inputs:
;    ptr1 is the tree root
;    ptr2 is a 16-bit pointer to the caller's data free routine
.proc freeTree
    ldq ptr1
    stq freeNode

    lda ptr2
    sta freeData
    lda ptr2+1
    sta freeData+1

    lda #0
    sta treeStackTop
    sta treeStackItems

    ; Look if the current node is null
L1: ldq freeNode
    jsr isQZero
    beq L2              ; Branch if null

    ; Current node is non-null
    ldq freeNode
    stq ptr1
    jsr pushTreeStack
    ldz #TREENODE::left
    jsr loadPtr
    stq freeNode
    bra L1

    ; Current node is null
L2: lda treeStackTop
    beq L4              ; Branch if the stack is empty
    jsr popTreeStack
    stq ptr1
    jsr rtPushQ
    ldz #TREENODE::data
    jsr loadPtr
    jsr isQZero
    beq L3
    stq ptr2
    lda freeData
    ora freeData+1
    beq L3
    lda #<L3
    sec
    sbc #1
    sta tmp1
    lda #>L3
    sbc #0
    pha
    lda tmp1
    pha
    ldq ptr2
    jmp (freeData)
L3: jsr rtPopQ
    stq ptr1
    jsr rtPushQ
    ldq ptr1
    jsr heapFree
    jsr rtPopQ
    stq ptr1
    ldz #TREENODE::right
    jsr loadPtr
    stq freeNode
    jmp L1

L4: rts
.endproc

; Push the node address in Q onto the tree stack
.proc pushTreeStack
    stq ptr2
    lda treeStackItems
    cmp #TREESTACK_SIZE
    bne :+
    lda #rteStackOverflow
    jsr runtimeError

:   ldy treeStackTop
    ldx #0
:   lda ptr2,x
    sta treeStack,y
    inx
    iny
    cpx #4
    bne :-
    sty treeStackTop
    inc treeStackItems
    rts
.endproc

; Pop a node address from the stack and return it in Q
.proc popTreeStack
    ldx #3
    ldy treeStackTop
:   dey
    lda treeStack,y
    sta ptr2,x
    dex
    bpl :-
    sty treeStackTop
    dec treeStackItems
    ldq ptr2
    rts
.endproc

; Finds a node in the tree. If present, the node's data
; is returned in Q.
;
; Inputs:
;    ptr1 - tree root
;    ptr4 - key
.proc findInTree
L1: ldq ptr1
    jsr isQZero
    beq L5

    jsr compareKeys
    bmi L2              ; tree node < key
    beq L4              ; tree node = key

    ; key < tree node - go left
    ldz #TREENODE::left
    bra L3

    ; key > tree node - go right
L2: ldz #TREENODE::right

L3: jsr loadPtr
    stq ptr1
    bra L1

L4: ldz #TREENODE::data
    jsr loadPtr
L5: rts
.endproc
