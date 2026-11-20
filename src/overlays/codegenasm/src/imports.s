;
; imports.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The icode file's imports table (icode.inc, icodeImports.s in icodeasm):
; the libraries the program uses, in its Uses order, each with the kinds
; of its jump table's slots. Code generation keeps them in a membuf as the
; object file lists them (linker.inc). It calls each library's init (slot
; 0, "name.0") after the program header and its cleanup (slot 1,
; "name.1") at the end, and copies the list into the object file. The
; code names every slot that way (icodeExports.s in icodeasm), and the
; linker defines the names.
;
; The table also lists the program's Pascal units (ICODE_IMPORT_UNIT or
; ICODE_IMPORT_TPU), each with its code in its own icode file or its TPU,
; which genUnits (codegen.s) reads after the program's, each into its own
; object file. A unit's own imports are skipped (skipIcodeImports).

.include "asm.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export readIcodeImports, initLibraries, cleanupLibraries
.export writeLibraries, freeImports, skipIcodeImports, unitCount, getImportUnit
.export isImportTpu, writeUnits

.import readIcodeByte, readStatus, genThreeAddr

.bss

libs: .res 4                ; the membuf, or zero
libCount: .res 1            ; the number of libraries
libsLen: .res 2             ; bytes in libs
left: .res 1                ; libraries left to read or walk
slotsLeft: .res 2           ; slots left in the library
byte: .res 1                ; for putByte and getByte
labelLen: .res 1
label: .res OBJ_NAME_MAX+3  ; a slot's label, null-terminated
isInit: .res 1
; The program's Pascal units (ICODE_IMPORT_UNIT), each in its own icode
; file, in the units list's order: each name null-terminated
MAX_UNITS = 16
UNIT_NAME_SIZE = 13         ; unit::name
unitCount: .res 1
unitNames: .res MAX_UNITS * UNIT_NAME_SIZE
unitIdx: .res 1
unitTpu: .res MAX_UNITS      ; non-zero for a unit whose code is in its TPU
tpuFlag: .res 1

.code

; This routine reads the imports table, which follows the header, into the
; membuf. The carry is set if it is bad: an import that isn't a library, a
; name too long or the end of the file.
.proc readIcodeImports
    jsr allocMemBuf
    stq libs
    lda #0
    sta libsLen
    sta libsLen+1

    lda #0
    sta libCount
    sta unitCount
    jsr readIcodeByte
    sta left

L1: lda left
    beq DN
    dec left
    jsr readIcodeByte
    cmp #ICODE_IMPORT_UNIT
    bne :+
    lda #0                      ; its code is in its own file
    bra RU
:   cmp #ICODE_IMPORT_TPU
    bne :+
    lda #1                      ; its code is in its TPU
RU: jsr readUnit
    bcs BD
    bra L1
:   cmp #ICODE_IMPORT_LIBRARY
    bne BD
    inc libCount

    ; The library's name and slot count
    jsr copyName
    bcs BD
    jsr readIcodeByte
    sta slotsLeft
    jsr putByte
    jsr readIcodeByte
    sta slotsLeft+1
    jsr putByte

    ; Each slot's kind
L2: lda slotsLeft
    ora slotsLeft+1
    beq L1
    jsr readIcodeByte
    jsr putByte
    lda slotsLeft
    bne :+
    dec slotsLeft+1
:   dec slotsLeft
    bra L2

DN: lda readStatus
    and #$40
    bne BD
    clc
    rts

BD: sec
    rts
.endproc

; This routine copies a name (its length, then its characters)
; from the icode file to the membuf. The carry is set if it is too long.
.proc copyName
    jsr readIcodeByte
    cmp #OBJ_NAME_MAX+1
    bcs DN
    sta labelLen
    jsr putByte
:   lda labelLen
    beq :+
    jsr readIcodeByte
    jsr putByte
    dec labelLen
    bra :-
:   clc
DN: rts
.endproc

; This routine writes the byte in A to the membuf
.proc putByte
    sta byte
    ldq libs
    stq ptr1
    lda #<byte
    sta ptr2
    lda #>byte
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf
    inc libsLen
    bne :+
    inc libsLen+1
:   rts
.endproc

; This routine reads the next byte of the membuf into A
.proc getByte
    ldq libs
    stq ptr1
    lda #<byte
    sta ptr2
    lda #>byte
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda byte
    rts
.endproc

; This routine moves the membuf's position to its start
.proc rewind
    ldq libs
    stq ptr1
    lda #0
    tax
    jmp setMemBufPos
.endproc

; This routine reads a name from the membuf into label, null-terminated,
; with its length in labelLen
.proc getLabel
    jsr getByte
    sta labelLen
    ldx #0
:   cpx labelLen
    beq :+
    phx
    jsr getByte
    plx
    sta label,x
    inx
    bra :-
:   lda #0
    sta label,x
    rts
.endproc

; This routine writes a JSR to each library's init (slot 0), in order
.proc initLibraries
    lda #1
    sta isInit
    bra genLibraryInitCleanup
.endproc

; This routine writes a JSR to each library's cleanup (slot 1), in order
.proc cleanupLibraries
    lda #0
    sta isInit
    ; Fall through to genLibraryInitCleanup
.endproc

.proc genLibraryInitCleanup
    jsr rewind
    lda libCount
    sta left

L1: lda left
    bne :+
    rts
