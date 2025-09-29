.include "tokenizer.inc"
.include "parser.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "asmlib.inc"
.include "zeropage.inc"

.export showTree, printz, printzLong, printStructAddr, printStructName
.export printStructBool, printStructNumber, loadPtr

.import initTokenizer, initParser, showAddr, showDecl

.bss

tokenHeap: .res 4
astRoot: .res 4
unitList: .res 4
intBuf: .res 10

.data

sourceFn: .asciiz "source.pas"
rootMsg: .asciiz "Tree root: "
nullMsg: .asciiz "(null)"
nameStr: .asciiz "name: "
trueMsg: .asciiz "true"
falseMsg: .asciiz "false"

.code

; This routine is the main loop for the tree viewer.
; It starts by showing the root declaration node.
.proc showTree
    lda #0
    tax
    tay
    taz
    stq unitList

    jsr initTokenizer
    lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    stq tokenHeap

    jsr initParser
    ldq unitList
    jsr setUnitsList
    ldq tokenHeap
    jsr parse
    stq astRoot

    lda #$93
    jsr CHROUT              ; Clear the screen
    lda #<rootMsg
    ldx #>rootMsg
    jsr printz
    ldq astRoot
    jsr showAddr
    lda #13
    jsr CHROUT
    ldq astRoot
    jsr showDecl

    ldq tokenHeap
    jsr heapFree
    rts
.endproc

.proc printz
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   rts
.endproc

.proc printzLong
    stq ptr1
    jsr isQZero
    bne :+
    lda #<nullMsg
    sta ptr1
    lda #>nullMsg
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
:   ldz #0
:   nop
    lda (ptr1),z
    beq :+
    jsr CHROUT
    inz
    bne :-
:   rts
.endproc

; Prints an address from a structure
; A - low byte of label
; X - high byte of label
; Z - offset in structure in ptr2
.proc printStructAddr
    phz
    jsr printz
    plz
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    lda #13
    jsr CHROUT
    rts
.endproc

; Prints a string from a struct
; A - low byte of label
; X - high byte of label
; Z - offset in structure in ptr2
.proc printStructName
    phz
    jsr printz
    plz
    neg
    neg
    nop
    lda (ptr2),z
    jsr printzLong
    lda #13
    jsr CHROUT
    rts
.endproc

; Prints a boolean from a struct
; A - low byte of label
; X - high byte of label
; Z - offset in structure in ptr2
.proc printStructBool
    phz
    jsr printz
    plz
    nop
    lda (ptr2),z
    beq L1
    lda #<trueMsg
    ldx #>trueMsg
    jsr printz
    bra L2
L1: lda #<falseMsg
    ldx #>falseMsg
    jsr printz
L2: lda #13
    jsr CHROUT
    rts
.endproc

; Prints the line number from the structure in ptr2
; Z - offset in structure
.proc printStructNumber
    nop
    lda (ptr2),z
    sta intOp1
    inz
    nop
    lda (ptr2),z
    sta intOp1+1
    ldq ptr2
    jsr pushQ
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    jsr popQ
    stq ptr2
    lda #<intBuf
    ldx #>intBuf
    jsr printz
    lda #13
    jsr CHROUT
    rts
.endproc

; This routine loads a pointer from the structure pointed at by ptr2.
; The offset in the structure is passed in Z.
; On exit, the Z flag is set if the pointer is null.
.proc loadPtr
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    rts
.endproc
