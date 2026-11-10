;
; error.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Compiler error handling

.include "zeropage.inc"
.include "4510macros.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "error.inc"

.export rtInitCompilerErrors, rtCompilerError, rtCompilerWarning, rtInitCompilerWarnings
.export rtSetCompilerFilename, rtSetCompilerUnitFilename, rtGetCompilerFilename

.import heapAlloc, exit, rtPushQ

; CBM filenames are at most 16 characters
MAX_FILENAME_LENGTH = 16

.bss

; Null-terminated name of the source file being compiled. Errors and
; warnings are in this file.
sourceFilename: .res MAX_FILENAME_LENGTH+1

; This is a pointer to a buffer that holds all error messages, index by error number.
; Each error message is at most 23 characters long and each is null terminated within
; a 24 byte slot.
parserErrors: .res 4
count: .res 1
logCompilerError: .res 2
logCompilerWarning: .res 2

.data

strPas: .asciiz ".pas"
parserErrorsFn: .asciiz "errormsgs.txt,s,r"
parserErrorsFn2:
errMsgTooLong: .asciiz "Error message too long"
tooManyErrMsgs: .asciiz "Too many error messages in file"

.code

; Initialize the compile-time message handler
; Inputs:
;    A - low byte of handler callback
;    B - high byte of handler callback
;
; When a compile-time error occurs, the callback handler is called
; with the following parameters.
;    A - low byte of source line number
;    X - high byte of source line number
;    Y - error number
;    The runtime stack contains a 32-bit pointer to the null terminated msg.
.proc rtInitCompilerErrors
    sta logCompilerError
    stx logCompilerError+1
    lda #0
    sta sourceFilename
    jmp loadParserErrors
.endproc

; Set the name of the source file errors and warnings are reported in
; Inputs:
;    A/X - pointer to the null-terminated filename
; Names longer than 16 characters are cut off. Destroys ptr1.
.proc rtSetCompilerFilename
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    sta sourceFilename,y
    beq :+
    iny
    cpy #MAX_FILENAME_LENGTH
    bne :-
    lda #0
    sta sourceFilename,y
:   rts
.endproc

; Set the source file errors and warnings are reported in to a unit's file:
; the unit's name followed by ".pas".
; Inputs:
;    Q - pointer to the unit (unit::name is first)
; Destroys ptr1
.proc rtSetCompilerUnitFilename
    stq ptr1
    ldy #0
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    sta sourceFilename,y
    iny
    inz
    cpy #MAX_FILENAME_LENGTH-4  ; leave room for ".pas"
    bne :-
:   ldx #0
:   lda strPas,x
    sta sourceFilename,y
    beq :+
    iny
    inx
    bne :-
:   rts
.endproc

; Get the name of the source file errors and warnings are reported in
; Outputs:
;    A/X - pointer to the null-terminated filename. It is empty if no
;          name has been set since initCompilerErrors.
.proc rtGetCompilerFilename
    lda #<sourceFilename
    ldx #>sourceFilename
    rts
.endproc

.proc rtInitCompilerWarnings
    sta logCompilerWarning
    stx logCompilerWarning+1
    rts
.endproc

; Log a compile-time error
; Inputs:
;    A - error number from errors.inc -- errXXX
;    X - low byte of current line number
;    Y - high byte of current line number
.proc rtCompilerError
    jsr pushMessage
    jmp (logCompilerError)
.endproc

; Log a compile-time warning
; Inputs:
;    A - warning number from errors.inc
;    X - low byte of current line number
;    Y - high byte of current line number
.proc rtCompilerWarning
    jsr pushMessage
    jmp (logCompilerWarning)
.endproc

; Push a pointer to the message for an error or warning onto the runtime
; stack and set up the handler's inputs.
; Inputs:
;    A - error or warning number
;    X - low byte of current line number
;    Y - high byte of current line number
; Outputs:
;    A - low byte of the line number
;    X - high byte of the line number
;    Y - error or warning number
.proc pushMessage
    phx
    phy
    pha
    lda #MAX_ERROR_LENGTH+1
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq parserErrors
    stq ptr1
    pla
    sta count
    pha
L1: ldq ptr1
    clc
    adcq intOp32
    stq ptr1
    dec count
    bne L1

    ldq ptr1
    jsr rtPushQ

    ply
    plx
    pla
    rts
.endproc

; This routine calculates the size of the buffer necessary to load all error messages.
; The number of errors is passed in A.
; The size of the buffer is returned in A/X.
.proc calcBufferSize
    tax
    lda #0
    sta intOp1
    sta intOp1+1
:   lda intOp1
    clc
    adc #MAX_ERROR_LENGTH+1
    sta intOp1
    lda intOp1+1
    adc #0
    sta intOp1+1
    dex
    bne :-
    lda intOp1
    ldx intOp1+1
    rts
.endproc

; This routine reads the error file.
; The low byte of the filename is passed X
; The high byte of the filename is passed in Y
; The length of the filename (include ",s,r" is passed in A)
; The buffer pointer is expected in ptr1
.proc readErrorFile
    jsr SETNAM
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    jsr OPEN
    ldx #1
    jsr CHKIN

    ; Initialize intOp32 for ptr1 math later
    lda #MAX_ERROR_LENGTH+1
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    sta count

    ; Loop to read each error message from file
L1: ldz #0
:   lda STATUS
    cmp #$40
    beq L4
    jsr CHRIN
    cmp #13
    beq L2
    nop
    sta (ptr1),z
    inz
    cpz #MAX_ERROR_LENGTH+1
    beq L5
    bra :-

    ; Carriage return found - write zeros for remainder of line
L2: lda #0
    cpz #0
    beq L1
:   cpz #MAX_ERROR_LENGTH+1
    beq L3
    nop
    sta (ptr1),z
    inz
    bne :-

    ; End of line reached. Advance ptr1 for next error message.
L3: ldq ptr1
    clc
    adcq intOp32
    stq ptr1
    inc count
    lda count
    cmp #numParserErrors+1
    bcs L6
    bra L1

L4: lda #1
    jsr CLOSE
    ldx #0
    jmp CHKIN

    ; An error message is longer than the maximum allowed
L5: jsr CLRCHN
    ldx #0
:   lda errMsgTooLong,x
    beq :+
    jsr CHROUT
    inx
    bne :-
    lda #13
    jsr CHROUT
    jmp exit

    ; Too many error messages found in file
L6: jsr CLRCHN
    ldx #0
:   lda tooManyErrMsgs,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT
    jmp exit
.endproc

.proc loadParserErrors
    lda #numParserErrors
    jsr calcBufferSize
    jsr heapAlloc
    stq parserErrors
    stq ptr1
    ldx #<parserErrorsFn
    ldy #>parserErrorsFn
    lda #parserErrorsFn2-parserErrorsFn-1
    jsr readErrorFile
    rts
.endproc
