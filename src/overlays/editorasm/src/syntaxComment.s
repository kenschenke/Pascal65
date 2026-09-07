;
; syntaxComment.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; syntaxComment routine

.include "editor.inc"
.include "zeropage.inc"

.export huntForCommentClose, syntaxSinglelineComment, syntaxMultilineComment

.import syntaxIndex, syntaxCount, syntaxIsNextChar

; This routine looks for the close of a comment: "*)"
; On exit, syntaxIndex is the last character checked.
; On exit, the carry flag is set if the comment remains open.
.proc huntForCommentClose
L1: ldz syntaxIndex
    nop
    lda (ptr1),z
    cmp #'*'
    bne L2
    ; Is the next character ')'?
    ldx #')'
    jsr syntaxIsNextChar
    bne L2
    ; Comment is closed. Mark both characters as a comment
    ldz syntaxIndex
    lda #SYNTAXHL_COMMENT
    nop
    sta (ptr2),z
    inc syntaxIndex
    inz
    nop
    sta (ptr2),z
    inc syntaxIndex
    clc
    rts

    ; Comment still open
L2: ldz syntaxIndex
    lda #SYNTAXHL_COMMENT
    nop
    sta (ptr2),z

    ; Move to the next character
    inc syntaxIndex
    lda syntaxIndex
    cmp syntaxCount
    bne L1

    sec
    rts
.endproc

; This routine is called when the current character is a '(' and
; the next character is a '*'. Characters are checked until either:
;    1) A '*' followed by a ')' is found on the line
;    2) The end of the line is hit
;
; On exit:
;    The carry flag is cleared if #1
;    The carry flag is set if #2.
;
; In either case, SYNTAXHL_COMMENT is set for each character inside the comment.
.proc syntaxMultilineComment
    ldz syntaxIndex
    lda #SYNTAXHL_COMMENT
    nop
    sta (ptr2),z
    inz
    inc syntaxIndex
    nop
    sta (ptr2),z
    inc syntaxIndex

L1: ldz syntaxIndex
    nop
    lda (ptr1),z
    cmp #'*'
    bne L2
    ldx #')'
    jsr syntaxIsNextChar
    bne L2
    ; Comment is closed
    ldz syntaxIndex
    lda #SYNTAXHL_COMMENT
    nop
    sta (ptr2),z
    inz
    inc syntaxIndex
    nop
    sta (ptr2),z
    inc syntaxIndex
    clc
    rts

L2: ldz syntaxIndex
    lda #SYNTAXHL_COMMENT
    nop
    sta (ptr2),z
    inc syntaxIndex

    lda syntaxCount
    cmp syntaxIndex
    bne :+
    lda #0
    sec
    rts
:   bcs L1

    sec
    rts
.endproc

; This routine is called when a '/' character is found, followed by a second '/'.
; The routine sets SYNTAXHL_COMMENT for the remainder of the line
.proc syntaxSinglelineComment
    lda #SYNTAXHL_COMMENT
    ldz syntaxIndex
L1: nop
    sta (ptr2),z
    inz
    cpz syntaxCount
    bne L1

    stz syntaxIndex
    rts
.endproc
