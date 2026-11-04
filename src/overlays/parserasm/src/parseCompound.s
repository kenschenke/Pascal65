;
; parseCompound.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parse a compound (BEGIN..END) statement

.include "tokenizer.inc"
.include "4510macros.inc"
.include "asmlib.inc"
.include "error.inc"

.export parseCompound

.import getToken, parseStatementList, condGetToken, parserToken

.proc parseCompound
    lda parserToken
    cmp #tcEND
    beq :+
    jsr getToken
:   lda #tcEND
    jsr parseStatementList
    jsr pushQ

    lda #tcEND
    ldx #errMissingEND
    jsr condGetToken

    jsr popQ
    rts
.endproc
