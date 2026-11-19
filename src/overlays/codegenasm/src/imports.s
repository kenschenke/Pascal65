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
; the libraries the program uses, in its Uses order, each with the labels
; of its jump table's slots. Code generation keeps them in a membuf as the
; object file lists them (linker.inc). It calls each library's init (slot
; 0) after the program header and its cleanup (slot 1) at the end, and
; copies the list into the object file.

.include "asm.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export readIcodeImports, initLibraries, cleanupLibraries
.export writeLibraries, freeImports

.import readIcodeByte, readStatus, genThreeAddr

.bss

libs: .res 4                ; the membuf, or zero
libCount: .res 1            ; the number of libraries
libsLen: .res 2             ; bytes in libs
left: .res 1                ; libraries left to read or walk
slotsLeft: .res 2           ; slots left in the library
byte: .res 1                ; for putByte and getByte
labelLen: .res 1
label: .res OBJ_NAME_MAX+1  ; a slot's label, null-terminated
isInit: .res 1

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

    jsr readIcodeByte
    sta libCount
    sta left

L1: lda left
    beq DN
    dec left
    jsr readIcodeByte
    cmp #ICODE_IMPORT_LIBRARY
    bne BD

    ; The library's name and slot count
    jsr copyName
    bcs BD
    jsr readIcodeByte
    sta slotsLeft
    jsr putByte
    jsr readIcodeByte
    sta slotsLeft+1
    jsr putByte

    ; Each slot: its kind and label
L2: lda slotsLeft
    ora slotsLeft+1
    beq L1
    jsr readIcodeByte
    jsr putByte
    jsr copyName
    bcs BD
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

; This routine copies a name or label (its length, then its characters)
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

; This routine reads a name or label from the membuf into label,
; null-terminated
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

    ; Slot 0 is the init, slot 1 the cleanup
    jsr getByte                 ; slot 0's kind
    jsr getLabel
    lda isInit
    beq :+
    jsr genCall
:   jsr getByte                 ; slot 1's kind
    jsr getLabel
    lda isInit
    bne :+
    jsr genCall

    ; Skip the rest of the slots
:   sec
    lda slotsLeft
    sbc #2
    sta slotsLeft
    lda slotsLeft+1
    sbc #0
    sta slotsLeft+1
L2: lda slotsLeft
    ora slotsLeft+1
    beq L1
    jsr getByte                 ; the slot's kind
    jsr getLabel
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
