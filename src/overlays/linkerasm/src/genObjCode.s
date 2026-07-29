;
; genObjCode.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; genObjCode routine

.include "c64.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

OBJ_FILENUM = 2
PRG_FILENUM = 3

.export genObjCode

.import sortLinkerTags

.bss

toGo: .res 2
codePos: .res 2
tagsMemBuf: .res 4
tagToFix: .res .sizeof(TAGTOFIX)
prgFilename: .res 17
strbuf: .res 20
readStatus: .res 1

.data

pasExt: .asciiz ".pas"
prgExt: .asciiz ".prg"
strObjFile: .byte "zztmp,s,r"
strObjFile2:
writeExt: .asciiz ",p,w"

.code

; Source filename passed in A/X
.proc genObjCode
    jsr formatPrgFilename

    jsr sortLinkerTags
    stq tagsMemBuf

    ; Delete the output PRG file if it exists
    jsr deletePrgFile

    ; Open the object file
    ; Call SETLFS
    ldx DEVNUM
    lda #OBJ_FILENUM
    tay
    jsr SETLFS
    ; Call SETNAM
    ldx #<strObjFile
    ldy #>strObjFile
    lda #strObjFile2-strObjFile
    jsr SETNAM
    ; Open the file
    jsr OPEN

    ; Open the PRG file
    jsr openPrgFile

    ; Clear readStatus
    lda #0
    sta readStatus

    ; Write the load address to the new PRG file
    ; $2001 for MEGA65
    ldx #PRG_FILENUM
    jsr CHKOUT
    lda #1
    jsr CHROUT
    lda #$20
    jsr CHROUT

    ; Rewind the tagsMemBuf
    ldq tagsMemBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Read the first tagToFix from the membuf (initializes toGo)
    lda #0
    sta codePos
    sta codePos+1
    jsr readTagToFix

    ; Loop through the object file
L1: lda readStatus
    and #$40
    bne DN

    lda toGo
    cmp #$ff
    bne L2
    lda toGo+1
    cmp #$ff
    bne L2

    ; Copy a byte from the object file
    jsr readByte
    pha
    ldx #PRG_FILENUM
    jsr CHKOUT
    pla
    jsr CHROUT
    bra L1

    ; Is toGo zero?
L2: lda toGo
    ora toGo+1
    bne L3

    jsr updateOffset
    bra L1

    ; Copy a byte from the object file
L3: jsr readByte
    pha
    ldx #PRG_FILENUM
    jsr CHKOUT
    pla
    jsr CHROUT

    lda toGo
    sec
    sbc #1
    sta toGo
    lda toGo+1
    sbc #0
    sta toGo+1
    lda codePos
    clc
    adc #1
    sta codePos
    lda codePos+1
    adc #0
    sta codePos+1
    bra L1

DN: ; Close the output PRG file
    lda #PRG_FILENUM
    jsr CLOSE
    ; Close the input object file
    lda #OBJ_FILENUM
    jsr CLOSE
    jsr CLRCHN

    jsr deleteObjFile

    ldq tagsMemBuf
    jsr freeMemBuf
    
    rts
.endproc

.proc testObjCode
    ; Open the object file
    ; Call SETLFS
    ldx DEVNUM
    lda #OBJ_FILENUM
    tay
    jsr SETLFS
    ; Call SETNAM
    ldx #<strObjFile
    ldy #>strObjFile
    lda #strObjFile2-strObjFile
    jsr SETNAM
    ; Open the file
    jsr OPEN

    ; Open the PRG file
    jsr openPrgFile

    ; Clear readStatus
    lda #0
    sta readStatus

    jsr readByte
    pha
    ldx #PRG_FILENUM
    jsr CHKOUT
    pla
    jsr CHROUT

    jsr readByte
    pha
    ldx #PRG_FILENUM
    jsr CHKOUT
    pla
    jsr CHROUT

    lda #1
    jsr CLOSE
    lda #2
    jsr CLOSE

    jsr CLRCHN

    rts
.endproc

; This routine reads a byte from file #2 (the object file).
; It updated readStatus with the latest I/O status.
; The byte is returned in A.
.proc readByte
    ldx #OBJ_FILENUM
    jsr CHKIN
    jsr CHRIN
    pha
    lda STATUS
    sta readStatus
    pla
    rts
.endproc

; This routine deletes the input object file
.proc deleteObjFile
    ; Copy strObjFile to strbuf (leaving off the ",p,r")
    ldx #0
L1: lda strObjFile,x
    cmp #','
    beq L2
    sta strbuf,x
    inx
    bne L1

L2: lda #0
    sta strbuf,x

    ; Delete the file
    lda #<strbuf
    sta ptr1
    lda #>strbuf
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr scratchFile

    rts
.endproc

; This routine formats the output PRG filename.
; The input is the source filename in A/X.
;
; If the source filename ends in ".pas",
; drop the extension and use that for the PRG filename.
.proc formatPrgFilename
    sta ptr1
    stx ptr1+1

    ; Copy the filename
    ldy #0
    ldx #0
