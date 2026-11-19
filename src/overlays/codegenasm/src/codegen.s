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

.data

icodeFn: .asciiz "zztmpicode"

tempFn: .byte "zztmpicode,s,r"
tempFn2:

; The code is written to this file, then copied into the object file
; (writeObjFile)
codeFn: .byte "zzcode,s,w"
codeFn2:

.bss

runtimeStackSize: .res 2
delName: .res 2             ; for deleteIfExists

.code

; The icode file holds everything code generation needs: the header,
; the imports and frames tables and the code (icode.inc). It doesn't use
; the AST.
.proc genObjCode
    jsr initImports
    jsr initFrames

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

    jsr writeStringLiterals

    jsr freeStringLiterals

    jsr writeDataSegment

    jsr freeDataSegment

    ; The linker puts the runtime's BSS after the program

    ; Close the intermediate code file
    lda #2
    jsr CLOSE
    ldx #0
    jsr CHKIN

    ; Close the code file
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKOUT

    ; Delete the intermediate code file
    lda #<icodeFn
    ldx #>icodeFn
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile

    lda #1
    jsr CLOSE
    lda #2
    jsr CLOSE
    jsr CLRCHN

    ; Write the object file. It frees the linker tags. The linker lays
    ; out the program and checks that it fits in memory.
    jmp writeObjFile
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
