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
.include "zeropage.inc"
.include "4510macros.inc"
.include "cbm_kernal.inc"
.include "error.inc"
.include "icode.inc"

.export genObjCode, deleteIfExists
.export genThreeAddr, runtimeStackSize
.export genOneInstruction, genTwoInstruction, incCodeOffset, calcNamePtr

.import writePrgHeader, processIcodeInstructions, prgCleanup
.import initStringLiterals, writeStringLiterals, freeStringLiterals
.import cleanupLibraries, readIcodeImports, initImports, freeImports
.import readIcodeFrames, initFrames, freeFrames
.import initDataSegment, writeDataSegment, freeDataSegment
.import tagBSS_EXITHANDLER
.import writeObjFile, objFilename, codeFilename, readIcodeHeader
.import readUnitHeader, skipIcodeImports, unitCount, getImportUnit
.import beginUnitFrames, endUnitFrames, setRuntimeFeatures
.import isImportTpu, readIcodeByte, initExports, freeExports, setObjModule
.import modName, nameBuf, nameLen

.data

icodeFn: .asciiz "zztmpicode"
unitPrefix: .asciiz ICODE_UNIT_PREFIX
strSeqRead: .asciiz ",s,r"
strTpuSuffix: .asciiz ".tpu"
strObjSuffix: .asciiz ".obj"

tempFn: .byte "zztmpicode,s,r"
tempFn2:

; The code is written to this file, then copied into the object file
; (writeObjFile)
codeFn: .byte "zzcode,s,w"
codeFn2:

.bss

runtimeStackSize: .res 2
delName: .res 2             ; for deleteIfExists
unitIdx: .res 1             ; the unit whose icode file is read
unitFn: .res 24             ; its name, then ",s,r"
unitFnLen: .res 1           ; the name's length, without ",s,r"
unitFnTotal: .res 1
skipLeft: .res 2            ; for skipToIcode
skipCount: .res 1
objName: .res 17           ; a unit's object file: its name, then ".obj"

.code

; The icode files hold everything code generation needs: each module's
; header, imports and frames tables and code (icode.inc). It doesn't use
; the AST. Each module gets its own object file (linker.inc): the
; program's (zztmp), then each Pascal unit's (<unit>.obj), in the order
; the program's imports list them (genUnits). The linker links them.
.proc genObjCode
    jsr initImports
    jsr initFrames
    jsr initExports
    lda #0
    sta unitCount               ; for badIcode, until the imports are read

    ; Delete the object file and the code file if they exist
    lda #<objFilename
    ldx #>objFilename
    jsr deleteIfExists
    lda #<codeFilename
    ldx #>codeFilename
    jsr deleteIfExists

    jsr startModule

    ; Open the icode file and read its header: the runtime mode and
    ; stack size and the module's name (icode.inc)
    ; Call SETLFS
    ldx DEVNUM
    lda #2
    tay
    iny
    jsr SETLFS
    ; Call SETNAM
    ldx #<tempFn
    ldy #>tempFn
    lda #tempFn2-tempFn
    jsr SETNAM
    ; Open the file
    jsr OPEN
    jsr readIcodeHeader
    bcs :+
    jsr readIcodeImports
    bcs :+
    jsr readIcodeFrames
    bcc :++
:   jmp badIcode

:   jsr writePrgHeader

    jsr processIcodeInstructions

    ; User code is written.

    ; Clean up the libraries. A runtime error (exit in the runtime) comes
    ; here too, so the libraries clean up after it.
    lda #<tagBSS_EXITHANDLER
    ldx #>tagBSS_EXITHANDLER
    jsr linkAddressSet
    jsr cleanupLibraries

    ; Add some code to clean up the runtime and return to BASIC.
    jsr prgCleanup

    ; The program's object file
    lda #2
    jsr CLOSE
    lda #<objFilename
    ldx #>objFilename
    ldy #$ff
    jsr finishModule

    ; Each Pascal unit's, from its own icode file
    jsr genUnits
    bcc :+
    jmp badIcode

