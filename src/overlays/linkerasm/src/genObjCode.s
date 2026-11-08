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
.include "error.inc"

OBJ_FILENUM = 2
PRG_FILENUM = 3
RT_FILENUM = 4          ; a runtime file (see copyRuntime)

.export genObjCode

.import sortLinkerTags

.bss

; For copyRuntime
rtFiles: .res 1         ; files left to copy
rtNameLen: .res 1
rtSkip: .res 2          ; bytes to skip at the start of the file
rtLeft: .res 2          ; bytes left to copy
rtBlock: .res 1         ; bytes in this block (0 means 256)
rtBuf: .res 256

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
    ldx #TAGTOFIX::type
    lda tagToFix,x
    cmp #LINKADDR_RUNTIME
    bne :+
    jmp copyRuntime

:   ldx #OBJ_FILENUM
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

; This routine copies the rest of a static runtime into the PRG, at a
; LINKADDR_RUNTIME tag. The object file has the list of files to copy there
; (see linker.inc), which isn't copied. codePos counts the bytes copied, as
; codegen's codeOffset did. A runtime file that's missing or too short is a
; compiler error, errRuntimeFileInvalid.
;
; The bytes are copied in blocks of up to 256, so the input and output
; channels change once a block rather than once a byte.
.proc copyRuntime
    jsr readByte                ; The number of files
    sta rtFiles

L1: lda rtFiles
    bne :+
    jmp readTagToFix            ; Done

    ; The file's name
:   jsr readByte
    sta rtNameLen
    ldx #0
:   phx
    jsr readByte
    plx
    sta strbuf,x
    inx
    cpx rtNameLen
    bne :-

    ; The bytes to skip and to copy
    jsr readByte
    sta rtSkip
    jsr readByte
    sta rtSkip+1
    jsr readByte
    sta rtLeft
    sta intOp1
    jsr readByte
    sta rtLeft+1
    sta intOp1+1
    lda codePos                 ; Count them now
    clc
    adc intOp1
    sta codePos
    lda codePos+1
    adc intOp1+1
    sta codePos+1

    ; Open the file and skip to the part to copy
    ldx DEVNUM
    lda #RT_FILENUM
    tay
    jsr SETLFS
    lda rtNameLen
    ldx #<strbuf
    ldy #>strbuf
    jsr SETNAM
    jsr OPEN
    ldx #RT_FILENUM
    jsr CHKIN
L2: lda rtSkip
    ora rtSkip+1
    beq L3
    jsr CHRIN
    lda STATUS
    bne ER                      ; The file is missing or too short
    lda rtSkip
    bne :+
    dec rtSkip+1
:   dec rtSkip
    bra L2

    ; Copy it
L3: lda rtLeft
    ora rtLeft+1
    beq CL                      ; Branch if all of it is copied
    jsr copyRuntimeBlock
    bcc L3

ER: jsr CLRCHN
    lda #errRuntimeFileInvalid
    ldx #0
    ldy #0
    jsr compilerError
CL: lda #RT_FILENUM
    jsr CLOSE
    dec rtFiles
    jmp L1
.endproc

; This routine copies the next block of a runtime file, up to 256 bytes of
; rtLeft, and subtracts it from rtLeft. The carry is set if the file ends
; early or fails.
.proc copyRuntimeBlock
    lda rtLeft+1
    beq :+
    lda #0                      ; A whole page
    bra :++
:   lda rtLeft
:   sta rtBlock
    ldx #RT_FILENUM
    jsr CHKIN
    ldx #0
L1: phx
    jsr CHRIN
    plx
    sta rtBuf,x
    inx
    lda STATUS
    beq L2
    ; The file ended or failed. Only its last byte may have EOF set.
    and #$bf
    bne ER
    cpx rtBlock
    bne ER                      ; Not the last byte of the block
    lda rtBlock                 ; Nor the last block: rtLeft = rtBlock
    bne :+
    lda rtLeft                  ; A whole page: rtLeft = $100
    bne ER
    lda rtLeft+1
    cmp #1
    bne ER
    bra L2
:   lda rtLeft+1
    bne ER
    lda rtLeft
    cmp rtBlock
    bne ER
L2: cpx rtBlock
    bne L1

    ldx #PRG_FILENUM
    jsr CHKOUT
    ldx #0
:   lda rtBuf,x
    jsr CHROUT
    inx
    cpx rtBlock
    bne :-

    ; Subtract the block from rtLeft. A whole page (rtBlock = 0) leaves
    ; the low byte as it is and takes one from the high byte.
    lda rtLeft
    sec
    sbc rtBlock
    sta rtLeft
    lda rtBlock
    beq :+
    lda rtLeft+1
    sbc #0
    sta rtLeft+1
    clc
    rts
:   dec rtLeft+1
    clc
    rts

ER: sec
    rts
.endproc
