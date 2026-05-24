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
.endproc

.proc freeTagsTree
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    jsr pushQ
    ldz #TREENODE::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr freeTagsTree

    jsr popQ
    stq ptr1
    jsr pushQ
    ldz #TREENODE::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr freeTagsTree

    jsr popQ
    stq ptr1
    jsr pushQ
    ldz #TREENODE::data
    neg
    neg
    nop
    lda (ptr1),z
    jsr heapFree

    jsr popQ
    jsr heapFree

    rts
.endproc

.proc walkTagsTree
    jsr isQZero
    bne :+
    rts

    ; Left child first
:   stq ptr1
    jsr pushQ
    ldz #TREENODE::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr walkTagsTree

    ; Add the tag for the current node
    jsr popQ
    stq ptr1
    jsr pushQ
    ldz #TREENODE::data
    neg
    neg
    nop
    lda (ptr1),z
    jsr addTagToFind

    ; Finally, the right child
    jsr popQ
    stq ptr1
    ldz #TREENODE::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr walkTagsTree
    
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

    ; Format the offset as a string
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
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

    ; Add the TAGTOFIX structure to the binary tree
L5: ldq tagsTree
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
    bne :+
    ldq ptr4
    stq tagsTree
:   jmp L1

DN: rts
.endproc
