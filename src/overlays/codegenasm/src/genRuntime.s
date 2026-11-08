;
; genRuntime.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; genRuntime routine
;
; A program either has the runtime linked into it (static mode, chosen by
; $StaticRuntime) or loads it when it runs (dynamic mode, the default).
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
; genRuntime reads the core's jump table, patches it from the header of
; each package the program needs and writes it. The rest of the runtime
; isn't written to the object file. A LINKADDR_RUNTIME tag marks where it
; goes, and a list of the files to copy follows it (see linker.inc). The
; linker copies them straight into the PRG.
;
; Dynamic mode: genRuntime writes an empty jump table and the loader
; (loader.s) after it. The loader fills the jump table at run time. The
; header of runtimeN gives rtLow, which takes the place of $C000 as the
; ceiling for the program, its heap and its stack.

.include "c64.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "asm.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "error.inc"

JMPTBL_SIZE = $156
PKG_HEADER_SIZE = 5         ; header size, before the entry list
CODESEG_CEIL = $c000        ; the ceiling for a static program

LFN_CORE = 2                ; logical file numbers
LFN_PKG = 3
LFN_OBJ = 1                 ; the object file, opened by genObjCode

.export genRuntime, setRuntimeFeatures, setRuntimeMode
.export runtimeMode, codeCeiling

.import incCodeOffset
.import loaderStart, LOADER_SIZE, LOADER_INIT_L: zp, LOADER_INIT_H: zp

.data

coreName: .asciiz .sprintf("core%d", RT_ABI_VERSION)
runtimeName: .asciiz .sprintf("runtime%d", RT_ABI_VERSION)
abiDigits: .asciiz .sprintf("%d", RT_ABI_VERSION)
fileSuffix: .asciiz ",p,r"
tagInit: .asciiz "init"
tagRuntime: .asciiz "rtcopy"
rtMagic: .byte RTH_MAGIC0, RTH_MAGIC1, RTH_MAGIC2, RTH_MAGIC3, RT_ABI_VERSION

; Package file name prefixes, in package order (RT_PKG_* in asm.inc)
pkgDynArrays: .asciiz "dynarrays"
pkgFiles: .asciiz "files"
pkgTrig: .asciiz "trig"
pkgNamesL: .byte <pkgDynArrays, <pkgFiles, <pkgTrig
pkgNamesH: .byte >pkgDynArrays, >pkgFiles, >pkgTrig

.bss

runtimeFeatures: .res 1     ; RTF_* (asm.inc) for the packages to link
runtimeMode: .res 1         ; RT_MODE_* (asm.inc)
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
numFiles: .res 1            ; files the linker copies
coreLen: .res 2             ; length of the core file, after its length
readCount: .res 2           ; bytes left for readBytes
hdrBuf: .res 2 + RTH_SIZE   ; a package's header, or runtimeN's

.code

; This routine sets the runtime features (RTF_* in asm.inc) in A. Code
; generation links the runtime packages for them. A build with ALLPKGS
; defined (make ALLPKGS=1) links every package, for debugging.
.proc setRuntimeFeatures
.ifdef ALLPKGS
    lda #RTF_ALL
.endif
    sta runtimeFeatures
    rts
.endproc

; This routine sets the runtime mode (RT_MODE_* in asm.inc) in A
.proc setRuntimeMode
    sta runtimeMode
    rts
.endproc

; This routine writes the runtime, or the loader, to the object file and
; sets codeCeiling. A missing or bad runtime file is a compiler error.
.proc genRuntime
    lda #<CODESEG_CEIL
    sta codeCeiling
    lda #>CODESEG_CEIL
    sta codeCeiling+1
    lda runtimeMode
    cmp #RT_MODE_STATIC
    beq :+
    jmp genDynamic
