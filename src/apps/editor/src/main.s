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

.segment "ENTRY"

.import clearKeyBuf, editorRun, initEditor, initLib

main:
    ; Save the stack pointer
    tsx
    stx savedStackPtr

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

    jsr clearKeyBuf             ; Clear the keyboard buffer

    ; Load the library
    jsr initLib

    jsr initMemHeap

    jsr initEditor

    jsr editorRun

    rts
