;
; runtime.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The runtime, at RT_BASE in the PRG
;
; A program either has the runtime linked into it (static mode, chosen by
; $StaticRuntime) or loads it when it runs (dynamic mode, the default). The
; object file's header gives the mode and the features (RTF_*) the program
; uses.
;
; Static mode: the runtime is a core, which every program gets, and
; packages, which a program gets only if it uses their feature (see
; rtpkg.inc). The core file (coreN) is its length, then the jump table, then
; the core's code, data and BSS. Each package follows the core, in package
; order, so its address depends on which packages before it are linked.
; There is one variant file of each package for each address, such as
; trig1c, and each starts with a header listing the jump table entries to
; point at the package's routines.
;
; layoutRuntime reads the core's jump table and patches it from the header
; of each package the program needs, and works out the runtime's size.
; writeRuntime writes the table, then copies the rest of the core and each
; package straight into the PRG.
;
; Dynamic mode: the runtime is an empty jump table and the loader
; (loader.s) after it. The loader fills the jump table at run time. The
; header of runtimeN gives rtLow, which takes the place of $C000 as the
; ceiling for the program, its heap and its stack.

.include "c64.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "asm.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "rtlayout.inc"
.include "error.inc"
.include "4510macros.inc"

JMPTBL_SIZE = RT_JMPTBL_SIZE

LFN_RT = 4                  ; logical file numbers
LFN_PRG = 3

.export layoutRuntime, writeRuntime, codeCeiling

.import objMode, objFeatures, progBase
.import loaderStart, LOADER_SIZE, LOADER_INIT_L: zp, LOADER_INIT_H: zp

.data

coreName: .asciiz .sprintf("core%d", RT_ABI_VERSION)
runtimeName: .asciiz .sprintf("runtime%d", RT_ABI_VERSION)
abiDigits: .asciiz .sprintf("%d", RT_ABI_VERSION)
fileSuffix: .asciiz ",p,r"
rtMagic: .byte RTH_MAGIC0, RTH_MAGIC1, RTH_MAGIC2, RTH_MAGIC3, RT_ABI_VERSION

; Package file name prefixes, in package order (RT_PKG_* in asm.inc)
pkgDynArrays: .asciiz "dynarrays"
pkgFiles: .asciiz "files"
pkgTrig: .asciiz "trig"
pkgNamesL: .byte <pkgDynArrays, <pkgFiles, <pkgTrig
pkgNamesH: .byte >pkgDynArrays, >pkgFiles, >pkgTrig

.bss

codeCeiling: .res 2         ; the top of the program's memory
jmpTable: .res JMPTBL_SIZE
fileName: .res 24
pkgIndex: .res 1            ; 0-based package number
pkgBit: .res 1              ; the package's RTF_* bit
pkgPos: .res 1              ; its position: RTF_* bits of those before it
pkgLen: .res 2              ; length of its code
pkgCount: .res 1            ; number of jump table entries in its header
pkgSkips: .res RT_NUM_PKGS  ; for each package, the size of its header
pkgLensL: .res RT_NUM_PKGS  ; and the length of its code
pkgLensH: .res RT_NUM_PKGS
coreLen: .res 2             ; length of the core, after its jump table
readCount: .res 2           ; bytes left for readBytes
hdrBuf: .res 2 + RTH_SIZE   ; a package's header, or runtimeN's
rtSize: .res 2              ; the runtime's size in the PRG
rtSkip: .res 2              ; copyFile: bytes to skip at the file's start
rtLeft: .res 2              ; copyFile: bytes left to copy
rtBlock: .res 1             ; bytes in this block (0 means 256)
rtBuf: .res 256

.code

; This routine reads the runtime's files for the layout and sets
; codeCeiling. The runtime's size is returned in A/X. A missing or bad
; runtime file is errRuntimeFileInvalid, and the carry is set.
.proc layoutRuntime
    lda #<LINK_STATIC_CEILING
    sta codeCeiling
    lda #>LINK_STATIC_CEILING
    sta codeCeiling+1
    lda #<JMPTBL_SIZE
    sta rtSize
    lda #>JMPTBL_SIZE
    sta rtSize+1
    lda objMode
    cmp #RT_MODE_STATIC
    beq :+
    jmp layoutDynamic
