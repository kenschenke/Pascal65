.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "tokenizer.inc"

.export getToken, condGetToken

.import parserIcode, parserToken, parserString, parserType, parserValue, currentLineNumber
.import parserError

.bss

tokenCode: .res 1
strlength: .res 1

.code

.proc getToken
    ldq parserIcode
    jsr isMemBufAtEnd
    bne :+
    rts

:   lda #<tokenCode
    ldx #>tokenCode
    ldy #1
    jsr readBytes
    lda tokenCode
    cmp #tzLineNum
    bne L2
    lda #<currentLineNumber
    ldx #>currentLineNumber
    ldy #2
    jsr readBytes
    jmp getToken

L2: cmp #tzIdentifier
    bne L3
    lda #tcIdentifier
    jmp readString

L3: cmp #tzString
    bne L4
    lda #tcString
    jmp readString

L4: cmp #tzByte
    bne L5
    lda #1
    ldx #tyByte
    jmp readNum

L5: cmp #tzWord
    bne L6
    lda #2
    ldx #tyWord
    jmp readNum

L6: cmp #tzCardinal
    bne L7
    lda #4
    ldx #tyCardinal
    jmp readNum

L7: cmp #tzReal
    bne L8
    lda #tyReal
    sta parserType
    lda #tcNumber
    sta parserToken
    jmp readString
L8: ; Assume tzToken
    lda #<parserToken
    ldx #>parserToken
    ldy #1
    jmp readBytes
.endproc

; Length in A
; Type in X
.proc readNum
    stx parserType
    pha
    lda #0
    ldx #3
:   sta parserValue,x
    dex
    bpl :-
    ply
    lda #<parserValue
    ldx #>parserValue
    jsr readBytes
    lda #tcNumber
    sta parserToken
    jmp readString
.endproc

; Reads bytes from the intermediate code membuf
; Caller's buffer is in A/X
; Y contains number of bytes to read
.proc readBytes
    sta ptr2
    stx ptr2+1
    phy
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldq parserIcode
    stq ptr1
    pla
    ldx #0
    jmp readFromMemBuf
.endproc

.proc readString
    sta parserToken
    lda #<strlength
    ldx #>strlength
    ldy #1
    jsr readBytes
    lda #<parserString
    ldx #>parserString
    ldy strlength
    jsr readBytes
    ldx strlength
    lda #0
    sta parserString,x
    rts
.endproc

; This routine conditionally retrieves the next token, but only if the
; current token matches the one in A. If not, the error in X is thrown.
;
; Inputs: A - required value of current token
;         X - error number if current token did not match A
.proc condGetToken
    cmp parserToken
    bne :+
    jmp getToken
:   txa
    jmp parserError
.endproc
