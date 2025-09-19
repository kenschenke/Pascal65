;
; getcharcode.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getCharCode routine

.include "tokenizer.inc"

.export getCharCode

; This routine returns the character code for a given input character.
; The character code is used to classify characters into groups.
;
; Inputs: the character is passed in A
; Outputs: the code is returned in A
.proc getCharCode
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

    cmp #CH_EOF
    beq EndOfFile

    ; Don't know
    lda #ccError
    rts

Letter:
    lda #ccLetter
    rts

Special:
    lda #ccSpecial
    rts

Digit:
    lda #ccDigit
    rts

WhiteSpace:
    lda #ccWhiteSpace
    rts

Quote:
    lda #ccQuote
    rts

Dollar:
    lda #ccDollar
    rts

Hash:
    lda #ccHash
    rts

Percent:
    lda #ccPercent
    rts

EndOfFile:
    lda #ccEndOfFile
    rts
.endproc
