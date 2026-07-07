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
.import writeRuntimeBss, cleanupLibraries
.import initDataSegment, writeDataSegment, freeDataSegment

.data

icodeFn: .asciiz "zztmpicode"

tempFn: .byte "zztmpicode,s,r"
tempFn2:

; This is used to delete the file if it exists
objFilename: .asciiz "zztmp"

; This is used to create the file
objFn: .byte "zztmp,s,w"
objFn2:

.bss

runtimeStackSize: .res 2
astRoot: .res 4

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

    ; See if the object file already exists
    lda #<objFilename
    ldx #>objFilename
    ldy #0
    ldz #0
    jsr doesFileExist
    beq :+
    ; The file exists. Delete it.
    lda #<objFilename
    ldx #>objFilename
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile

    ; Open the object code output file
    ; Call SETLFS
:   ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ; Call SETNAM
    ldx #<objFn
    ldy #>objFn2
    lda #objFn2-objFn
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

    ; Clean up the libraries
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

    ; Close the object code file
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

    rts
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
