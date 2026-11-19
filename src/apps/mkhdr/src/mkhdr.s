;
; mkhdr.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; makeHeader routine. Parses a library unit and writes its pre-compiled
; header. The records are written by hdrWrite (src/shared/hdr/hdrwrite.s).
; See hdr.inc for the file format.

.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "tokenizer.inc"
.include "parser.inc"
.include "asmlib.inc"
.include "ast.inc"
.include "hdr.inc"
.include "4510macros.inc"

HDR_FILENUM = 2

.export makeHeader

.import initTokenizer, initParser, errorCount
.import hdrWrite, hdrOutVec

.data

dummyUnit: .asciiz "mkhdr"
strPas: .asciiz ".pas"
strHdr: .asciiz ".hdr"
strWriteExt: .asciiz ",p,w"
strParsing: .asciiz "Parsing "
strNotLibrary: .asciiz "Not a library unit."
strTooMany: .asciiz "Too many records."
strTooLong: .asciiz "Name too long."
strInternal: .asciiz "Internal error."
strWrote: .asciiz "Wrote "
strRecords: .asciiz " records to "

.bss

sourceFn: .res 2
tokens: .res 4
astRoot: .res 4
unitList: .res 4
outName: .res 24            ; header filename, null-terminated
openName: .res 32           ; outName plus ",p,w"
openLen: .res 1
resultLo: .res 1            ; hdrWrite's record count or error
resultHi: .res 1

.code

; Parse a library unit and write its header.
; The null-terminated source filename (e.g. "system.pas") is passed in A/X.
.proc makeHeader
    sta sourceFn
    stx sourceFn+1

    lda #<strParsing
    ldx #>strParsing
    jsr printStr
    lda sourceFn
    ldx sourceFn+1
    jsr printStr
    lda #13
    jsr CHROUT

    lda #0
    sta errorCount

    ; Tokenize the source file
    jsr initTokenizer
    lda sourceFn
    ldx sourceFn+1
    jsr tokenize
    stq tokens
    jsr isQZero
    bne :+
    rts

    ; The parser adds the System unit implicitly when the unit list is
    ; empty. Seed the list with a placeholder so a unit is parsed on its own.
:   lda #<dummyUnit
    ldx #>dummyUnit
    jsr unitCreate
    stq unitList

    jsr initParser
    jsr parserInit
    ldq unitList
    jsr setParserUnitsList
    ldq tokens
    jsr parse
    stq astRoot
    ldq tokens
    jsr freeMemBuf

    lda errorCount
    beq :+
    rts

    ; Make sure it's a library unit
:   ldq astRoot
    stq ptr1
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    bne :+
    lda #<strNotLibrary
    ldx #>strNotLibrary
    jmp printError

:   jsr formatOutName

    ; The header's records, in the shared writer (hdrwrite.s)
    jsr openOutput
    lda #<CHROUT
    sta hdrOutVec
    lda #>CHROUT
    sta hdrOutVec+1
    ldq astRoot
    jsr hdrWrite
    sta resultLo
    stx resultHi
    php
    jsr closeOutput
    plp
    bcc OK

    ; The writer's error
    lda resultLo
    cmp #HDR_ERR_TOO_MANY
    bne :+
    lda #<strTooMany
    ldx #>strTooMany
    jmp printError
:   cmp #HDR_ERR_NAME_LONG
    bne :+
    lda #<strTooLong
    ldx #>strTooLong
    jmp printError
:   lda #<strInternal
    ldx #>strInternal
    jmp printError

OK: lda #<strWrote
    ldx #>strWrote
    jsr printStr
    lda resultLo
    ldx resultHi
    jsr printWord
    lda #<strRecords
    ldx #>strRecords
    jsr printStr
    lda #<outName
    ldx #>outName
    jsr printStr
    lda #13
    jmp CHROUT
.endproc

; Build outName ("system.hdr") and openName ("system.hdr,p,w") from the
; source filename. A trailing ".pas" is dropped.
.proc formatOutName
    lda sourceFn
    sta ptr1
    lda sourceFn+1
    sta ptr1+1

    ; tmp1 = length of the source filename
    ldy #0
:   lda (ptr1),y
    beq :+
    iny
    bne :-
:   sty tmp1

    ; Drop a trailing ".pas"
    lda tmp1
    cmp #5
    bcc CopyAll
    sec
    sbc #4
    tay
    ldx #0
:   lda (ptr1),y
    cmp strPas,x
    bne CopyAll
    iny
    inx
    cpx #4
    bne :-
    lda tmp1
    sec
    sbc #4
    sta tmp1
CopyAll:
    ldy #0
:   cpy tmp1
    beq :+
    lda (ptr1),y
    sta outName,y
    iny
    bne :-
:   ldx #0
:   lda strHdr,x
    sta outName,y
    beq :+
    iny
    inx
    bne :-

    ; openName = outName + ",p,w"
:   ldx #0
:   lda outName,x
    beq :+
    sta openName,x
    inx
    bne :-
:   ldy #0
:   lda strWriteExt,y
    sta openName,x
    beq :+
    inx
    iny
    bne :-
:   stx openLen
    rts
.endproc

; Delete any existing header and open a new one for writing
.proc openOutput
    lda #<outName
    sta ptr1
    lda #>outName
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr scratchFile

    ldx DEVNUM
    lda #HDR_FILENUM
    tay
    jsr SETLFS
    ldx #<openName
    ldy #>openName
    lda openLen
    jsr SETNAM
    jsr OPEN
    ldx #HDR_FILENUM
    jmp CHKOUT
.endproc

.proc closeOutput
    jsr CLRCHN
    lda #HDR_FILENUM
    jmp CLOSE
.endproc

; Print the null-terminated string in A/X
.proc printStr
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

; Print the message in A/X followed by a CR
.proc printError
    jsr printStr
    lda #13
    jmp CHROUT
.endproc

; Print the 16-bit number in A/X in decimal
.proc printWord
    sta intOp1
    stx intOp1+1
    lda #<numBuf
    ldx #>numBuf
    jsr writeInt16
    ldx #0
:   lda numBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc

.bss

numBuf: .res 10
