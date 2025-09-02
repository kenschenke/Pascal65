;
; runcompiler.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runCompiler routine

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "cbm_kernal.inc"
.include "c64.inc"

.export runCompiler

.import clearScreen, loadfile

.data

autoRunFn: .byte "autorun,s,w"
autoRunFn2:

autoSrcFn: .byte "autosrc,s,w"
autoSrcFn2:

compilingMsg: .asciiz "Compiling "

compilerFn: .asciiz "compiler"

loadprog: .asciiz "loadprog"
loadprog2:

.code

; This routine runs the compiler. First it creates an AUTORUN or AUTOSRC
; file depending on whether the user wants to run or just compiler.
; It writes a message to the screen then loads the loadprog helper.
; This is just a short routine that loads and runs the compiler.
; The routine lives outside of the memory space of the IDE, which will
; get overwritten when the compiler loads.
;
; On input, the carry flag is set if the program is getting run,
; cleared if the source is just getting compiled.
.proc runCompiler
    jsr saveCompilerAutoFile

    ; Write the compiling message
    jsr clearScreen
    ldx #0
:   lda compilingMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   ; Write the filename
    ldz #EDITFILE::filename
:   nop
    lda (currentFile),z
    beq :+
    jsr CHROUT
    inz
    bne :-
:   lda #13
    jsr CHROUT

    ldx #<loadprog
    ldy #>loadprog
    lda #loadprog2-loadprog-1
    jsr loadfile

    lda #<compilerFn
    ldx #>compilerFn
    jmp $8fd0           ; Call into loadprog
.endproc

; This routine creates an AUTORUN or AUTOSRC file for the compiler.
; If the file is named AUTORUN then the compiler will add code to
; re-launch the IDE when the program finishes. Both files are the
; same contents, just the main source file.
;
; On entry, the carry flag is set if an AUTORUN is to be created.
; The source filename is taken from currentFile
.proc saveCompilerAutoFile
    bcs AR          ; Branch if AUTORUN
    ldx #<autoSrcFn
    ldy #>autoSrcFn
    lda #autoSrcFn2-autoSrcFn
    bra SN

AR: ldx #<autoRunFn
    ldy #>autoRunFn
    lda #autoRunFn2-autoRunFn

SN: jsr SETNAM

    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS

    jsr OPEN
    ldx #1
    jsr CHKOUT

    ; Write the filename
    ldz #EDITFILE::filename
:   nop
    lda (currentFile),z
    beq :+
    jsr CHROUT
    inz
    bne :-
:   lda #13
    jsr CHROUT

    lda #1
    jsr CLOSE
    jsr CLRCHN

    rts
.endproc
