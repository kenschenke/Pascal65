;
; main.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tree Viewer entry point

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "error.inc"

CH_LOWERCASE = 14

.segment "ENTRY"

.import initLib, showTree, clearKeyBuf
.import logError

main:
    ; Set alphabet to upper and lower case
    lda #CH_LOWERCASE
    jsr CHROUT

    ; Disable BASIC ROM
    lda $01
    and #$f8
    ora #$06
    sta $01

    ; Clear the keyboard buffer
    jsr clearKeyBuf

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

    ; Run the main loop
    jsr showTree

    rts