:   dec left

    ; The name, then the slot count
    jsr getLabel
    jsr getByte
    sta slotsLeft
    jsr getByte
    sta slotsLeft+1

    ; Slot 0 is the init, "name.0", and slot 1 the cleanup, "name.1"
    ldx labelLen
    lda #'.'
    sta label,x
    lda isInit
    eor #1
    clc
    adc #'0'
    sta label+1,x
    lda #0
    sta label+2,x
    jsr genCall

    ; Skip the slots' kinds
L2: lda slotsLeft
    ora slotsLeft+1
    beq L1
    jsr getByte
    lda slotsLeft
    bne :+
    dec slotsLeft+1
:   dec slotsLeft
    bra L2
.endproc

; This routine writes a JSR to the label in label
.proc genCall
    lda #<label
    ldx #>label
    ldy #LINKADDR_BOTH
    ldz #1
    jsr linkAddressLookup
    genThree OC_JSR, 0
    rts
.endproc

; This routine writes the object file's libraries to the current output:
; their count, then each one, as the membuf holds them.
.proc writeLibraries
    lda libCount
    jsr CHROUT
    jsr rewind
L1: lda libsLen
    ora libsLen+1
    bne :+
    rts
:   jsr getByte
    jsr CHROUT
    lda libsLen
    bne :+
    dec libsLen+1
:   dec libsLen
    bra L1
.endproc

; This routine writes the object file's units to the current output: their
; count, then each one's name (its length, then its characters), in the
; imports table's order. The linker links each one's object file after the
; program's.
.proc writeUnits
    lda unitCount
    jsr CHROUT
    lda #0
    sta unitIdx
L1: lda unitIdx
    cmp unitCount
    bne :+
    rts
:   jsr getImportUnit
    sta ptr3
    stx ptr3+1
    ldy #0
:   lda (ptr3),y
    beq :+
    iny
    bra :-
:   tya
    jsr CHROUT
    ldy #0
:   lda (ptr3),y
    beq :+
    jsr CHROUT
    iny
    bra :-
:   inc unitIdx
    bra L1
.endproc

; This routine frees the membuf, if there is one
.proc freeImports
    ldq libs
    jsr isQZero
    beq :+
    jsr freeMemBuf
    lda #0
    tax
    tay
    taz
    stq libs
:   rts
.endproc

; This routine clears the membuf pointer. Code generation calls it before
; anything else, since an overlay's BSS isn't cleared.
.export initImports
.proc initImports
    lda #0
    tax
    tay
    taz
    stq libs
    rts
.endproc

; This routine reads a Pascal unit's name from the imports table into
; unitNames, and keeps in unitTpu the flag in A: non-zero if its code is
; in its TPU (ICODE_IMPORT_TPU). The carry is set if it is too long or there are too many.
.proc readUnit
    sta tpuFlag
    lda unitCount
    cmp #MAX_UNITS
    bcs DN
    jsr unitNamePtr
    jsr readIcodeByte
    cmp #UNIT_NAME_SIZE
    bcs DN
    sta labelLen
    ldy #0
:   cpy labelLen
    beq :+
    phy
    jsr readIcodeByte
    ply
    sta (ptr3),y
    iny
    bra :-
:   lda #0
    sta (ptr3),y
    ldx unitCount
    lda tpuFlag
    sta unitTpu,x
    inc unitCount
    clc
DN: rts
.endproc

; This routine points ptr3 (16 bits) at the name numbered unitCount in
; unitNames
.proc unitNamePtr
    lda #<unitNames
    sta ptr3
    lda #>unitNames
    sta ptr3+1
    ldx unitCount
:   beq DN
    lda ptr3
    clc
    adc #UNIT_NAME_SIZE
    sta ptr3
    bcc :+
    inc ptr3+1
:   dex
    bra :--
DN: rts
.endproc

; This routine returns in A non-zero if the program's Pascal unit
; numbered in A, from 0, has its code in its TPU (ICODE_IMPORT_TPU)
.proc isImportTpu
    tax
    lda unitTpu,x
    rts
.endproc

; This routine returns in A/X a pointer to the name of the program's
; Pascal unit numbered in A, from 0 (null-terminated)
.proc getImportUnit
    ldx unitCount
    phx
    sta unitCount
    jsr unitNamePtr
    pla
    sta unitCount
    lda ptr3
    ldx ptr3+1
    rts
.endproc

; This routine reads past a unit's imports table. Only the program's
; imports are linked, and code names a library's slots by name. The carry
; is set if the table is bad.
.proc skipIcodeImports
    jsr readIcodeByte
    sta left
L1: lda left
    beq DN
    dec left
    jsr readIcodeByte
    pha
    jsr readIcodeByte           ; the name
    sta labelLen
:   lda labelLen
    beq :+
    jsr readIcodeByte
    dec labelLen
    bra :-
:   pla
    cmp #ICODE_IMPORT_UNIT
    beq L1
    cmp #ICODE_IMPORT_TPU
    beq L1
    cmp #ICODE_IMPORT_LIBRARY
    bne BD
    jsr readIcodeByte           ; the slot count, then the slots' kinds
    sta slotsLeft
    jsr readIcodeByte
    sta slotsLeft+1
L2: lda slotsLeft
    ora slotsLeft+1
    beq L1
    jsr readIcodeByte
    lda slotsLeft
    bne :+
    dec slotsLeft+1
:   dec slotsLeft
    bra L2

DN: lda readStatus
    and #$40
    bne BD
    clc
    rts
BD: sec
    rts
.endproc
