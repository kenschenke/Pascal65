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

.export genObjCode
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
.import beginUnitFrames, endUnitFrames, setRuntimeFeatures, labelScope

.data

icodeFn: .asciiz "zztmpicode"
unitPrefix: .asciiz ICODE_UNIT_PREFIX
strSeqRead: .asciiz ",s,r"

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

.code

; The icode files hold everything code generation needs: each module's
; header, imports and frames tables and code (icode.inc). It reads the
; program's, then each Pascal unit's (genUnits). It doesn't use the AST.
.proc genObjCode
    jsr initImports
    jsr initFrames
    lda #0
    jsr setRuntimeFeatures      ; each module's EOM adds its own
    lda #0
    sta labelScope              ; the program's labels are unchanged

    ; Initialize the linkerTags and tagsToFind containers.
    jsr initLinkerTags

    jsr initStringLiterals

    jsr initDataSegment

    lda #0
    sta codeOffset
    sta codeOffset+1

    ; Delete the object file and the code file if they exist
    lda #<objFilename
    ldx #>objFilename
    jsr deleteIfExists
    lda #<codeFilename
    ldx #>codeFilename
    jsr deleteIfExists

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
    jsr CHKOUT

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

    ; The program's icode is done. Each Pascal unit's code, in its own
    ; icode file, follows the cleanup, which never falls through.
    lda #2
    jsr CLOSE
    jsr genUnits
    bcc :+
    jmp badIcode
:

    jsr writeStringLiterals

    jsr freeStringLiterals

    jsr writeDataSegment

    jsr freeDataSegment

    ; The linker puts the runtime's BSS after the program

    ldx #0
    jsr CHKIN

    ; Close the code file
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKOUT

    lda #1
    jsr CLOSE
    lda #2
    jsr CLOSE
    jsr CLRCHN

    ; Delete the icode files. Not before: deleting a file closes every
    ; open file (it closes the drive's command channel).
    jsr deleteIcode

    ; Write the object file. It frees the linker tags. The linker lays
    ; out the program and checks that it fits in memory.
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
:   jsr unitFileName
    lda #<unitFn
    ldx #>unitFn
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile
    inc unitIdx
    bra L1
.endproc

; This routine puts the name of the icode file of the unit numbered
; unitIdx in unitFn, null-terminated, and its length in unitFnLen:
; ICODE_UNIT_PREFIX, then the unit's name.
.proc unitFileName
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
.endproc

; This routine generates the code of each Pascal unit the program's
; imports table lists (ICODE_IMPORT_UNIT), from the unit's own icode file
; (icode.inc), in the table's order. A unit's imports are the program's
; too, so they're skipped, and its frames are read in place of the
; program's while its code is generated. deleteIcode deletes the files.
; The carry is set if a file can't be read: the file is left open on 2.
.proc genUnits
    lda #0
    sta unitIdx
L1: lda unitIdx
    cmp unitCount
    bne :+
    clc
    rts

:   jsr unitFileName

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

    jsr readUnitHeader
    bcs BD
    jsr skipIcodeImports
    bcs BD
    jsr beginUnitFrames
    jsr readIcodeFrames
    bcs BF

    ; Its labels are its own (readOperand.s): its number from 1
    ldx unitIdx
    inx
    stx labelScope
    jsr processIcodeInstructions
    lda #0
    sta labelScope
    jsr endUnitFrames
    lda #2
    jsr CLOSE

    inc unitIdx
    jmp L1

BF: jsr endUnitFrames
BD: sec
    rts
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
; file and frees what genObjCode set up. No object file is written.
.proc badIcode
    lda #2
    jsr CLOSE
    lda #1
    jsr CLOSE
    jsr CLRCHN
    lda #<codeFilename
    ldx #>codeFilename
    jsr deleteIfExists
    jsr freeStringLiterals
    jsr freeDataSegment
    jsr freeLinkerTags
    jsr freeImports
    jsr freeFrames
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
