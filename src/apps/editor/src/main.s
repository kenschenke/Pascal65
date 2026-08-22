;
; main.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Main editor entry point

.include "cbm_kernal.inc"
.include "zeropage.inc"
.include "editor.inc"
.include "asmlib.inc"

CH_UPPERCASE = 142

.segment "ENTRY"

.import initLib, backupZeroPage, restoreZeroPage, editorLoop, logError
.import runCompiledPrg, deleteZzprg

main:
    ; Save the stack pointer
    tsx
    stx savedStackPtr

    ; Make a backup of page zero
    jsr backupZeroPage

    ; Set alphabet to upper and lower case
    lda #CH_LOWERCASE
    jsr CHROUT

    ; Disable BASIC ROM
    lda $01
    and #$f8
    ora #$06
    sta $01

    ; Set up the exit handler
    lda #<_exit
    sta exitHandler
    lda #>_exit
    sta exitHandler+1

    ; Load the library
    jsr initLib

    ; Initialize the memory heap
    jsr initMemHeap

    ; Initialize error handling
    lda #<logError
    ldx #>logError
    jsr initCompilerErrors

    ; Initialize the runtime stack
    jsr stackInit

    ; Delete "zzprg.prg" if it exists
    jsr deleteZzprg

    ; Launch the editor
    jsr editorLoop
    php

    ; Restore page zero
    jsr restoreZeroPage
    plp
    bcc :+
    jmp runCompiledPrg

    ; Re-enable BASIC ROM
:   lda $01
    ora #$01
    sta $01

    ; Clear the screen
    lda #CH_CLRSCR
    jsr CHROUT

    ; Put the character set back to uppercase and graphics
    lda #CH_UPPERCASE
    jsr CHROUT

    rts
