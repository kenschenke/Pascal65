.include "c64.inc"
.include "icode.inc"
.include "linker.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export dumpIcode, memBuf, dumpNewline, dumpChar, printz, dumpFrameName

.import readInstruction, dumpHex

.data

tempFn: .byte "zztmpicode,s,r"
tempFn2:

strHdr: .asciiz "HDR "
strPrg: .asciiz "PRG "
strUnit: .asciiz "UNIT "
strBadHdr: .asciiz "BAD HEADER"
strImpLib: .asciiz "IMP LIB "
strImpUnit: .asciiz "IMP UNIT "
unitPrefix: .asciiz ICODE_UNIT_PREFIX
strSeqRead: .asciiz ",s,r"
strBadImp: .asciiz "BAD IMPORT"
strIndent: .asciiz "   "
strFrm: .asciiz "FRM "

.bss

memBuf: .res 4
buf: .res 1
hdrByte: .res 1
hdrCount: .res 1
impLeft: .res 1             ; for dumpImports
slotsLeft: .res 2
lineLen: .res 1
slotsLo: .res 1             ; the header's level 1 slots
slotsHi: .res 1
MAX_FRAMES = 16             ; frames dumped by name
NAME_SIZE = 13              ; unit::name
frameNames: .res MAX_FRAMES * NAME_SIZE
frameIdx: .res 1
namePos: .res 1
MAX_UNITS = 16              ; unit files dumped
unitCount: .res 1
unitNames: .res MAX_UNITS * NAME_SIZE
unitIdx: .res 1
recording: .res 1           ; non-zero while the program's file is dumped
unitFn: .res 24
unitFnLen: .res 1

.code

; This routine dumps the program's icode file, then each Pascal unit's own
; file its imports table lists (icode.inc), into a membuf it returns in Q.
.proc dumpIcode
    jsr allocMemBuf
    stq memBuf
    lda #0
    sta unitCount
    sta unitIdx

    lda #1
    sta recording
    ldx #<tempFn
    ldy #>tempFn
    lda #tempFn2-tempFn
    jsr dumpFile
    lda #0
    sta recording

    ; Each unit's: ICODE_UNIT_PREFIX, its name, then ",s,r"
L1: lda unitIdx
    cmp unitCount
    bne :+
    ldq memBuf
    rts
:   lda unitIdx
    jsr unitNamePos
    tay
    ldx #0
:   lda unitPrefix,x
    beq :+
    sta unitFn,x
    inx
    bra :-
:   lda unitNames,y
    beq :+
    sta unitFn,x
    inx
    iny
    bra :-
:   ldy #0
:   lda strSeqRead,y
    beq :+
    sta unitFn,x
    inx
    iny
    bra :-
:   txa
    ldx #<unitFn
    ldy #>unitFn
    jsr dumpFile
    inc unitIdx
    bra L1
.endproc

; This routine dumps the icode file named in X/Y, its length in A
.proc dumpFile
    pha
    phx
    phy
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ply
    plx
    pla
    jsr SETNAM
    ; Open the file and set input channel
    jsr OPEN
    ldx #1
    jsr CHKIN

    jsr dumpHeader
    bcs L3
    jsr dumpImports
    bcs L3
    jsr dumpFrames

    ; Loop, reading instructions from the icode
L1: lda STATUS
    cmp #$40
    beq L3
    jsr CHRIN

    ; If __DEBUG__ is defined, leave IC_LIN instructions in the dump
    ; for debugging purposes.
.ifndef __DEBUG__
    ; If the instruction is IC_LIN, skip it (and the next three bytes)
    cmp #IC_LIN
    bne L2
    jsr CHRIN
    jsr CHRIN
    jsr CHRIN
    bra L1
.endif

L2: jsr readInstruction
    jsr dumpNewline
    bra L1

    ; Close the icode file
L3: lda #1
    jsr CLOSE
    jmp CLRCHN
.endproc

