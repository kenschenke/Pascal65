;
; resync.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Resynchronize the parser after a syntax error

.include "zeropage.inc"
.include "error.inc"
.include "asmlib.inc"
.include "tokenizer.inc"

.export doResync, tokenIn

.import getToken, parserToken, currentLineNumber, parserError

.bss

; Copies of the three token lists. parserError and getToken use ptr1
; through ptr3.
lists: .res 6

.code

; This routine resynchronizes the parser after a syntax error. Up to three
; token lists are in ptr1, ptr2 and ptr3. NULL in one of those is skipped.
;
; If the current token is in one of the lists, it returns at once.
; Otherwise it reports the token as unexpected and skips tokens until it
; finds one in a list, a period or the end of the file. A period is never
; skipped, because it ends the program. Reaching the end of the file is
; reported as well.
.proc doResync
    ldx #1
:   lda ptr1,x
    sta lists,x
    lda ptr2,x
    sta lists+2,x
    lda ptr3,x
    sta lists+4,x
    dex
    bpl :-

    jsr inLists
    beq DN

    lda parserToken
    cmp #tcEndOfFile
    bne :+
    lda #errUnexpectedEndOfFile
    jmp parserError

:   lda #errUnexpectedToken
    jsr parserError

L1: lda parserToken
    cmp #tcPeriod
    beq DN
    jsr getToken
    jsr inLists
    beq DN
    lda parserToken
    cmp #tcEndOfFile
    bne L1
    lda #errUnexpectedEndOfFile
    jmp parserError

DN: rts
.endproc

; This routine sets the Z flag if parserToken is in one of the lists
; saved by doResync.
.proc inLists
    lda lists
    ldx lists+1
    jsr tokenIn
    beq DN
    lda lists+2
    ldx lists+3
    jsr tokenIn
    beq DN
    lda lists+4
    ldx lists+5
    jmp tokenIn
DN: rts
.endproc

; The token list pointer is passed in A/X
; On exit, the Z flag is set if parserToken is in the list.
.proc tokenIn
    sta ptr4
    stx ptr4+1
    ora ptr4+1
    beq L2
    ldy #0
L1: lda (ptr4),y
    cmp #tcDummy
    beq L2
    cmp parserToken
    beq L3
    iny
    bne L1
L2: lda #1
L3: rts
.endproc
