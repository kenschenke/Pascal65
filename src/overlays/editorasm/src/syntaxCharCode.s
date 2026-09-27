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
    bcc CkSpecial   ; Branch if <= 64
    cmp #91
    bcs :+
    jmp Letter      ; Branch if <= 90
:   cmp #97
    bcc CkSpecial   ; Branch if <= 96
    cmp #123
    bcs :+
    jmp Letter      ; Branch if <= 122
:   cmp #193
    bcc CkSpecial   ; Branch if <= 192
    cmp #219
    bcs CkSpecial   ; Branch if <= 218
    jmp Letter

    ; Is it a special character?
CkSpecial:
    cmp #'+'
    bne :+
    jmp Special
:   cmp #'-'
    bne :+
    jmp Special
:   cmp #'*'
    beq Special
    cmp #'/'
    beq Special
    cmp #'='
    beq Special
    cmp #'^'
    beq Special
    cmp #'.'
    beq Special
    cmp #','
    beq Special
    cmp #'<'
    beq Special
    cmp #'>'
    beq Special
    cmp #'('
    beq Special
    cmp #')'
    beq Special
    cmp #'['
    beq Special
    cmp #']'
    beq Special
    cmp #':'
    beq Special
    cmp #';'
    beq Special
    cmp #'!'
    beq Special
    cmp #'&'
    beq Special
    cmp #'@'
    beq Special

    ; Is it a digit
    cmp #'0'
    bcc CkWhiteSpace
    cmp #'9'+1
    bcs CkWhiteSpace
    jmp Digit

CkWhiteSpace:
    ; Is it whitespace?
    cmp #' '
    beq WhiteSpace
    cmp #9              ; Tab
    beq WhiteSpace
    cmp #10             ; Tab
    beq WhiteSpace
    cmp #13             ; CR
    beq WhiteSpace
    cmp #0
    beq WhiteSpace

    cmp #'''
    beq Quote

    cmp #'$'
    beq Dollar

    cmp #'#'
    beq Hash

    cmp #'%'
    beq Percent

    ; Don't know
    lda #shError
    rts

Letter:
    lda #shLetter
    rts

Special:
    lda #shSpecial
    rts

Digit:
    lda #shDigit
    rts

WhiteSpace:
    lda #shWhiteSpace
    rts

Quote:
    lda #shQuote
    rts

Dollar:
    lda #shDollar
    rts

Hash:
    lda #shHash
    rts

Percent:
    lda #shPercent
    rts
.endproc
