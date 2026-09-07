;
; syntaxCharCode.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; syntaxCharCode routine

.include "editor.inc"

.export syntaxCharCode

; This routine returns the character code for a given input character.
; The character code is used to classify characters into groups.
;
; Inputs: the character is passed in A
; Outputs: the code is returned in A
.proc syntaxCharCode
    ; Is it a letter?
    cmp #65
    bcc IsDigit   ; Branch if <= 64
    cmp #91
    bcs :+
    jmp Letter      ; Branch if <= 90
:   cmp #97
    bcc IsDigit   ; Branch if <= 96
    cmp #123
    bcs :+
    jmp Letter      ; Branch if <= 122
:   cmp #193
    bcc IsDigit   ; Branch if <= 192
    cmp #219
    bcs IsDigit   ; Branch if <= 218
    jmp Letter

IsDigit:
    ; Is it a digit
    cmp #'0'
    bcc DontKnow
    cmp #'9'+1
    bcs DontKnow
    jmp Digit

    ; Don't know
DontKnow:
    lda #shError
    rts

Letter:
    lda #shLetter
    rts

Digit:
    lda #shDigit
    rts
.endproc