:

    ; Open the core
    lda #<coreName
    ldx #>coreName
    jsr startFileName
    jsr endFileName
    lda #LFN_CORE
    jsr openFile

    ; Read its length and the jump table
    ldx #LFN_CORE
    jsr CHKIN
    lda #<coreLen
    sta ptr1
    lda #>coreLen
    sta ptr1+1
    ldx #2
    ldy #0
    jsr readBytes
    bcc :+
    jmp runtimeFileError
:
    lda #<jmpTable
    sta ptr1
    lda #>jmpTable
    sta ptr1+1
    ldx #<JMPTBL_SIZE
    ldy #>JMPTBL_SIZE
    jsr readBytes
    bcc :+
    jmp runtimeFileError
:
    lda #LFN_CORE
    jsr CLOSE

    ; The rest of the core
    lda coreLen
    sec
    sbc #<JMPTBL_SIZE
    sta coreLen
    lda coreLen+1
    sbc #>JMPTBL_SIZE
    sta coreLen+1
    bcs :+
    jmp runtimeFileError
:

    ; Patch the jump table for each package the program needs
    lda #1
    sta numFiles
    jsr firstPackage
L1: bcs L2                      ; Branch if no more packages
    jsr patchJmpTable
    bcc :+
    jmp runtimeFileError
:
    inc numFiles
    jsr nextPackage
    bra L1

    ; Write the jump table
L2: ldx #LFN_OBJ
    jsr CHKOUT
    lda #<jmpTable
    sta ptr1
    lda #>jmpTable
    sta ptr1+1
    lda #<JMPTBL_SIZE
    sta pkgLen
    lda #>JMPTBL_SIZE
    sta pkgLen+1
    jsr writeOut

    ; The linker copies the rest here
    lda #<tagRuntime
    ldx #>tagRuntime
    jsr linkAddressSet
    lda #<tagRuntime
    ldx #>tagRuntime
    ldy #LINKADDR_RUNTIME
    ldz #0
    jsr linkAddressLookup

    ; Then the list of files for it to copy, starting with the core
    ldx #LFN_OBJ
    jsr CHKOUT
    lda numFiles
    jsr CHROUT
    lda #<coreName
    ldx #>coreName
    jsr startFileName
    jsr endFileName
    lda #<(2 + JMPTBL_SIZE)
    ldx #>(2 + JMPTBL_SIZE)
    jsr writeEntryHead
    lda coreLen
    ldx coreLen+1
    jsr writeEntryLen

    ; And each package
    jsr firstPackage
L3: bcs DN                      ; Branch if no more packages
    jsr packageFileName
    ldx pkgIndex
    lda pkgSkips,x
    ldx #0
    jsr writeEntryHead
    ldx pkgIndex
    lda pkgLensL,x
    pha
    lda pkgLensH,x
    tax
    pla
    jsr writeEntryLen
    jsr nextPackage
    bra L3

DN: jmp finish

    ; A runtime file is missing or bad
ER: jmp runtimeFileError
.endproc

; This routine writes the runtime for dynamic mode: an empty jump table and
; the loader. codeCeiling is set to rtLow from runtimeN's header.
.proc genDynamic
    ; Read runtimeN's load address and header, and check them
    lda #<runtimeName
    ldx #>runtimeName
    jsr startFileName
    jsr endFileName
    lda #LFN_CORE
    jsr openFile
    ldx #LFN_CORE
    jsr CHKIN
    lda #<hdrBuf
    sta ptr1
    lda #>hdrBuf
    sta ptr1+1
    ldx #2 + RTH_SIZE
    ldy #0
    jsr readBytes
    bcc :+
    jmp runtimeFileError
:
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
    lda #LFN_CORE
    jsr CLOSE
    lda hdrBuf
    sta codeCeiling
    lda hdrBuf+1
    sta codeCeiling+1

    ; The jump table, which the loader fills
    ldx #LFN_OBJ
    jsr CHKOUT
    lda #<JMPTBL_SIZE
    sta pkgLen
    lda #>JMPTBL_SIZE
    sta pkgLen+1
