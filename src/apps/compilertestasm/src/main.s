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

.import clearKeyBuf, initLib, compileTests, logError, logWarning
.import backupZeroPage, restoreZeroPage
.import testInit, testPass, testFail

.export failTests

main:
    ; Remember the stack pointer so a failure can return straight to BASIC
    jsr testInit

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
    lda #<onExit
    sta exitHandler
    lda #>onExit
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

    ; Initialize compiler warnings
    lda #<logWarning
    ldx #>logWarning
    jsr initCompilerWarnings

    jsr compileTests

    ; Restore page zero
    jsr restoreZeroPage

.ifdef TESTSET
    jsr testPass
.endif

    rts

; Called when a runtime error ends the compiler
onExit:
    lda #13
    jsr CHROUT
    ; Fall through to failTests

; Called when a compile produces an error or warning. Reports the failure
; and returns straight to BASIC.
failTests:
    jsr restoreZeroPage
    jmp testFail