:   jsr freeImports

    ; Delete the icode files. Not before: deleting a file closes every
    ; open file (it closes the drive's command channel).
    jmp deleteIcode
.endproc

; This routine starts a module's object code: no linker tags, literals,
; data segments or exports, code offset 0 and the runtime features its EOM
; adds. It opens the code file, zzcode, as the output.
.proc startModule
    lda #0
    jsr setRuntimeFeatures      ; the module's EOM adds its own
    jsr initLinkerTags
    jsr initStringLiterals
    jsr initDataSegment
    lda #0
    sta codeOffset
    sta codeOffset+1

    ; Open the code file
    ; Call SETLFS
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ; Call SETNAM
    ldx #<codeFn
    ldy #>codeFn
    lda #codeFn2-codeFn
    jsr SETNAM
    ; Open the file and set output channel
    jsr OPEN
    ldx #1
    jmp CHKOUT
.endproc

; This routine finishes a module's object code and writes its object file,
; named at A/X (null-terminated). Y is $FF for the program or the unit's
; number from 0 (setObjModule). The string literals and the data segments
; follow the code. The linker puts the runtime's BSS after the modules.
.proc finishModule
    jsr setObjModule

    jsr writeStringLiterals

    jsr freeStringLiterals

    jsr writeDataSegment

    jsr freeDataSegment

    ; Close the code file
    lda #1
    jsr CLOSE
    jsr CLRCHN

    ; Write the object file. It deletes the code file and frees the linker
    ; tags and the exports.
    jmp writeObjFile
.endproc

; This routine deletes the program's icode file and each unit's
.proc deleteIcode
    lda #<icodeFn
    ldx #>icodeFn
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile
    lda #0
    sta unitIdx
L1: lda unitIdx
    cmp unitCount
    bne :+
    rts
:   lda unitIdx                 ; a unit's TPU is kept
    jsr isImportTpu
    bne NX
    jsr unitFileName
    lda #<unitFn
    ldx #>unitFn
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile
NX: inc unitIdx
    bra L1
.endproc

; This routine puts the name of the icode file of the unit numbered
; unitIdx in unitFn, null-terminated, and its length in unitFnLen:
; ICODE_UNIT_PREFIX, then the unit's name. A unit whose code is in its TPU
; (ICODE_IMPORT_TPU) has the TPU's: its name, then ".tpu".
.proc unitFileName
    lda unitIdx
    jsr isImportTpu
    bne TP
    lda unitIdx
    jsr getImportUnit
    sta ptr1
    stx ptr1+1
    ldx #0
:   lda unitPrefix,x
    beq :+
    sta unitFn,x
    inx
    bra :-
:   ldy #0
:   lda (ptr1),y
    sta unitFn,x
    beq :+
    inx
    iny
    bra :-
:   stx unitFnLen
    rts

TP: lda unitIdx
    jsr getImportUnit
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    sta unitFn,y
    iny
    bra :-
:   ldx #0
:   lda strTpuSuffix,x
    sta unitFn,y
    beq :+
    iny
    inx
    bra :-
:   sty unitFnLen
    rts
.endproc

; This routine generates the code of each Pascal unit the program's
; imports table lists, from the unit's own icode file or its TPU's icode
; section (icode.inc), in the table's order, and writes its object file,
; <unit>.obj. Code names other modules' entries and libraries' slots by
; name, so a unit's imports table is skipped. Its frames table numbers the
; frames its operands name. deleteIcode deletes the icode files.
; The carry is set if a file can't be read: the file is left open on 2.
.proc genUnits
    lda #0
    sta unitIdx
L1: lda unitIdx
    cmp unitCount
    bne :+
    clc
    rts

:   jsr startModule
    jsr unitFileName

    ; Open it with ",s,r"
    ldx unitFnLen
    ldy #0
:   lda strSeqRead,y
    sta unitFn,x
    beq :+
    inx
    iny
    bra :-
:   stx unitFnTotal
    ldx DEVNUM
    lda #2
    tay
    iny
    jsr SETLFS
    lda unitFnTotal
    ldx #<unitFn
    ldy #>unitFn
    jsr SETNAM
    jsr OPEN
    lda unitIdx                 ; a TPU's icode is its last section
    jsr isImportTpu
    beq :+
    jsr skipToIcode

:   jsr readUnitHeader
    bcs BD

    ; The module's name, for the object file
    ldx #0
:   lda modName,x
    beq :+
    sta nameBuf,x
    inx
    bra :-
:   stx nameLen

    jsr skipIcodeImports
    bcs BD
    jsr beginUnitFrames
    jsr readIcodeFrames
    bcs BF

    jsr processIcodeInstructions
    jsr endUnitFrames
    lda #2
    jsr CLOSE

    ; Its object file
    jsr unitObjName
    lda #<objName
    ldx #>objName
    ldy unitIdx
    jsr finishModule

    inc unitIdx
    jmp L1

BF: jsr endUnitFrames
BD: sec
    rts
.endproc

; This routine puts the name of the object file of the unit numbered
; unitIdx in objName: the unit's name, then ".obj"
.proc unitObjName
    lda unitIdx
    jsr getImportUnit
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    sta objName,y
    iny
    bra :-
:   ldx #0
:   lda strObjSuffix,x
    sta objName,y
    beq :+
    iny
    inx
    bra :-
:   rts
.endproc

; This routine reads a TPU (tpu.inc), open on 2, to its icode section's
; first byte: past its header, the units it uses, its interface section
; and the icode section's length. The icode's header checks the rest.
.proc skipToIcode
    ldx #9                      ; the magic to the interface's CRC
:   jsr readIcodeByte
    dex
    bne :-
    jsr readIcodeByte           ; the units it uses: names and CRCs
    sta skipCount
L1: lda skipCount
    beq IN
    dec skipCount
    jsr readIcodeByte
    clc
    adc #2
    tax
:   jsr readIcodeByte
    dex
    bne :-
    bra L1

IN: jsr readIcodeByte           ; the interface section
    sta skipLeft
    jsr readIcodeByte
    sta skipLeft+1
L2: lda skipLeft
    ora skipLeft+1
    beq CD
    jsr readIcodeByte
    lda skipLeft
    bne :+
    dec skipLeft+1
:   dec skipLeft
    bra L2

CD: jsr readIcodeByte           ; the icode section's length
    jmp readIcodeByte
.endproc

; This routine deletes the file named in A/X if it exists
.proc deleteIfExists
    sta delName
    stx delName+1
    ldy #0
    ldz #0
    jsr doesFileExist
    beq :+
    lda delName
    ldx delName+1
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile
:   rts
.endproc

; This routine reports an icode file code generation can't read: not icode,
; another version, or not a program. It closes the files, deletes the code
; file and every object file written, and frees what genObjCode set up.
.proc badIcode
    lda #2
    jsr CLOSE
    lda #1
    jsr CLOSE
    jsr CLRCHN
    lda #<codeFilename
    ldx #>codeFilename
    jsr deleteIfExists
    lda #<objFilename
    ldx #>objFilename
    jsr deleteIfExists
    lda #0
    sta unitIdx
L1: lda unitIdx
    cmp unitCount
    beq :+
    jsr unitObjName
    lda #<objName
    ldx #>objName
    jsr deleteIfExists
    inc unitIdx
    bra L1
:   jsr freeStringLiterals
    jsr freeDataSegment
    jsr freeLinkerTags
    jsr freeImports
    jsr freeFrames
    jsr freeExports
    lda #errIcodeFileInvalid
    ldx #0
    ldy #0
    jmp compilerError
.endproc

.proc genOneInstruction
    pha
    ldx #1
    jsr CHKOUT
    pla
    jsr CHROUT
    lda #1
    jmp incCodeOffset
.endproc

.proc genTwoInstruction
    phx
    pha
    ldx #1
    jsr CHKOUT
    pla
    jsr CHROUT
    pla
    jsr CHROUT

    lda #2
    jmp incCodeOffset
.endproc

.proc genThreeAddr
    phy
    phx
    pha
    ldx #1
    jsr CHKOUT
    pla
    jsr CHROUT
    pla
    jsr CHROUT
    pla
    jsr CHROUT

    lda #3
    jmp incCodeOffset
.endproc

.proc incCodeOffset
    clc
    adc codeOffset
    sta codeOffset
    lda codeOffset+1
    adc #0
    sta codeOffset+1
    rts
.endproc

; Structure pointer in A/X/Y and structure offset in Z.
; Address returned in Q.
.proc calcNamePtr
    stz intOp32
    ldz #0
    stz intOp32+1
    stz intOp32+2
    stz intOp32+3
    clc
    adcq intOp32
    rts
.endproc
