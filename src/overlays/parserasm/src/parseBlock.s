.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "parser.inc"
.include "ast.inc"
.include "error.inc"
.include "tokenizer.inc"

isProgramOrUnitBlockOffset = 9
isLibraryOffset = 8
declOffset = 0
interfaceDeclOffset = 4

.export parseBlock

.import isInUnitInterface, parserToken, getToken, parserError
.import parserString, parseCompound, doResync, tlStatementStart
.import parserModuleType, parseDeclarations, parserError, currentLineNumber

.data

libraryStr: .asciiz "LIBRARY"

.code

; This routine parses a program block. That can be the main program block,
; a unit block, or any block of code.
;
; Inputs: A contains a non-zero if this block is for a program or unit.
; Returns: The Z flag is set if the block was a library.
.proc parseBlock
    pha
    jsr pushA               ; isProgramOrUnitBlock
    lda #0
    jsr pushA               ; isLibrary
    jsr pushQZero           ; interfaceDecl
    pla
    jsr parseDeclarations   ; decl
    jsr pushQ

    ldz #isProgramOrUnitBlockOffset
    nop
    lda (stackPointer),z
    beq L2
    lda isInUnitInterface
    beq L2

    lda parserToken
    cmp #tcIMPLEMENTATION           ; if (parserToken !+ tcIMPLEMENTATION)
    beq :+
    lda #errMissingIMPLEMENTATION
    jsr parserError
:   lda #0
    sta isInUnitInterface
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldx #3
    ldz #interfaceDeclOffset+3      ; interfaceDecl = decl
:   lda ptr1,x
    nop
    sta (stackPointer),z
    dez
    dex
    bpl :-
    jsr getToken
    jsr isLibraryParserString
    bne L1
    jsr getToken
    ldz #isLibraryOffset
    lda #1
    nop
    sta (stackPointer),z
    ldz #declOffset+3
    ldx #3
    lda #0
:   nop
    sta (stackPointer),z
    dez
    dex
    bpl :-
    bra L2
L1: lda #1
    jsr parseDeclarations
    stq ptr1
    ldx #3
    ldz #declOffset+3
:   lda ptr1,x
    nop
    sta (stackPointer),z
    dez
    dex
    bpl :-
L2: lda #0
    tax
    tay
    taz
    stq ptr1
    ldz #isLibraryOffset
    nop
    lda (stackPointer),z
    bne L3
    lda parserModuleType
    cmp #TYPE_UNIT              ; if (parserModuleType == TYPE_UNIT)
    bne :+
    lda parserToken
    cmp #tcEND                  ; if (parserToken == tcEND)
    bne :+
    lda #0
    tax
    tay
    taz
    stq ptr1                    ; body = null
    bra L3
:   resync tlStatementStart
    lda parserToken
    cmp #tcBEGIN                ; if (parserToken != tcBEGIN)
    beq :+
    lda #errMissingBEGIN
    jsr parserError
:   jsr parseCompound
    stq ptr1
L3: lda #STMT_BLOCK
    jsr pushA                   ; kind
    jsr pushQZero               ; expr
    ldq ptr1
    jsr pushQ                   ; body
    lda currentLineNumber
    ldx currentLineNumber+1
    jsr pushAX                  ; lineNumber
    jsr stmtCreate
    stq ptr1
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldx #3
    ldz #stmt::decl+3
:   lda ptr2,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    ldz #interfaceDeclOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldx #3
    ldz #stmt::interfaceDecl+3
:   lda ptr2,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    jsr popQ
    jsr popQ
    jsr popA
    jsr popA
    ldq ptr1
    rts
.endproc

; This routine compares parserString to "library"
.proc isLibraryParserString
    ldx #0
:   lda parserString,x
    beq L1
    cmp libraryStr,x
    bne L2
    inx
    bne :-
L1: cmp libraryStr,x
L2: rts
.endproc
