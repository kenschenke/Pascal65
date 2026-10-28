;
; logerror.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; logError routine

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export logError, errorCount, logWarning

.bss

errorCount: .res 1
strBuf: .res 10

.data

strError: .asciiz "*** ERROR: "
strWarning: .asciiz "*** WARNING: "
strLine: .asciiz " -- line "

.code

; Called when the compiler flags an error.
; Inputs:
;    A/X - the source code line
;    Y   - the error number (error.inc)
;    Runtime stack - null-terminated error message
.proc logError
    sta intOp1
    stx intOp1+1
    inc errorCount

    ; Print the error header
    ldx #0
:   lda strError,x
    beq :+
    jsr CHROUT
    inx
    bne :-

    ; Print the message
:   jmp logMessage
.endproc

; Called when the compiler flags a warning.
; Inputs:
;    A/X - the source code line
;    Y   - the error number (error.inc)
;    Runtime stack - null-terminated error message
.proc logWarning
    sta intOp1
    stx intOp1+1

    ; Print the error header
    ldx #0
:   lda strWarning,x
    beq DN
    jsr CHROUT
    inx
    bne :-

    ; Print the message
DN: ; Fall through to logMessage
.endproc

.proc logMessage
    jsr popQ
    stq ptr1
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    jsr CHROUT
    inz
    bne :-

    ; Print the line message
:   ldx #0
:   lda strLine,x
    beq :+
    jsr CHROUT
    inx
    bne :-

    ; Print the line number
:   lda #<strBuf
    ldx #>strBuf
    jsr writeInt16
    ldx #0
:   lda strBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   lda #13
    jsr CHROUT

    rts
.endproc
