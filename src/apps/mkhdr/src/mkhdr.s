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
; header. See hdr.inc for the file format.

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
.import hdrRecSize, hdrFieldFirst, hdrFieldNext, hdrTbl, hdrEntryPtr

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
candAddr: .res 4            ; address being looked up
addKind: .res 1
idx: .res 2
count: .res 2               ; number of records in the index table
finalCount: .res 1+1
cur: .res 2
recKind: .res 1
recSize: .res 1
tgtKind: .res 1
fieldOff: .res 1
nameLen: .res 1
emitIdx: .res 1
resultLo: .res 1
resultHi: .res 1
outBuf: .res 64

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

    ; Allocate the index table
    lda #<(HDR_MAX_RECORDS*HDR_ENTRY_SIZE)
    ldx #>(HDR_MAX_RECORDS*HDR_ENTRY_SIZE)
    jsr heapAlloc
    stq hdrTbl

    ; Seed the table with the module decl (record 1)
    lda #0
    sta count
    sta count+1
    ldx #3
:   lda astRoot,x
    sta candAddr,x
    dex
    bpl :-
    lda #HDR_REC_DECL
    jsr findOrAdd
    bcc :+
    jmp tooMany

    ; Phase 1. Walk every record and add whatever it points to.
:   lda #1
    sta cur
    lda #0
    sta cur+1

PhaseA:
    lda count
    cmp cur
    lda count+1
    sbc cur+1
    bcc PhaseADone              ; count < cur
    jsr loadEntry
    lda recKind
    cmp #HDR_REC_NAME
    beq NextA
    jsr hdrFieldFirst
FieldA:
    jsr hdrFieldNext
    bcs NextA
    stx fieldOff
    sta tgtKind
    lda tgtKind
    beq FieldA                  ; plain value
    bmi FieldA                  ; not stored
    ldz fieldOff
    ldx #0
:   nop
    lda (ptr1),z
    sta candAddr,x
    inz
    inx
    cpx #4
    bne :-
    lda tgtKind
    jsr findOrAdd
    bcc FieldA
    jmp tooMany
NextA:
    inc cur
    bne PhaseA
    inc cur+1
    bra PhaseA

PhaseADone:
    lda count
    sta finalCount
    lda count+1
    sta finalCount+1

    jsr openOutput

    ; Header: magic, version, record count
    lda #'P'
    jsr CHROUT
    lda #'H'
    jsr CHROUT
    lda #HDR_VERSION
    jsr CHROUT
    lda count
    jsr CHROUT
    lda count+1
    jsr CHROUT

    ; Phase 2. Write each record.
    lda #1
    sta cur
    lda #0
    sta cur+1

PhaseB:
    lda count
    cmp cur
    lda count+1
    sbc cur+1
    bcc PhaseBDone
    jsr loadEntry
    lda recKind
    cmp #HDR_REC_NAME
    beq WriteName
    jsr writeStruct
    bra NextB

WriteName:
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    inz
    bne :-
    ; Name is 255 characters or longer
    jsr closeOutput
    lda #<strTooLong
    ldx #>strTooLong
    jmp printError
:   inz
    tza
    sta nameLen
    lda #HDR_REC_NAME
    jsr CHROUT
    lda nameLen
    jsr CHROUT
    lda #0
    sta emitIdx
:   ldz emitIdx
    nop
    lda (ptr1),z
    jsr CHROUT
    inc emitIdx
    lda emitIdx
    cmp nameLen
    bne :-

NextB:
    inc cur
    bne PhaseB
    inc cur+1
    bra PhaseB

PhaseBDone:
    jsr closeOutput

    ; Every pointer should have been found in phase 1
    lda count
    cmp finalCount
    bne Internal
    lda count+1
    cmp finalCount+1
    bne Internal

    lda #<strWrote
    ldx #>strWrote
    jsr printStr
    lda count
    ldx count+1
    jsr printWord
    lda #<strRecords
    ldx #>strRecords
    jsr printStr
    lda #<outName
    ldx #>outName
    jsr printStr
    lda #13
    jsr CHROUT
    rts

Internal:
    lda #<strInternal
    ldx #>strInternal
    jmp printError

tooMany:
    lda #<strTooMany
    ldx #>strTooMany
    jmp printError
.endproc

; Write the structure for the record in ptr1, with its pointers replaced
; by record indexes. recKind has the HDR_REC_* kind.
.proc writeStruct
    ldx recKind
    lda hdrRecSize,x
    sta recSize

    ; Copy the structure into outBuf
    ldx #0
    ldz #0
:   nop
    lda (ptr1),z
    sta outBuf,x
    inz
    inx
    cpx recSize
    bne :-

    lda recKind
    jsr hdrFieldFirst
Field:
    jsr hdrFieldNext
    bcs Emit
    stx fieldOff
    sta tgtKind
    lda tgtKind
    beq Field                   ; plain value
    bmi ZeroField

    ; Replace the address with its record index
    ldx fieldOff
    ldy #0
:   lda outBuf,x
    sta candAddr,y
    inx
    iny
    cpy #4
    bne :-
    lda tgtKind
    jsr findOrAdd
    sta resultLo
    stx resultHi
    ldx fieldOff
    lda resultLo
    sta outBuf,x
    inx
    lda resultHi
    sta outBuf,x
    inx
    lda #0
    sta outBuf,x
    inx
    sta outBuf,x
    bra Field

ZeroField:
    ldx fieldOff
    ldy #4
    lda #0
:   sta outBuf,x
    inx
    dey
    bne :-
    bra Field

Emit:
    lda recKind
    jsr CHROUT
    lda #0
    sta emitIdx
:   ldx emitIdx
    lda outBuf,x
    jsr CHROUT
    inc emitIdx
    lda emitIdx
    cmp recSize
    bne :-
    rts
.endproc

; Read the index table entry for record cur.
; Sets ptr1 to the record's address and recKind to its kind.
.proc loadEntry
    lda cur
    ldx cur+1
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   nop
    lda (ptr3),z
    sta ptr1,x
    inz
    inx
    cpx #4
    bne :-
    nop
    lda (ptr3),z
    sta recKind
    rts
.endproc

; Find candAddr in the index table. If it's not there, add it with the kind in A.
; Returns the 1-based record index in A/X (zero for a null address).
; Carry is set if the table is full.
.proc findOrAdd
    sta addKind

    lda candAddr
    ora candAddr+1
    ora candAddr+2
    ora candAddr+3
    bne :+
    lda #0
    tax
    clc
    rts

:   lda #0
    sta idx
    sta idx+1

Search:
    inc idx
    bne :+
    inc idx+1
:   lda count
    cmp idx
    lda count+1
    sbc idx+1
    bcc NotFound                ; count < idx
    lda idx
    ldx idx+1
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   nop
    lda (ptr3),z
    cmp candAddr,x
    bne Search
    inz
    inx
    cpx #4
    bne :-
    lda idx
    ldx idx+1
    clc
    rts

NotFound:
    inc count
    bne :+
    inc count+1
:   lda #<HDR_MAX_RECORDS
    cmp count
    lda #>HDR_MAX_RECORDS
    sbc count+1
    bcc Full                    ; HDR_MAX_RECORDS < count
    lda count
    ldx count+1
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   lda candAddr,x
    nop
    sta (ptr3),z
    inz
    inx
    cpx #4
    bne :-
    lda addKind
    nop
    sta (ptr3),z
    lda count
    ldx count+1
    clc
    rts

Full:
    sec
    rts
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
