;
; main.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Main compiler entry point

.include "cbm_kernal.inc"
.include "zeropage.inc"
.include "asmlib.inc"

CH_LOWERCASE = 14

.segment "ENTRY"

.import clearKeyBuf, initLib, getSourceFn, runCompiler, logError
.import backupZeroPage, restoreZeroPage, showTitleBanner

main:
    ; Save the stack pointer
    tsx
    stx savedStackPtr

    ; Make a backup of page zero
    jsr backupZeroPage

    ; Set alphabet to upper and lower case
    lda #CH_LOWERCASE
    jsr CHROUT

    ; Show title
    jsr showTitleBanner

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

    jsr clearKeyBuf             ; Clear the keyboard buffer

    ; Load the library
    jsr initLib

    ; Initialize the runtime stack
    jsr stackInit

    ; Initialize the memory heap
    jsr initMemHeap

    ; Initialize error handling
    lda #<logError
    ldx #>logError
    jsr initCompilerErrors

    jsr getSourceFn
    bcs :+                      ; Branch if we have a filename
    jsr restoreZeroPage
    rts

:   jsr runCompiler

    ; Restore page zero
    jsr restoreZeroPage

    ; Re-enable BASIC ROM
    lda $01
    ora #$01
    sta $01

    rts