:

    ; Read the core's length and jump table
    lda #<coreName
    ldx #>coreName
    jsr startFileName
    jsr endFileName
    jsr openFile
    lda #<coreLen
    sta ptr1
    lda #>coreLen
    sta ptr1+1
    ldx #2
    ldy #0
    jsr readBytes
    bcs ER
    lda #<jmpTable
    sta ptr1
    lda #>jmpTable
    sta ptr1+1
    ldx #<JMPTBL_SIZE
    ldy #>JMPTBL_SIZE
    jsr readBytes
    bcs ER
    jsr closeFile

    ; The rest of the core
    lda coreLen
    sec
    sbc #<JMPTBL_SIZE
    sta coreLen
    lda coreLen+1
    sbc #>JMPTBL_SIZE
    sta coreLen+1
    bcc ER
    lda coreLen
    ldx coreLen+1
    jsr addSize

    ; Patch the jump table for each package the program needs
    jsr firstPackage
L1: bcs DN                      ; Branch if no more packages
    jsr patchJmpTable
    bcs ER
    ldx pkgIndex
    lda pkgLensL,x
    pha
    lda pkgLensH,x
    tax
    pla
    jsr addSize
    jsr nextPackage
    bra L1

DN: lda rtSize
    ldx rtSize+1
    clc
    rts

ER: jmp runtimeFileError
.endproc

; This routine reads runtimeN's header for the layout of a dynamic program:
; rtLow is the ceiling. The size is the jump table and the loader.
.proc layoutDynamic
    lda #<runtimeName
    ldx #>runtimeName
    jsr startFileName
    jsr endFileName
    jsr openFile
    lda #<hdrBuf
    sta ptr1
    lda #>hdrBuf
    sta ptr1+1
    ldx #2 + RTH_SIZE
    ldy #0
    jsr readBytes
    bcs ER
    lda hdrBuf                  ; The load address is rtLow
    cmp hdrBuf + 2 + RTH_LOW
    bne ER
    lda hdrBuf+1
    cmp hdrBuf + 2 + RTH_LOW + 1
    bne ER
    ldx #0                      ; The magic number and the version
:   lda hdrBuf + 2 + RTH_MAGIC,x
    cmp rtMagic,x
    bne ER
    inx
    cpx #5
    bne :-
    jsr closeFile
    lda hdrBuf
    sta codeCeiling
    lda hdrBuf+1
    sta codeCeiling+1
    lda #<LOADER_SIZE
    ldx #>LOADER_SIZE
    jsr addSize
    lda rtSize
    ldx rtSize+1
    clc
    rts

ER: jmp runtimeFileError
.endproc

; This routine reports a missing or bad runtime file. The carry is set.
.proc runtimeFileError
    jsr closeFile
    lda #errRuntimeFileInvalid
    ldx #0
    ldy #0
    jsr compilerError
    sec
    rts
.endproc

; This routine adds A/X to rtSize
.proc addSize
    clc
    adc rtSize
    sta rtSize
    txa
    adc rtSize+1
    sta rtSize+1
    rts
.endproc

; This routine writes the runtime to the PRG, which is the current output.
; A runtime file that's missing or too short, or changed since
; layoutRuntime read it, is errRuntimeFileInvalid, and the carry is set.
.proc writeRuntime
    lda objMode
    cmp #RT_MODE_STATIC
    beq :+
    jmp writeDynamic

    ; The jump table
:   ldx #LFN_PRG
    jsr CHKOUT
    ldx #0
:   lda jmpTable,x
    jsr CHROUT
    inx
    bne :-
:   lda jmpTable+$100,x
    jsr CHROUT
    inx
    cpx #<JMPTBL_SIZE
    bne :-
    .assert >JMPTBL_SIZE = 1, error, "the copy expects one full page"

    ; The rest of the core
    lda #<coreName
    ldx #>coreName
    jsr startFileName
    jsr endFileName
    lda #<(2 + JMPTBL_SIZE)
    sta rtSkip
    lda #>(2 + JMPTBL_SIZE)
    sta rtSkip+1
    lda coreLen
    sta rtLeft
    lda coreLen+1
    sta rtLeft+1
    jsr copyFile
    bcs ER

    ; And each package
    jsr firstPackage
L1: bcs DN                      ; Branch if no more packages
    jsr packageFileName
    ldx pkgIndex
    lda pkgSkips,x
    sta rtSkip
    lda #0
    sta rtSkip+1
    lda pkgLensL,x
    sta rtLeft
    lda pkgLensH,x
    sta rtLeft+1
    jsr copyFile
    bcs ER
    jsr nextPackage
    bra L1

