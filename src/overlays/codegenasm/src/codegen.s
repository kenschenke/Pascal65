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

.export genObjCode
.export genThreeAddr, runtimeStackSize, setRuntimeStackSize
.export genOneInstruction, genTwoInstruction, incCodeOffset, calcNamePtr

.import writePrgHeader, processIcodeInstructions, prgCleanup
.import initStringLiterals, writeStringLiterals, freeStringLiterals
.import writeRuntimeBss, cleanupLibraries, checkCodeSize
.import initDataSegment, writeDataSegment, freeDataSegment
.import tagBSS_EXITHANDLER
.import writeObjFile, objFilename, codeFilename

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
astRoot: .res 4
delName: .res 2             ; for deleteIfExists

.code

; AST root passed in Q
.proc genObjCode
    stq astRoot

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

    ldq astRoot
    jsr writePrgHeader

    ; Open the icode file
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

    jsr processIcodeInstructions

    ; User code is written.

    ; Clean up the libraries. A runtime error (exit in the runtime) comes
    ; here too, so the libraries clean up after it.
    lda #<tagBSS_EXITHANDLER
    ldx #>tagBSS_EXITHANDLER
    jsr linkAddressSet
    ldq astRoot
    jsr cleanupLibraries

    ; Add some code to clean up the runtime and return to BASIC.
    jsr prgCleanup

    jsr writeStringLiterals

    jsr freeStringLiterals

    jsr writeDataSegment

    jsr freeDataSegment

    jsr writeRuntimeBss

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

    ; Report a program too large for memory. It won't be linked, so
    ; it gets no object file.
    jsr checkCodeSize
    bcc :+
    lda #<codeFilename
    ldx #>codeFilename
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile
    jmp freeLinkerTags

    ; Write the object file. It frees the linker tags.
:   ldq astRoot
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

.proc setRuntimeStackSize
    sta runtimeStackSize
    stx runtimeStackSize+1
    rts
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
