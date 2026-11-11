;
; editortest.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Hooks for the editor tests (src/apps/editortest). They are only assembled
; in the test build of the overlay (make EDITORTEST=1), which defines
; __EDITORTEST__. The normal editor has none of this.
;
; The test sets a key script with editorTestSetup, then calls editorRun.
; editorReadKey takes its keys from the script instead of the keyboard. When
; the script runs out, the edit buffer is closed (as a save would) and
; editorRun returns EDITOR_LOOP_QUIT straight to its caller, wherever the
; editor was waiting for a key. The test then looks at the file through
; currentFile and frees everything with editorTestCleanup.
;
; The editor reads filenames with asmlib's getline, which reads the keyboard
; itself. editorTestSetup points getline's jump table entry at testGetline,
; which takes the keys from the script too, and editorTestCleanup puts it
; back.

.ifdef __EDITORTEST__

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export editorTestSetup, editorTestCleanup, editorTestNextKey
.export editorTestSP, editorTestPascal, editorTestState

.import closeEditBuf, fileFree, firstFile, titleScreen, clipboard
.import fixAlphaCase, screenrows

INPUTBUFLEN = 20            ; As getline has it

.bss

editorTestSP: .res 1        ; Stack pointer on entry to editorRun
editorTestPascal: .res 1    ; Non-zero makes new files Pascal files
getlineAddr: .res 2         ; getline's own address in the jump table

.data

; The addresses of the editor's variables a test looks at (editorTestState)
stateTable:
    .addr firstFile         ; .dword: the first open file
    .addr clipboard         ; .dword: the clipboard's memory buffer
    .addr screenrows        ; .byte: the number of text rows

.code

; Returns the address of stateTable in A/X
.proc editorTestState
    lda #<stateTable
    ldx #>stateTable
    rts
.endproc

; Returns the next key of the script in X. At the end of the script it does
; not return. It returns EDITOR_LOOP_QUIT from editorRun instead.
.proc editorTestNextKey
    ldx $ffff               ; The address is set by editorTestSetup
keyAddr = * - 2
    beq DN
    inc keyAddr
    bne :+
    inc keyAddr+1
:   rts

DN: jsr closeEditBuf        ; Put edits in progress into the line
    ldx editorTestSP
    txs
    lda #EDITOR_LOOP_QUIT
    rts
.endproc

; Sets the key script. A/X points to it and Y is non-zero if new files are
; Pascal files. The script is a list of key codes as the keyboard sends
; them, ended by a zero.
.proc editorTestSetup
    sta editorTestNextKey::keyAddr
    stx editorTestNextKey::keyAddr+1
    sty editorTestPascal
    lda getline+1
    sta getlineAddr
    lda getline+2
    sta getlineAddr+1
    lda #<testGetline
    sta getline+1
    lda #>testGetline
    sta getline+2
    rts
.endproc

; asmlib's getline, with keys from the script and nothing on the screen.
; A/X is a buffer of INPUTBUFLEN bytes. The number of characters is returned
; in A, and the carry is clear if the line ended with Esc.
.proc testGetline
    sta ptr1
    stx ptr1+1
    lda #0
    ldy #INPUTBUFLEN-1
:   sta (ptr1),y
    dey
    bpl :-
    sta tmp1
L1: jsr editorTestNextKey
    txa
    jsr fixAlphaCase
    cmp #CH_ENTER
    beq EN
    cmp #CH_BACKSPACE
    beq BS
    cmp #CH_ESC
    beq ES
    cmp #32
    bcc L1                  ; A control code
    cmp #160
    bcs :+
    cmp #127
    bcs L1
:   ldy tmp1
    cpy #INPUTBUFLEN
    beq L1                  ; The buffer is full
    sta (ptr1),y
    inc tmp1
    bra L1
BS: ldy tmp1
    beq L1
    dec tmp1
    dey
    lda #' '
    sta (ptr1),y
    bra L1
EN: lda tmp1
    sec
    rts
ES: lda tmp1
    clc
    rts
.endproc

; Frees every open file, the title screen and the clipboard, without the
; prompts that closing a modified file shows. A is the code editorRun
; returned. When the editor runs or compiles a program, or changes the
; theme, it has already freed the files and the title screen (see
; editorCloseAllFiles).
.proc editorTestCleanup
    cmp #EDITOR_LOOP_QUIT
    bne L3
L1: ldq firstFile
    jsr isQZero
    beq L2
    stq currentFile
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (currentFile),z
    stq firstFile
    ldq currentFile
    jsr fileFree
    bra L1

L2: ldq titleScreen
    jsr isQZero
    beq L3
    jsr fileFree

L3: ldq clipboard
    jsr isQZero
    beq L4
    jsr freeMemBuf

L4: lda #0
    tax
    tay
    taz
    stq currentFile
    stq firstFile
    stq titleScreen
    stq clipboard
    lda getlineAddr
    sta getline+1
    lda getlineAddr+1
    sta getline+2
    rts
.endproc

.endif ; __EDITORTEST__
