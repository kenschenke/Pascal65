;;;
 ; getNextTokenFromIode.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Intermediate Code Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "error.inc"
.include "misc.inc"
.include "symtab.inc"
.include "scanner.inc"

.export _getNextTokenFromIcode

.import extractSymtabNode, _readFromMemBuf, _retrieveChunk
.import _currentLineNumber, _mcLineMarker, _symbolStrings, _getChunk
.import popax, pushax
.importzp ptr1, ptr2, ptr3

.bss

code: .res 1
hdrChunkNum: .res 2
nodeChunkNum: .res 2
pNodeChunkNum: .res 2
pToken: .res 2
pString: .res 2
symtabNode: .res .sizeof(SYMBNODE)

.code

; void getNextTokenFromIcode(CHUNKNUM hdrChunkNum, TOKEN *pToken, CHUNKNUM *pNodeChunkNum)
.proc _getNextTokenFromIcode
    ; Save the third parameter
    sta pNodeChunkNum
    stx pNodeChunkNum + 1
    ; Save the second parameter
    jsr popax
    sta pToken
    stx pToken + 1
    ; Save the first parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; Loop to process any line markers and extract the next token code.

@LookForLineMarker:
    ; Read the first token
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda #<code
    ldx #>code
    jsr pushax
    lda #1
    ldx #0
    jsr _readFromMemBuf
    lda code
    cmp _mcLineMarker
    bne @LookAtTokenCode
    ; Extract the line number
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda #<_currentLineNumber
    ldx #>_currentLineNumber
    jsr pushax
    lda #2
    ldx #0
    jsr _readFromMemBuf
    jmp @LookForLineMarker

@LookAtTokenCode:
    ; Look for tcNumber, tcIdentifier, or tcString (symbol table node)
    lda code
    cmp #tcNumber
    beq @HasSymbolTableNode
    cmp #tcIdentifier
    beq @HasSymbolTableNode
    cmp #tcString
    bne @HasSpecialToken

@HasSymbolTableNode:
    ; Extract a symbol table node

    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    lda #<nodeChunkNum
    ldx #>nodeChunkNum
    jsr extractSymtabNode

    ; Clear the string

    lda pToken
    sta ptr1
    lda pToken + 1
    sta ptr1 + 1
    ; Add the structure offset for pToken->string
    clc
    lda ptr1
    adc #4
    sta ptr1
    sta pString
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    sta pString + 1
    ; Loop to clear the string buffer
    ldy #TOKEN_STRING_LEN
    dey
    lda #0
@ClrLoop:
    sta (ptr1),y
    dey
    bpl @ClrLoop

    ; Get a pointer to the symbol table node
    lda nodeChunkNum
    ldx nodeChunkNum + 1
    jsr _getChunk
    sta ptr1            ; Store the chunk pointer
    stx ptr1 + 1

    ; Retrieve the token name from the symbol table
    ldy #SYMTABNODE::nameChunkNum
    lda (ptr1),y
    iny
    lda (ptr1),y
    tax
    jsr pushax
    lda pString
    ldx pString + 1
    jsr _retrieveChunk

    ; See if the caller provided a pointer to a chunknum
    lda pNodeChunkNum
    ora pNodeChunkNum + 1
    beq @Done
    lda pNodeChunkNum
    sta ptr1
    lda pNodeChunkNum + 1
    sta ptr1 + 1
    ldy #0
    lda nodeChunkNum
    sta (ptr1),y
    iny
    lda nodeChunkNum + 1
    sta (ptr1),y

    jmp @Done

@HasSpecialToken:
    ; Copy the string for this token into the token's string buffer

    ; ptr1 is the token's string buffer (the destination)
    lda pToken
    sta ptr1
    lda pToken + 1
    sta ptr1 + 1
    ; offset to the string buffer portion of the token
    clc
    lda ptr1
    adc #4
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1

    ; ptr2 is the symbol string (the source of the copy)
    lda code
    adc code
    tay
    lda _symbolStrings,y
    sta ptr2
    iny
    lda _symbolStrings,y
    sta ptr2 + 1

    ; Copy the string, including the null terminator
    ldy #0
@TokenLoop:
    lda (ptr2),y
    sta (ptr1),y
    beq @Done
    iny
    jmp @TokenLoop

@Done:
    ; Store the token code in the pToken buffer
    lda pToken
    sta ptr1
    lda pToken + 1
    sta ptr1 + 1
    lda code
    ldy #0
    sta (ptr1),y
    rts

.endproc
