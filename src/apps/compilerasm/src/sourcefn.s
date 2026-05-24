;
; sourcefn.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; sourcefn routine

.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "c64.inc"

.export getSourceFn

.data

prompt: .asciiz "Source file: "
autosrc: .asciiz "autosrc"
existMsg: .asciiz " does not exist."

.bss

filename: .res 20

.code

; This routine is called from main. It looks for a AUTOSRC file, which is written
; by the editor when the compiler is called from within the IDE. If it exists, the
; source filename is read from that file. If it does not exist, the user is prompted
; for the source filename.
;
; Return:
;    Carry flag is cleared when no source file could be determined.
;    If the carry flag is set, a pointer to the null-terminated filename is in A/X.
.proc getSourceFn
    lda #<autosrc
    ldx #>autosrc
    ldy #0
    ldz #0
    jsr doesFileExist
    cmp #0
    bne :+              ; Branch if autosrc exists
    ; Autosrc does not exist. Prompt the user for the filename instead.
    jmp promptFn

    ; Read the autosrc
:   lda #<autosrc
    ldx #>autosrc
    ldy #0
    ldz #0
    sec
    jsr makeFilename
    jsr SETNAM
    ; Call SETLFS
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    jsr OPEN
    ldx #1
    jsr CHKIN
    ; Read the filename until a CR is found
    ldy #0
:   jsr CHRIN
    cmp #13
    beq :+
    sta filename,y
    iny
    bne :-
:   lda #0
    sta filename,y
    ; Close the file
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKIN
    
    jmp checkFn
.endproc

; This routine prompts the user for the source filename to compile.
; Pointer to the null-terminated filename is returned in A/X.
; If the carry flag is cleared on return, the pressed escape or the filename is empty.
.proc promptFn
    ; Print the prompt to the screen
    ldx #0
:   lda prompt,x
    beq :+
    jsr CHROUT
    inx
    bne :-

    ; Input the filename
:   lda #<filename
    ldx #>filename
    jsr getline
    bcs :+              ; Branch if the user did not press escape
    rts

:   cmp #0
    bne :+              ; Branch if the filename is not empty
    clc
    rts

:   tax
    lda #0
    sta filename,x      ; Null-terminate the filename

    ; Fall through to checkFn
.endproc

; This routine checks if the file exists. If it does not, it
; prints an error message then clears the carry bit and returns.
.proc checkFn
    ; Check if the file exists.
    lda #<filename
    ldx #>filename
    ldy #0
    ldz #0
    jsr doesFileExist
    cmp #0
    bne L1              ; Branch if the file exists

    ; The file does not exist. Show a message then set the carry flag
    ; and return.

    lda #13
    jsr CHROUT
    jsr CHROUT
    ldx #0
:   lda filename,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   ldx #0
:   lda existMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT
    clc
    rts

L1: lda #<filename
    ldx #>filename
    sec
    rts
.endproc