DN: clc
    rts

ER: jmp runtimeFileError
.endproc

; This routine writes a dynamic program's runtime: the empty jump table
; and the loader, which reads the program header's address from its first
; two instructions.
.proc writeDynamic
    ldx #LFN_PRG
    jsr CHKOUT
    lda #<JMPTBL_SIZE
    sta pkgLen
    lda #>JMPTBL_SIZE
    sta pkgLen+1
:   lda #0
    jsr CHROUT
    jsr decPkgLen
    bne :-

    ; The loader, with the program header's address
    lda progBase
    sta loaderStart + LOADER_INIT_L
    lda progBase+1
    sta loaderStart + LOADER_INIT_H
    lda #<loaderStart
    sta ptr1
    lda #>loaderStart
    sta ptr1+1
    lda #<LOADER_SIZE
    sta pkgLen
    lda #>LOADER_SIZE
    sta pkgLen+1
    ldy #0
:   lda (ptr1),y
    jsr CHROUT
    inw ptr1
    jsr decPkgLen
    bne :-
    clc
    rts
.endproc

; This routine starts the runtime packages loop at the first package
; the program needs. The carry is set if there are none.
.proc firstPackage
    lda #0
    sta pkgIndex
    lda #1
    sta pkgBit
    bra findPackage
.endproc

; This routine moves to the next package the program needs. The carry is
; set if there are no more.
.proc nextPackage
    inc pkgIndex
    asl pkgBit
    ; Fall through
.endproc

; This routine looks for a needed package, starting at pkgIndex. The
; carry is set if there are no more. Otherwise pkgPos is set.
.proc findPackage
L1: lda pkgIndex
    cmp #RT_NUM_PKGS
    bcs DN                      ; Branch if no more packages
    lda pkgBit
    and objFeatures
    bne FD                      ; Branch if the program needs this one
    inc pkgIndex
    asl pkgBit
    bra L1
FD: lda pkgBit                  ; The packages before this one
    sec
    sbc #1
    and objFeatures
    sta pkgPos
    clc
DN: rts
.endproc

; This routine puts the current package's variant file name, such as
; "trig1c,p,r", in fileName. Its length is returned in Y.
.proc packageFileName
    ldx pkgIndex
    lda pkgNamesL,x
    pha
    lda pkgNamesH,x
    tax
    pla
    jsr startFileName
    lda #<abiDigits
    ldx #>abiDigits
    jsr addToFileName
    lda pkgPos                  ; The position letter
    clc
    adc #'a'
    sta fileName,y
    iny
    jmp endFileName
.endproc

; This routine opens the current package's variant file, such as trig1c,
; and reads and checks its header. pkgLen and pkgCount are set. The carry
; is set if the file is missing or doesn't match.
.proc openPackage
    jsr packageFileName
    jsr openFile
    lda #<hdrBuf
    sta ptr1
    lda #>hdrBuf
    sta ptr1+1
    ldx #PKG_HEADER_SIZE
    ldy #0
    jsr readBytes
    bcs DN
    ldx pkgIndex                ; Check the package number
    inx
    cpx hdrBuf
    bne BD
    lda pkgPos                  ; and the position
    cmp hdrBuf+1
    bne BD
    lda hdrBuf+2
    sta pkgLen
    lda hdrBuf+3
    sta pkgLen+1
    lda hdrBuf+4
    sta pkgCount
    clc
DN: rts
BD: sec
    rts
.endproc

; This routine patches jmpTable from the current package's header, and
; saves the header's size and the package's length for writeRuntime. The
; carry is set if the file is missing or bad.
.proc patchJmpTable
    jsr openPackage
    bcs DN
    ldx pkgIndex
    lda pkgLen
    sta pkgLensL,x
    lda pkgLen+1
    sta pkgLensH,x
    lda pkgCount                ; The header is 5 + 3 * count bytes
    cmp #(256 - PKG_HEADER_SIZE) / 3
    bcs DN                      ; Branch if too many entries (carry set)
    sta tmp1
    asl a
    adc tmp1
    adc #PKG_HEADER_SIZE
    sta pkgSkips,x
    lda pkgCount
    beq CL
