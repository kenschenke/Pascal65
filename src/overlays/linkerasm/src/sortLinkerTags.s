;
; sortLinkerTags.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; sortLinkerTags routine

.include "tree.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export sortLinkerTags

.bss

tagsToFind: .res 4
tagToFind: .res .sizeof(TAGTOFIND)
tagToFix: .res 4
tagsTree: .res 4
tagsMemBuf: .res 4
intBuf: .res 15
key: .res 15
lastKey: .res 15
lastNode: .res 4
walkTreeNode: .res 4
walkTreeStackSize: .res 2

.code

; This routine sorts the list of tags to fix in the object file by offset.
; It does this by reading through the list of tags to fix and puts them into a
; binary tree, ordered by offset. It then walks the binary tree and writes the
; TAGTOFIND structures to a memory buffer.
;
; The memory buffer is returned in Q.
.proc sortLinkerTags
    jsr buildTagsTree
    jsr buildTagsMemBuf

    ldq tagsTree
    jsr freeTagsTree

    ldq tagsMemBuf
    rts
.endproc

.proc buildTagsMemBuf
    jsr allocMemBuf
    stq tagsMemBuf

    ; Walk the tagsTree
    ldq tagsTree
    jsr walkTagsTree

    rts
.endproc

.proc freeTagsTree
    jsr isQZero
    bne :+
    rts

:   stq walkTreeNode
    lda #0
    sta walkTreeStackSize
    sta walkTreeStackSize+1

    ; Loop until done
L1: ldq walkTreeNode
    jsr isQZero
    beq L2                      ; Branch if we don't have a current tree node.

    ; We have a current tree node. Push it onto the stack.
    jsr pushWalkStack
    ldq walkTreeNode
    stq ptr1
    ldz #TREENODE::left
    neg
    neg
    nop
    lda (ptr1),z
    stq walkTreeNode
    bra L1

    ; Current tree node is null. 
L2: lda walkTreeStackSize
    ora walkTreeStackSize+1
    bne L3                          ; Branch if the stack is not empty.
    rts

L3: jsr popWalkStack
    ldq walkTreeNode
    stq ptr1
    ldz #TREENODE::right
    neg
    neg
    nop
    lda (ptr1),z
    stq walkTreeNode

    ldq ptr1
    jsr pushQ

    ldz #TREENODE::data
    neg
    neg
    nop
    lda (ptr1),z
    jsr heapFree

    jsr popQ
    jsr heapFree

    jmp L1
.endproc

.proc walkTagsTree
    jsr isQZero
    bne :+
    rts

:   stq walkTreeNode
    lda #0
    sta walkTreeStackSize
    sta walkTreeStackSize+1

    ; Loop until done
L1: ldq walkTreeNode
    jsr isQZero
    beq L2                      ; Branch if we don't have a current tree node.

    ; We have a current tree node. Push it onto the stack.
    jsr pushWalkStack
    ldq walkTreeNode
    stq ptr1
    ldz #TREENODE::left
    neg
    neg
    nop
    lda (ptr1),z
    stq walkTreeNode
    bra L1

    ; Current tree node is null. 
L2: lda walkTreeStackSize
    ora walkTreeStackSize+1
    bne L3                          ; Branch if the stack is not empty.
    rts

L3: jsr popWalkStack
    ldq walkTreeNode
    stq ptr1
    ldz #TREENODE::right
    neg
    neg
    nop
    lda (ptr1),z
    stq walkTreeNode

    ldz #TREENODE::data
    neg
    neg
    nop
    lda (ptr1),z
    jsr addTagToFind

    jmp L1
.endproc

.proc pushWalkStack
    ldq walkTreeNode
    jsr pushQ
    lda walkTreeStackSize
    clc
    adc #1
    sta walkTreeStackSize
    lda walkTreeStackSize+1
    adc #0
    sta walkTreeStackSize+1
    rts
.endproc

.proc popWalkStack
    jsr popQ
    stq walkTreeNode
    lda walkTreeStackSize
    sec
    sbc #1
    sta walkTreeStackSize
    lda walkTreeStackSize+1
    sbc #0
    sta walkTreeStackSize+1
    rts
