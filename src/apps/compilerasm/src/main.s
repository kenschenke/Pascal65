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

.import clearKeyBuf, initLib, getSourceFn, runCompiler

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

    jsr getSourceFn
    bcs :+                      ; Branch if we have a filename
    rts

:   jsr runCompiler

    rts
