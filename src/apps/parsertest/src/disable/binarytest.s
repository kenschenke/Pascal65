.include "tree.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

NUM_WORDS = 7

.export binaryTest

.import heapWalk

.data

; Sort order: after, before, isabel, later, laugh, middle, yellow

; Tree:
;                       middle
;                      /      \
;                  before     yellow
;                   /    \
;                after   later
;                        /    \
;                     isabel  laugh

; Words to add
strWord1: .asciiz "middle"
strWord2: .asciiz "before"
strWord3: .asciiz "later"
strWord4: .asciiz "yellow"
strWord5: .asciiz "after"
strWord6: .asciiz "laugh"
strWord7: .asciiz "isabel"

; Word is not added to tree
strWord8: .asciiz "blue"

words: .byte .LOBYTE(strWord1), .HIBYTE(strWord1)
       .byte .LOBYTE(strWord2), .HIBYTE(strWord2)
       .byte .LOBYTE(strWord3), .HIBYTE(strWord3)
       .byte .LOBYTE(strWord4), .HIBYTE(strWord4)
       .byte .LOBYTE(strWord5), .HIBYTE(strWord5)
       .byte .LOBYTE(strWord6), .HIBYTE(strWord6)
       .byte .LOBYTE(strWord7), .HIBYTE(strWord7)

strFind1: .asciiz "Finding after: "
strFind2: .asciiz "Find blue: "
strWordMissing: .asciiz "after is missing"
strUnexpectedWord: .asciiz "was not expecting to find blue"
strMissing: .asciiz "missing"
strFreeing: .asciiz "Freeing "

.bss

treeRoot: .res 4
wordNum: .res 1

.code

.proc binaryTest
    lda #0
    tax
    tay
    taz
    stq treeRoot
    sta wordNum

    jsr heapWalk

L1: lda wordNum
    cmp #NUM_WORDS
    beq L2

    asl a               ; Multiply wordNum by two
    tax
    lda words,x
    sta ptr2
    lda words+1,x
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    
    ldq treeRoot
    stq ptr1
    
    ; Pass the word as data
    ldq ptr2
    stq ptr3

    jsr addTreeNode
    ldq treeRoot
    jsr isQZero
    bne :+
    ldq ptr4
    stq treeRoot
:   inc wordNum
    bra L1

    ; Walk the tree
L2: ldq treeRoot
    stq ptr1

    jsr walkTree

    ; Look for a couple tree nodes
    lda #13
    jsr CHROUT

    jsr lookForExistingWord
    jsr lookForMissingWord
    jsr testFree
    jsr heapWalk
    rts
.endproc

.proc testFree
    ldq treeRoot
    stq ptr1
    lda #<freeNode
    sta ptr2
    lda #>freeNode
    sta ptr2+1
    jsr freeTree
    rts
.endproc

.proc freeNode
    stq ptr1
    ldx #0
:   lda strFreeing,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   ldz #0
:   nop
    lda (ptr1),z
    beq :+
    jsr CHROUT
    inz
    bne :-

:   lda #13
    jsr CHROUT
    rts
.endproc

.proc lookForExistingWord
    ; Look for a tree node that's present
    ldx #0
:   lda strFind1,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   ldq treeRoot
    stq ptr1
    lda #<strWord5
    sta ptr4
    lda #>strWord5
    sta ptr4+1
    lda #0
    sta ptr4+2
    sta ptr4+3
    jsr findInTree
    jsr isQZero
    bne :+
    jsr showWordMissing
    bra L1

:   stq ptr1
    jsr showWord

L1: lda #13
    jsr CHROUT
    rts
.endproc

.proc lookForMissingWord
    ; Look for a tree node that's not present
    ldx #0
:   lda strFind2,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   ldq treeRoot
    stq ptr1
    lda #<strWord8
    sta ptr4
    lda #>strWord8
    sta ptr4+1
    lda #0
    sta ptr4+2
    sta ptr4+3
    jsr findInTree
    jsr isQZero
    beq :+
    jsr showUnexpectedWord
    bra L1

:   stq ptr1
    jsr showMissingStr

L1: lda #13
    jsr CHROUT
    rts
.endproc

.proc walkTree
    ldq ptr1
    jsr isQZero
    beq L1

    jsr pushQ
    
    ; Left
    ldz #TREENODE::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr walkTree
    
    jsr popQ
    stq ptr1

    ; Print this node
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    jsr CHROUT
    inz
    bne :-
:   lda #13
    jsr CHROUT

    ; Right
    ldz #TREENODE::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr walkTree

L1: rts
.endproc

.proc showWordMissing
    ldx #0
:   lda strWordMissing,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc

.proc showUnexpectedWord
    ldx #0
:   lda strUnexpectedWord,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc

.proc showMissingStr
    ldx #0
:   lda strMissing,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc

.proc showWord
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    jsr CHROUT
    inz
    bne :-
:   rts
.endproc
