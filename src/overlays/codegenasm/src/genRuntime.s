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
; The runtime is a core, which every program gets, and packages, which a
; program gets only if it uses their feature (see rtpkg.inc). The core file
; (coreN) is the jump table, then the core's code, data and BSS. Each
; package follows the core, in package order, so its address depends on
; which packages before it are linked. There is one variant file of each
; package for each address, such as trig1c, and each starts with a header
; listing the jump table entries to point at the package's routines.
;
; genRuntime reads the core's jump table, patches it from the header of
; each package the program needs, writes it, copies the rest of the core,
; then copies each package's code.

.include "c64.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "asm.inc"
.include "asmlib.inc"
.include "error.inc"

JMPTBL_SIZE = $156
PKG_HEADER_SIZE = 5         ; header size, before the entry list

LFN_CORE = 2                ; logical file numbers
LFN_PKG = 3
LFN_OBJ = 1                 ; the object file, opened by genObjCode

.export genRuntime, setRuntimeFeatures

.import incCodeOffset

.data

coreName: .asciiz .sprintf("core%d", RT_ABI_VERSION)
abiDigits: .asciiz .sprintf("%d", RT_ABI_VERSION)
fileSuffix: .asciiz ",p,r"

; Package file name prefixes, in package order (RT_PKG_* in asm.inc)
pkgDynArrays: .asciiz "dynarrays"
pkgFiles: .asciiz "files"
pkgTrig: .asciiz "trig"
pkgNamesL: .byte <pkgDynArrays, <pkgFiles, <pkgTrig
pkgNamesH: .byte >pkgDynArrays, >pkgFiles, >pkgTrig

.bss

runtimeFeatures: .res 1     ; RTF_* (asm.inc) for the packages to link
jmpTable: .res JMPTBL_SIZE
fileName: .res 24
pkgIndex: .res 1            ; 0-based package number
pkgBit: .res 1              ; the package's RTF_* bit
pkgPos: .res 1              ; its position: RTF_* bits of those before it
pkgLen: .res 2              ; length of its code
pkgCount: .res 1            ; number of jump table entries in its header
readCount: .res 2           ; bytes left for readBytes
hdrBuf: .res PKG_HEADER_SIZE

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

.proc genRuntime
    ; Open the core
    lda #<coreName
    ldx #>coreName
    jsr startFileName
    jsr endFileName
    lda #LFN_CORE
    jsr openFile

    ; Discard the starting address
    ldx #LFN_CORE
    jsr CHKIN
    jsr CHRIN
    jsr CHRIN

    ; Read the jump table
    lda #<jmpTable
    sta ptr1
    lda #>jmpTable
    sta ptr1+1
    ldx #<JMPTBL_SIZE
    ldy #>JMPTBL_SIZE
    jsr readBytes
    bcc :+
    jmp ER

    ; Patch it for each package the program needs
:   jsr firstPackage
L1: bcs L2                      ; Branch if no more packages
    jsr patchJmpTable
    bcc :+
    jmp ER
:   jsr nextPackage
    bra L1

    ; Write the jump table
L2: lda #<jmpTable
    sta ptr1
    lda #>jmpTable
    sta ptr1+1
    lda #<JMPTBL_SIZE
    sta pkgLen
    lda #>JMPTBL_SIZE
    sta pkgLen+1
    ldx #LFN_OBJ
    jsr CHKOUT
:   ldy #0
    lda (ptr1),y
    jsr CHROUT
    lda #1
    jsr incCodeOffset
    inw ptr1
    jsr decPkgLen
    bne :-

    ; Copy the rest of the core: its code, data and BSS. The KERNAL
    ; returns the file's last byte with EOF set, so it's copied too.
L3: ldx #LFN_CORE
    jsr CHKIN
    jsr CHRIN
    pha
    lda STATUS
    sta tmp1
    ldx #LFN_OBJ
    jsr CHKOUT
    pla
    jsr CHROUT
    lda #1
    jsr incCodeOffset
    lda tmp1
    beq L3                      ; Branch if not at the end yet
    and #$bf
    bne ER                      ; Branch if a read error
    lda #LFN_CORE
    jsr CLOSE

    ; Copy each package's code
    jsr firstPackage
L4: bcs DN                      ; Branch if no more packages
    jsr copyPackage
    bcs ER
    jsr nextPackage
    bra L4

DN: jmp finish

    ; A runtime file is missing or bad
ER: lda #errRuntimeFileInvalid
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

; This routine opens the current package's variant file, such as trig1c,
; and reads and checks its header. pkgLen and pkgCount are set. The carry
; is set if the file is missing or doesn't match.
.proc openPackage
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
    jsr endFileName
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

; This routine patches jmpTable from the current package's header. The
; carry is set if the file is missing or bad.
.proc patchJmpTable
    jsr openPackage
    bcs DN
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

; This routine copies the current package's code to the object file. The
; carry is set if the file is missing or bad.
.proc copyPackage
    jsr openPackage
    bcs DN
    ; Skip the jump table entries
L1: lda pkgCount
    beq L2
    lda #<hdrBuf
    sta ptr1
    lda #>hdrBuf
    sta ptr1+1
    ldx #3
    ldy #0
    jsr readBytes
    bcs DN
    dec pkgCount
    bra L1
    ; Copy the code
L2: lda pkgLen
    ora pkgLen+1
    beq CL
L3: ldx #LFN_PKG
    jsr CHKIN
    jsr CHRIN
    pha
    lda STATUS
    sta tmp1
    ldx #LFN_OBJ
    jsr CHKOUT
    pla
    jsr CHROUT
    lda #1
    jsr incCodeOffset
    jsr decPkgLen
    beq CL                      ; Branch if that was the last byte
    lda tmp1
    bne BD                      ; Branch if the file ended early
    bra L3
CL: lda #LFN_PKG
    jsr CLOSE
    clc
DN: rts
BD: sec
    rts
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
