.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

isRealOffset = 0
firstExprOffset = isRealOffset + 1
declBufOffset = firstExprOffset + 4

.export addStringArrayLiterals

.import loadStackValue, icodeSaveData

.bss

strMemBuf: .res 4           ; Membuf for the string literals
numLiterals: .res 2         ; Number of string literals written
exprPtr: .res 4             ; Current literal expression in chain
labelBuf: .res 15
dummy: .res 1

.data

strLabel: .asciiz "strbuf"

.code

; Passed on the stack, bottom to top:
;    Pointer to first string literal expression (never NULL)
;    Pointer to array declaration block membuf
;    A 1 if the literals are real numbers
.proc addStringArrayLiterals
    ; Allocate a membuf to hold the string literals
    jsr allocMemBuf
    stq strMemBuf

    ; Zero out numLiterals
    lda #0
    sta numLiterals
    sta numLiterals+1

    ; Start with the first expression
    ldz #firstExprOffset
    jsr loadStackValue

    ; Loop through the string literal expressions
L1: stq exprPtr
    stq ptr2

    ; Are these real number literals?
    ldz #isRealOffset
    nop
    lda (stackPointer),z
    beq L2                  ; branch if not

    ; Is this a negative real number?
    ldz #expr::neg
    nop
    lda (ptr2),z
    beq L2                  ; branch if not

    ; Write a negative sign to the membuf
    ldq strMemBuf
    stq ptr1
    lda #'-'
    sta dummy
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
    ldq exprPtr
    stq ptr2

    ; Write the string literal to strMemBuf
L2: ldq strMemBuf
    stq ptr1
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ; Count the length of the string
    ldz #0
:   nop
    lda (ptr2),z
    beq :+
    inz
    bne :-
:   inz
    tza
    ldx #0
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
    beq :+
    jmp L1

    ; Done looping through the string literal expressions.
    ; Create a label for the string literals.
:   jsr formatStringLabel

    ; Add a DAT segment for the literals.
    ldz #isRealOffset
    nop
    lda (stackPointer),z
    beq :+
    lda #ARRAYDECL_REAL
    bra L3
:   lda #ARRAYDECL_STRING
L3: jsr pushA
    ldq strMemBuf
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

    ; Write the label for the string literals
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

    jsr popA
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
    ldq strMemBuf
    stq intOp32
    lda intOp1
    ldx intOp1+1
    jsr hexstr
    rts
.endproc