L1: lda #<hdrBuf                ; Read the next entry
    sta ptr1
    lda #>hdrBuf
    sta ptr1+1
    ldx #3
    ldy #0
    jsr readBytes
    bcs DN
    lda hdrBuf                  ; Entry number
    cmp #JMPTBL_SIZE / 3
    bcs DN                      ; Branch if past the table (carry set)
    ; ptr1 = jmpTable + entry * 3 + 1 (the JMP's operand)
    sta ptr1
    lda #0
    sta ptr1+1
    lda ptr1
    asl a
    rol ptr1+1
    clc
    adc ptr1
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    lda ptr1
    clc
    adc #<(jmpTable + 1)
    sta ptr1
    lda ptr1+1
    adc #>(jmpTable + 1)
    sta ptr1+1
    ldy #0
    lda hdrBuf+1
    sta (ptr1),y
    iny
    lda hdrBuf+2
    sta (ptr1),y
    dec pkgCount
    bne L1
CL: jsr closeFile
    clc
DN: rts
.endproc

; This routine decrements pkgLen. Z is set if it's then zero.
.proc decPkgLen
    lda pkgLen
    bne :+
    dec pkgLen+1
:   dec pkgLen
    lda pkgLen
    ora pkgLen+1
    rts
.endproc

; This routine reads X/Y (low/high) bytes from the runtime file to ptr1.
; The carry is set if the file ends before the last one, or on a read
; error.
.proc readBytes
    stx readCount
    sty readCount+1
    txa
    ora readCount+1
    beq OK
    ldx #LFN_RT
    jsr CHKIN
L1: jsr CHRIN
    ldy #0
    sta (ptr1),y
    inw ptr1
    lda STATUS
    sta tmp1
    lda readCount               ; Decrement the count
    bne :+
    dec readCount+1
:   dec readCount
    lda readCount
    ora readCount+1
    beq LS                      ; Branch if that was the last byte
    lda tmp1
    bne BD                      ; Branch if the file ended early
    bra L1
LS: lda tmp1                    ; EOF on the last byte is fine
    and #$bf
    bne BD
OK: clc
    rts
BD: sec
    rts
.endproc

; This routine copies the runtime file named in fileName (Y characters)
; into the PRG: it skips rtSkip bytes, then copies rtLeft. The carry is set
; if the file is missing or too short.
.proc copyFile
    jsr openFile
L1: lda rtSkip
    ora rtSkip+1
    beq L2
    jsr CHRIN
    lda STATUS
    bne ER                      ; The file is missing or too short
    lda rtSkip
    bne :+
    dec rtSkip+1
:   dec rtSkip
    bra L1

L2: lda rtLeft
    ora rtLeft+1
    beq CL                      ; Branch if all of it is copied
    jsr copyBlock
    bcc L2

ER: jsr closeFile
    sec
    rts
CL: jsr closeFile
    clc
    rts
.endproc

; This routine copies the next block of the runtime file, up to 256 bytes
; of rtLeft, and subtracts it from rtLeft. The bytes are copied in blocks so
; the input and output channels change once a block rather than once a
; byte. The carry is set if the file ends early or fails.
.proc copyBlock
    lda rtLeft+1
    beq :+
    lda #0                      ; A whole page
    bra :++
:   lda rtLeft
:   sta rtBlock
    ldx #LFN_RT
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

    ldx #LFN_PRG
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

; This routine starts fileName with the null-terminated string in A/X.
; Y is returned as the length.
.proc startFileName
    ldy #0
    ; Fall through
.endproc

; This routine adds the null-terminated string in A/X to fileName at Y.
; Y is returned as the new length.
.proc addToFileName
    sta ptr2
    stx ptr2+1
    ldx #0
:   phy
    txa
    tay
    lda (ptr2),y
    ply
    cmp #0
    beq :+
    sta fileName,y
    iny
    inx
    bne :-
:   rts
.endproc

; This routine ends fileName at Y with ",p,r". Y is returned as the length.
.proc endFileName
    lda #<fileSuffix
    ldx #>fileSuffix
    jmp addToFileName
.endproc

; This routine opens the runtime file named in fileName (Y characters) and
; makes it the input
.proc openFile
    sty tmp1
    ldx DEVNUM
    lda #LFN_RT
    tay
    jsr SETLFS
    lda tmp1
    ldx #<fileName
    ldy #>fileName
    jsr SETNAM
    jsr OPEN
    ldx #LFN_RT
    jmp CHKIN
.endproc

; This routine closes the runtime file and goes back to the default input.
; The PRG stays the output.
.proc closeFile
    lda #LFN_RT
    jsr CLOSE
    ldx #0
    jmp CHKIN
.endproc