.endproc

.proc addTagToFind
    stq ptr2
    ldq tagsMemBuf
    stq ptr1
    lda #.sizeof(TAGTOFIX)
    ldx #0
    jsr writeToMemBuf
    rts
.endproc

.proc buildTagsTree
    lda #0
    tax
    tay
    taz
    stq tagsTree
    stq lastNode

    jsr getLinkerTagsToFind
    stq tagsToFind
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the tags to find
L1: ldq tagsToFind
    jsr isMemBufAtEnd
    bne :+
    jmp DN

    ; Load the TAGTOFIND structure
:   ldq tagsToFind
    stq ptr1
    lda #<tagToFind
    sta ptr2
    lda #>tagToFind
    sta ptr2+1
    ldx #0
    stx ptr2+2
    stx ptr2+3
    lda #.sizeof(TAGTOFIND)
    jsr readFromMemBuf

    ; Allocate memory for a new TAGTOFIX structure
    lda #.sizeof(TAGTOFIX)
    ldx #0
    jsr heapAlloc
    stq tagToFix

    ; Find the tag in the tree
    lda #<tagToFind
    ldx #>tagToFind
    jsr findLinkerTag
    pha
    phx
    ldq tagToFix
    stq ptr1
    pla
    ldz #TAGTOFIX::address+1
    nop
    sta (ptr1),z
    pla
    dez
    nop
    sta (ptr1),z

    ldx #TAGTOFIND::type
    lda tagToFind,x
    ldz #TAGTOFIX::type
    nop
    sta (ptr1),z

    ldx #TAGTOFIND::offset
    lda tagToFind,x
    sta intOp1
    ldz #TAGTOFIX::offset
    nop
    sta (ptr1),z
    inx
    lda tagToFind,x
    sta intOp1+1
    inz
    nop
    sta (ptr1),z

    ; Format the offset as a string. writeInt16 is signed and would turn an
    ; offset over 32767 into a negative number, so use writeInt32.
    lda #0
    sta intOp2
    sta intOp2+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt32
    ; Count the length of the string
    ldx #0
:   lda intBuf,x
    beq :+
    inx
    bne :-
:   stx tmp1
    ; Subtract from five
    lda #5
    sec
    sbc tmp1
    sta tmp1
    ; Pad the key with leading zeros
    lda #'0'
    ldx #0
L2: ldy tmp1
    beq L3
    sta key,x
    inx
    dec tmp1
    bne L2
    ; Copy the offset string
    ; x=offset in key, y=offset in intBuf
L3: ldy #0
L4: lda intBuf,y
    sta key,x
    beq L5
    inx
    iny
    bne L4

    ; Add the TAGTOFIX structure to the binary tree.
    ;
    ; The tags normally arrive in order of offset, so each new key is larger
    ; than the last one added. Walking down from the root every time would
    ; take as long as the tree is deep, so a key that is larger than the last
    ; one is added directly after the last node.
L5: ldq lastNode
    jsr isQZero
    beq Gen                     ; No nodes yet
    ldx #0
CK: lda key,x
    cmp lastKey,x
    bne CD
    cmp #0
    beq Gen                     ; Equal keys
    inx
    bra CK
CD: bcc Gen                     ; Key is smaller than the last one

    ; Larger than the last key. Add it after the last node.
    ldq lastNode
    stq ptr1
    lda #<key
    sta ptr2
    lda #>key
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldq tagToFix
    stq ptr3
    jsr addTreeNode
    ldq ptr4
    stq lastNode
    jmp CopyKey

    ; Add the node starting at the root of the tree
Gen:
    ldq tagsTree
    stq ptr1
    lda #<key
    sta ptr2
    lda #>key
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldq tagToFix
    stq ptr3
    jsr addTreeNode
    ldq tagsTree
    jsr isQZero
    bne L6
    ldq ptr4                    ; This is the first node
    stq tagsTree
    stq lastNode
    bra CopyKey
L6: jmp L1

CopyKey:
    ldx #0
:   lda key,x
    sta lastKey,x
    beq :+
    inx
    bne :-
:   jmp L1

DN: rts
.endproc