L1: lda (ptr1),y
    sta prgFilename,x
    beq L2
    inx
    iny
    bne L1

L2: jsr doesFilenameEndWithPas
    bne L3
    jsr dropPasExtension
    rts

    ; Is the filename > 12 characters long?
L3: ldy #0
:   lda prgFilename,y
    beq :+
    iny
    bne :-
:   cpy #12
    bcc L4
    ldy #12
L4: ldx #0
:   lda prgExt,x
    sta prgFilename,y
    beq :+
    inx
    iny
    bne :-
:   rts
.endproc

; This routine looks at the null-terminated filename ptr1
; and determines whether it ends in ".pas". It does a
; case-insensitive comparison.
;
; The Z flag is set if the filename ends in ".pas"
.proc doesFilenameEndWithPas
    ldy #0
    ; Find the last character in the filename
:   lda prgFilename,y
    beq :+
    iny
    bne :-

:   dey
    ; Work backwards looking for the last dot
:   cpy #0
    beq L4
    lda prgFilename,y
    cmp #'.'
    beq L5
    dey
    bne :-

    ; No dot found
L4: lda #1
    rts

    ; Dot found - check the rest of the string
L5: iny
    ldx #1

    ; Loop through the characters in pasExt
:   lda prgFilename,y
    and #$7f            ; force to lower case
    beq :+
    cmp pasExt,x
    bne L8
    inx
    iny
    bne :-

:   cmp pasExt,x
L8: rts
.endproc

; This routine truncates prgFilename by looking for the
; last dot and setting it to 0.
.proc dropPasExtension
    ldy #0
    ; Find the last character in the filename
:   lda prgFilename,y
    beq :+
    iny
    bne :-

    ; Work backwards looking for the last dot
:   cpy #0
    beq DN
    lda prgFilename,y
    cmp #'.'
    beq :+
    dey
    bne :-

    ; Dot found - check the rest of the string
:   lda #0
    sta prgFilename,y
DN: rts
.endproc

.proc deletePrgFile
    ; First, see if the output PRG filename already exists
    lda #<prgFilename
    ldx #>prgFilename
    ldy #0
    ldz #0
    jsr doesFileExist
    beq :+
    ; The file does exist. Delete it.
    lda #<prgFilename
    sta ptr1
    lda #>prgFilename
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr scratchFile

:   rts
.endproc

.proc openPrgFile
    ; Copy the filename from prgFilename to strbuf
    ldx #0
L1: lda prgFilename,x
    beq L2
    sta strbuf,x
    inx
    bne L1

    ; Add the ",p,w" extension
L2: ldy #0
L3: lda writeExt,y
    beq L4
    sta strbuf,x
    inx
    iny
    bne L3

    ; Call SETLFS
L4: phx                 ; X contains length of filename (including ",p,w")
    ldx DEVNUM
    lda #PRG_FILENUM
    tay
    jsr SETLFS
    ; Call SETNAM
    ldx #<strbuf
    ldy #>strbuf
    pla
    jsr SETNAM
    ; Open the file
    jsr OPEN

    rts
.endproc

.proc readTagToFix
    ldq tagsMemBuf
    jsr isMemBufAtEnd
    bne :+
    lda #$ff
    sta toGo
    sta toGo+1
    rts

:   ldq tagsMemBuf
    stq ptr1
    lda #<tagToFix
    sta ptr2
    lda #>tagToFix
    sta ptr2+1
    ldx #0
    stx ptr2+2
    stx ptr2+3
    lda #.sizeof(TAGTOFIX)
    jsr readFromMemBuf

    ldx #TAGTOFIX::offset
    lda tagToFix,x
    sta intOp1
    inx
    lda tagToFix,x
    sta intOp1+1
    lda codePos
    sta intOp2
    lda codePos+1
    sta intOp2+1
    jsr subInt16
    lda intOp1
    sta toGo
    lda intOp1+1
    sta toGo+1

    rts
.endproc

.proc updateOffset
    ldx #OBJ_FILENUM
    jsr CHKIN
    jsr CHRIN           ; discard the current byte

    ldx #TAGTOFIX::type
    lda tagToFix,x
    cmp #LINKADDR_LOW
    beq LO
    cmp #LINKADDR_HIGH
    beq HI

    ; Update both bytes
    ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #TAGTOFIX::address
    lda tagToFix,x
    jsr CHROUT
    ldx #OBJ_FILENUM
    jsr CHKIN
    jsr CHRIN           ; discard the next byte too
    ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #TAGTOFIX::address+1
    lda tagToFix,x
    jsr CHROUT
    lda #2
    bra RN

    ; Update just the low byte
LO: ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #TAGTOFIX::address
    lda tagToFix,x
    jsr CHROUT
    lda #1
    bra RN

    ; Update just the high byte
HI: ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #TAGTOFIX::address+1
    lda tagToFix,x
    jsr CHROUT
    lda #1

    ; Update the codePos
RN: clc
    adc codePos
    sta codePos
    lda codePos+1
    adc #0
    sta codePos+1

    ; Read the next tag to fix
    jmp readTagToFix
.endproc
