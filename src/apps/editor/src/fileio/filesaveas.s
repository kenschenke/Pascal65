;
; filesaveas.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; fileSaveAs routine

.include "cbm_kernal.inc"
.include "c64.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "asmlib.inc"

.export fileSaveAs

.import screenrows, fnBuf
.import editorDrawMessageBar, statusmsg, statusmsg_dirty
.import fileWrite, renderCursor, makeFilename
.import doesFileExist, scratchFile
.import editorReadKey, editorSetStatusMsg, editorSetDefaultStatusMessage

.data

saveAsPrompt: .asciiz "Save As: "
saveAsPromptLength:
overwritePrompt: .asciiz " already exists. Overwrite Y/N?"

.bss

inputBufUsed: .res 1

.code

; This routine prompts the user for a filename.
; If the pressed escape or entered a blank filename,
; the carry flag is cleared. Otherwise, it is set.
; The filename is stored in fnBuf and the number of characters is returned in A.
.proc fileSaveAs
    ; Copy saveAsPrompt to statusmsg
    lda #<saveAsPrompt
    ldx #>saveAsPrompt
    jsr editorSetStatusMsg
    jsr editorDrawMessageBar
    ; Move the cursor because getline uses CHROUT
    ldy #saveAsPromptLength-saveAsPrompt-1
    ldx screenrows
    inx
    clc
    jsr PLOT
    ; Clear the editor cursor
    clc
    jsr renderCursor
    ; Call getline
    lda #<fnBuf
    ldx #>fnBuf
    jsr getline
    sta inputBufUsed
    bcs :+              ; Branch if the user hit enter
    rts
:   bne :+              ; Branch if the user entered a filename
    ; The filename was blank so clear the carry flag and return
    clc
    rts

    ; Check if the filename already exists
:   ldx inputBufUsed
    lda #0
    sta fnBuf,x
    lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    jsr doesFileExist
    beq L1
    ; The file already exists.
    ; Ask the user if they want to overwrite it.
    jsr askOverwrite
    bcc DN                  ; User is not overwriting - exit
    ; Delete the existing file
    lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile

    ; Call SETLFS
L1: ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ; Set up the filename
    lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    clc
    jsr makeFilename
    jsr SETNAM
    ; Open the file and set output channel
    jsr OPEN
    ldx #1
    jsr CHKOUT

    ; Write the file contents
    jsr fileWrite

    ; Close the file
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKOUT
    lda inputBufUsed
    sec
DN: rts
.endproc

; This routine prompts the user to overwrite the file.
; If carry flag is cleared if the user does not want to overwrite.
.proc askOverwrite
    ; Copy the filename to the statusmsg
    ldx #0
    ldy #0
:   lda fnBuf,y
    beq :+
    sta statusmsg,y
    inx
    iny
    bne :-
:   ldx #0
:   lda overwritePrompt,x
    sta statusmsg,y
    beq :+
    inx
    iny
    bne :-
:   lda #1
    sta statusmsg_dirty
    jsr editorDrawMessageBar
L1: jsr editorReadKey
    ora #$80            ; Convert to upper case
    cmp #'N'
    beq NO
    cmp #'Y'
    beq YES
    bra L1
NO: jsr editorSetDefaultStatusMessage
    clc
    rts
YES:
    sec
    rts
.endproc
