;
; fileclose.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; fileClose routine

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export fileClose

.import isDirty, fileFree, firstFile, editorDrawMessageBar, statusmsg
.import editorHandleFileSave, statusmsg_dirty, editorReadKey
.import editorSetDefaultStatusMessage

.data

promptSave: .asciiz "Save changes before closing? Y/N"

.code

; This routine closes the current file in the editor.
; If the file is modified (dirty), the user is prompted
; to save before closing.
.proc fileClose
    ; See if the file has unsaved changes
    ldz #EDITFILE::dirty
    nop
    lda (currentFile),z
    beq L1              ; Branch if all changes are saved
    jsr askFileSave
    bcc L1              ; Branch if user does not want to save changes
    ; Save changes before closing
    jsr editorHandleFileSave
    bcs L1
    rts                 ; User ended up not saving the file
    ; Check if the current file is the first file in the linked list
L1: ldq firstFile
    cpq currentFile
    bne L3              ; Branch if not the first file
    ; Set firstFile to the current file's nextFile
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (currentFile),z
    stq firstFile
    bra DN
L3: ; Find the current file in the linked list
    stq ptr1
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    cpq currentFile
    bne L3
    ; Set ptr1's nextFile to currentFile's nextFile
    neg
    neg
    nop
    lda (currentFile),z
    stq ptr2
    ldx #3
    ldz #EDITFILE::nextFile+3
:   lda ptr2,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    ; Free the currentFile
DN: ldq currentFile
    jsr fileFree
    ; Set the first file to the current file
    ldq firstFile
    stq currentFile
    rts
.endproc

; This routine asks the user if they want to save changes
; to the file before closing. On exit, the carry flag is set
; if the user wants to save changes.
.proc askFileSave
    ; Copy promptSave to statusmsg
    ldx #0
:   lda promptSave,x
    sta statusmsg,x
    beq :+
    inx
    bne :-
:   lda #1
    sta statusmsg_dirty
    jsr editorDrawMessageBar
L1: jsr editorReadKey
    ora #$80
    cmp #'N'
    beq NO
    cmp #'Y'
    bne L1
    jsr editorSetDefaultStatusMessage
    jsr editorDrawMessageBar
    sec
    rts
NO: jsr editorSetDefaultStatusMessage
    jsr editorDrawMessageBar
    clc
    rts
.endproc
