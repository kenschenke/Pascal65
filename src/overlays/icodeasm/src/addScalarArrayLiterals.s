.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

elemSizeOffset = 0
firstExprOffset = elemSizeOffset + 2
declBufOffset = firstExprOffset + 4

.export addScalarArrayLiterals

.import loadStackValue, icodeSaveData

.bss

scalarMemBuf: .res 4        ; Membuf for the literals
numLiterals: .res 2         ; Number of literals written
exprPtr: .res 4             ; Current literal expression in chain
labelBuf: .res 15
dummy: .res 4

.data

strLabel: .asciiz "scalar"

.code

; Passed on the stack, bottom to top:
;    Pointer to first literal expression (never NULL)
;    Pointer to array declaration block membuf
;    Size of each element (2 bytes)
.proc addScalarArrayLiterals
    ; Allocate a membuf to hold the literals
    jsr allocMemBuf
    stq scalarMemBuf

    ; Zero out numLiterals
    lda #0
    sta numLiterals
    sta numLiterals+1

    ; Start with the first expression
    ldz #firstExprOffset
    jsr loadStackValue

    ; Loop through the literal expressions
L1: stq exprPtr
    stq ptr2

    ; Write the literal to scalarMemBuf
    ldq scalarMemBuf
    stq ptr1
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr2),z
    stq intOp32
    ldz #expr::neg
    nop
    lda (ptr2),z
    beq :+
    jsr invertInt32
:   ldq intOp32
    stq dummy
    lda #<dummy
    sta ptr2
    lda #>dummy
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldz #elemSizeOffset+1
    nop
    lda (stackPointer),z
    tax
    dez
    nop
    lda (stackPointer),z
    jsr writeToMemBuf

    ; Increment numLiterals
    lda numLiterals
    clc
    adc #1
    sta numLiterals
    lda numLiterals+1
    adc #0
    sta numLiterals+1

    ; Move to the next expression in the chain
    ldq exprPtr
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L1

    ; Done looping through the literal expressions.
    ; Create a label for the literals.
    jsr formatStringLabel

    ; Add a DAT segment for the literals.
    lda #ARRAYDECL_SCALAR
    jsr pushA
    ldq scalarMemBuf
    jsr pushQ
    lda #<labelBuf
    ldx #>labelBuf
    ldy #0
    ldz #0
    jsr pushQ
    jsr icodeSaveData

    ; Write an empty label for the element declaration block
    lda #0
    sta dummy
    ldz #declBufOffset
    jsr loadStackValue
    stq ptr1
    lda #<dummy
    sta ptr2
    lda #>dummy
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf

    ; Write the label for the literals
    ldz #declBufOffset
    jsr loadStackValue
    stq ptr1
    lda #<labelBuf
    sta ptr2
    lda #>labelBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ; Count the length of the labelBuf
    ldx #0
:   lda labelBuf,x
    beq :+
    inx
    bne :-
:   inx
    txa
    ldx #0
    jsr writeToMemBuf

    ; Write the number of literals
    ldz #declBufOffset
    jsr loadStackValue
    stq ptr1
    lda #<numLiterals
    sta ptr2
    lda #>numLiterals
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #2
    ldx #0
    jsr writeToMemBuf

    jsr popAX
    jsr popQ
    jsr popQ

    rts
.endproc

.proc formatStringLabel
    ldx #0
:   lda strLabel,x
    beq :+
    sta labelBuf,x
    inx
    bne :-
:   stx intOp2
    lda #0
    sta intOp2+1
    lda #<labelBuf
    sta intOp1
    lda #>labelBuf
    sta intOp1+1
    jsr addInt16
    ldq scalarMemBuf
    stq intOp32
    lda intOp1
    ldx intOp1+1
    jsr hexstr
    rts
.endproc