; This routine dumps the icode file's header (icode.inc) as one line:
;    HDR PRG|UNIT name mode stacksize slots
; with the mode, stack size and level 1 slots in hex. If the file isn't
; icode of this version it dumps BAD HEADER and returns with the carry set.
.proc dumpHeader
    jsr CHRIN
    cmp #ICODE_MAGIC0
    bne BX
    jsr CHRIN
    cmp #ICODE_MAGIC1
    bne BX
    jsr CHRIN
    cmp #ICODE_VERSION
    beq :+
BX: jmp BD

:   lda #<strHdr
    ldx #>strHdr
    jsr printz
    jsr CHRIN
    cmp #ICODE_KIND_UNIT
    beq :+
    lda #<strPrg
    ldx #>strPrg
    bra :++
:   lda #<strUnit
    ldx #>strUnit
:   jsr printz

    ; The mode, the stack size and the slots, read before the name that
    ; follows them
    jsr CHRIN
    sta hdrByte
    jsr CHRIN
    pha
    jsr CHRIN
    tax
    pla
    phx
    pha
    jsr CHRIN
    sta slotsLo
    jsr CHRIN
    sta slotsHi

    ; The name
    jsr CHRIN
    sta hdrCount
:   lda hdrCount
    beq :+
    jsr CHRIN
    jsr dumpChar
    dec hdrCount
    bra :-
:   lda #' '
    jsr dumpChar

    lda hdrByte
    ldx #0
    ldy #0
    ldz #0
    jsr dumpHex
    lda #' '
    jsr dumpChar
    pla
    plx
    ldy #0
    ldz #0
    jsr dumpHex
    lda #' '
    jsr dumpChar
    lda slotsLo
    ldx slotsHi
    ldy #0
    ldz #0
    jsr dumpHex
    jsr dumpNewline
    clc
    rts

BD: lda #<strBadHdr
    ldx #>strBadHdr
    jsr printz
    jsr dumpNewline
    sec
    rts
.endproc

; This routine dumps the imports table that follows the header. Each
; library is a line, then its slots' kinds (R for a routine, V for a
; variable), 64 to a line. A table with no imports dumps nothing. The
; carry is set if an import isn't a library.
;    IMP LIB name slotcount
;       RRVRR...
.proc dumpImports
    jsr CHRIN
    sta impLeft

L1: lda impLeft
    bne :+
    clc
    rts
:   dec impLeft
    jsr CHRIN
    cmp #ICODE_IMPORT_UNIT
    bne :+
    jsr dumpUnitImport
    jmp L1
:
    cmp #ICODE_IMPORT_LIBRARY
    beq :+
    lda #<strBadImp
    ldx #>strBadImp
    jsr printz
    jsr dumpNewline
    sec
    rts

    ; IMP LIB, the name and the slot count
:   lda #<strImpLib
    ldx #>strImpLib
    jsr printz
    jsr CHRIN
    sta hdrCount
:   lda hdrCount
    beq :+
    jsr CHRIN
    jsr dumpChar
    dec hdrCount
    bra :-
:   lda #' '
    jsr dumpChar
    jsr CHRIN
    sta slotsLeft
    jsr CHRIN
    sta slotsLeft+1
    tax
    lda slotsLeft
    ldy #0
    ldz #0
    jsr dumpHex
    lda #0
    sta lineLen

    ; Each slot's kind
L2: lda slotsLeft
    ora slotsLeft+1
    bne :+
    jsr dumpNewline
    jmp L1
:   lda lineLen
    bne :+
    jsr dumpNewline
    lda #<strIndent
    ldx #>strIndent
    jsr printz
:   jsr CHRIN
    cmp #OBJLIB_VARIABLE
    beq :+
    lda #'R'
    bra :++
:   lda #'V'
:   jsr dumpChar
    inc lineLen
    lda lineLen
    cmp #64
    bne :+
    lda #0
    sta lineLen
:   lda slotsLeft
    bne :+
    dec slotsLeft+1
:   dec slotsLeft
    bra L2
.endproc

