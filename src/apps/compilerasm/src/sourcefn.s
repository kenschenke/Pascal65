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
.include "workdisk.inc"

.export getSourceFn

.import initWorkdisk

.data

prompt: .asciiz "Source file (9:name for a work disk on unit 9): "
autosrc: .asciiz "autosrc"
existMsg: .asciiz " does not exist."

.bss

filename: .res 21           ; getline's 20 and the terminator
unit: .res 1                ; The unit prefix's value

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
    ldx workDevice
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

; This routine takes the unit prefix off the name, then checks if the
; file exists, on the work disk or the system disk, as the tokenizer
; looks for it. If it does not, it prints an error message then clears
; the carry bit and returns.
.proc checkFn
    jsr takeUnit
    bcs NO              ; Branch if the prefix's work disk can't be used
    lda #<filename
    ldx #>filename
    ldy #0
    ldz #0
    jsr locateFile
    bne L1              ; Branch if the file exists

    ; The file does not exist. Show a message then clear the carry flag
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
NO: clc
    rts

L1: lda #<filename
    ldx #>filename
    sec
    rts
.endproc

; This routine takes a unit prefix, one or two digits and a colon (9:name),
; off the front of the filename. Without one the compiler runs in
; single-disk mode. With one, the workdisk overlay's wdUse makes the unit
; the work disk (the system disk's unit is single-disk mode). The carry
; is set if it can't, once wdUse has printed why.
.proc takeUnit
    ldx #0
    stx unit
L1: lda filename,x
    cmp #'0'
    bcc NU
    cmp #'9'+1
    bcs NU
    and #$0f
    pha
    lda unit            ; unit * 10 + the digit
    asl a
    asl a
    adc unit
    asl a
    sta unit
    pla
    clc
    adc unit
    sta unit
    inx
    cpx #3
    bne L1
    bra NO              ; Three digits: not a prefix
NU: cpx #0
    beq NO              ; No digits
    cmp #':'
    bne NO

    ; Move the name after the colon to the front
    ldy #0
:   inx
    lda filename,x
    sta filename,y
    iny
    cmp #0
    bne :-

    jsr initWorkdisk
    lda unit
    jsr wdUse
    bne ER
NO: clc
    rts
ER: sec
    rts
.endproc