:   lda #0
    jsr CHROUT
    jsr decPkgLen
    bne :-
    lda #<JMPTBL_SIZE
    ldx #>JMPTBL_SIZE
    jsr addCodeOffset

    ; The loader, which needs the program header's address
    lda #<tagInit
    ldx #>tagInit
    ldy #LINKADDR_LOW
    ldz #LOADER_INIT_L
    jsr linkAddressLookup
    lda #<tagInit
    ldx #>tagInit
    ldy #LINKADDR_HIGH
    ldz #LOADER_INIT_H
    jsr linkAddressLookup
    ldx #LFN_OBJ
    jsr CHKOUT
    lda #<loaderStart
    sta ptr1
    lda #>loaderStart
    sta ptr1+1
    lda #<LOADER_SIZE
    sta pkgLen
    lda #>LOADER_SIZE
    sta pkgLen+1
    jsr writeOut
    jmp finish

ER: jmp runtimeFileError
.endproc

; This routine reports a missing or bad runtime file
.proc runtimeFileError
    lda #errRuntimeFileInvalid
    ldx #0
    ldy #0
    jsr compilerError
    lda #LFN_CORE
    jsr CLOSE
    lda #LFN_PKG
    jsr CLOSE
    ; Fall through
.endproc

.proc finish
    ldx #0
    jsr CHKIN
    ldx #LFN_OBJ
    jmp CHKOUT
.endproc

; This routine writes pkgLen bytes from ptr1 to the object file, which must
; be the current output, and adds them to codeOffset.
.proc writeOut
    lda pkgLen
    ldx pkgLen+1
    jsr addCodeOffset
:   ldy #0
    lda (ptr1),y
    jsr CHROUT
    inw ptr1
    jsr decPkgLen
    bne :-
    rts
.endproc

; This routine adds A/X to codeOffset
.proc addCodeOffset
    clc
    adc codeOffset
    sta codeOffset
    txa
    adc codeOffset+1
    sta codeOffset+1
    rts
.endproc

; This routine starts an entry in the list of files for the linker to copy:
; the length of the name in fileName (Y), the name, and the number of bytes
; to skip at the start of the file (A/X).
.proc writeEntryHead
    pha
    phx
    sty tmp1
    ldx #LFN_OBJ
    jsr CHKOUT
    lda tmp1
    jsr CHROUT
    ldx #0
:   lda fileName,x
    jsr CHROUT
    inx
    cpx tmp1
    bne :-
    plx
    pla
    jsr CHROUT
    txa
    jmp CHROUT
.endproc

; This routine ends an entry in the list of files for the linker to copy
; with the number of bytes to copy (A/X), and adds them to codeOffset.
.proc writeEntryLen
    pha
    phx
    jsr CHROUT
    txa
    jsr CHROUT
    plx
    pla
    jmp addCodeOffset
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
    and runtimeFeatures
    bne FD                      ; Branch if the program needs this one
    inc pkgIndex
    asl pkgBit
    bra L1
FD: lda pkgBit                  ; The packages before this one
    sec
    sbc #1
    and runtimeFeatures
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
    lda #LFN_PKG
    jsr openFile

    ldx #LFN_PKG
    jsr CHKIN
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
; saves the header's size and the package's length for the linker. The
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
CL: lda #LFN_PKG
    jsr CLOSE
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

; This routine reads X/Y (low/high) bytes from the current input to ptr1.
; The carry is set if the file ends before the last one, or on a read
; error.
.proc readBytes
    stx readCount
    sty readCount+1
    txa
    ora readCount+1
    beq OK
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

; This routine opens the file named in fileName (Y characters) as the
; logical file in A. The secondary address is the file number plus one.
.proc openFile
    sty tmp1
    pha
    tay
    iny
    pla
    ldx DEVNUM
    jsr SETLFS
    lda tmp1
    ldx #<fileName
    ldy #>fileName
    jsr SETNAM
    jmp OPEN
.endproc