; This routine dumps the frames table that follows the imports table, a
; line for each frame with its slot count in hex, and keeps the names for
; dumpFrameName:
;    FRM name slots
.proc dumpFrames
    jsr CHRIN
    sta impLeft
    lda #0
    sta frameIdx
L1: lda impLeft
    bne :+
    rts
:   dec impLeft
    lda #<strFrm
    ldx #>strFrm
    jsr printz

    ; The name, kept in frameNames if there's room
    jsr nameSlot
    jsr CHRIN
    sta hdrCount
:   lda hdrCount
    beq :+
    jsr CHRIN
    jsr keepChar
    jsr dumpChar
    dec hdrCount
    bra :-
:   lda #0
    jsr keepChar
    inc frameIdx
    lda #' '
    jsr dumpChar
    jsr CHRIN
    pha
    jsr CHRIN
    tax
    pla
    ldy #0
    ldz #0
    jsr dumpHex
    jsr dumpNewline
    bra L1
.endproc

; This routine sets namePos to the start of frameIdx's name in frameNames,
; or $FF if it has no room
.proc nameSlot
    lda #$ff
    ldx frameIdx
    cpx #MAX_FRAMES
    bcs DN
    lda #0
:   cpx #0
    beq DN
    clc
    adc #NAME_SIZE
    dex
    bra :-
DN: sta namePos
    rts
.endproc

; This routine keeps the character in A at namePos, if there's room, and
; moves namePos on. It keeps A.
.proc keepChar
    ldx namePos
    cpx #$ff
    beq :+
    sta frameNames,x
    inc namePos
:   rts
.endproc

; This routine dumps a space and the name of the frame numbered in A (from
; 1), or its number in hex past MAX_FRAMES
.proc dumpFrameName
    pha
    lda #' '
    jsr dumpChar
    pla
    sta frameIdx
    dec frameIdx
    jsr nameSlot
    lda namePos
    cmp #$ff
    bne L1
    inc frameIdx
    lda frameIdx
    ldx #0
    ldy #0
    ldz #0
    jmp dumpHex
L1: ldx namePos
    lda frameNames,x
    beq DN
    jsr dumpChar
    inc namePos
    bra L1
DN: rts
.endproc

.proc dumpNewline
    lda #13
    ; Fall through to dumpChar
.endproc

.proc dumpChar
    sta buf
    ldq memBuf
    stq ptr1
    lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf
    rts
.endproc

.proc printz
    sta ptr2
    stx ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ldq ptr1
    jsr pushQ
    ldq memBuf
    stq ptr1
    
    ldy #0
:   lda (ptr2),y
    beq :+
    iny
    bne :-
:   tya
    ldx #0
    jsr writeToMemBuf
    jsr popQ
    stq ptr1
    rts
.endproc

; This routine dumps a Pascal unit's import as a line, and in the
; program's file keeps its name, to dump the unit's own file after it:
;    IMP UNIT name
.proc dumpUnitImport
    lda #<strImpUnit
    ldx #>strImpUnit
    jsr printz
    lda unitCount
    jsr unitNamePos
    sta namePos
    jsr CHRIN
    sta hdrCount
:   lda hdrCount
    beq :+
    jsr CHRIN
    jsr keepUnitChar
    jsr dumpChar
    dec hdrCount
    bra :-
:   lda #0
    jsr keepUnitChar
    lda recording
    beq :+
    lda unitCount
    cmp #MAX_UNITS
    bcs :+
    inc unitCount
:   jmp dumpNewline
.endproc

; This routine keeps the character in A at namePos in unitNames, while
; the program's file is dumped and there's room, and moves namePos on. It
; keeps A.
.proc keepUnitChar
    ldx recording
    beq :+
    ldx unitCount
    cpx #MAX_UNITS
    bcs :+
    ldx namePos
    sta unitNames,x
    inc namePos
:   rts
.endproc

; This routine returns in A the offset in unitNames of the name numbered
; in A
.proc unitNamePos
    tax
    lda #0
:   cpx #0
    beq :+
    clc
    adc #NAME_SIZE
    dex
    bra :-
:   rts
.endproc
