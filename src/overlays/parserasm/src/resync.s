.include "zeropage.inc"
.include "error.inc"
.include "asmlib.inc"
.include "tokenizer.inc"

.export doResync, tokenIn

.import getToken, parserToken, currentLineNumber, parserError

; This routine checks up to three token lists for a token to resync
; the parser. The three token lists are stored in ptr1, ptr2, and ptr3.
; NULL in one of those is skipped.
.proc doResync
    lda ptr1
    ldx ptr1+1
    jsr tokenIn
    bne L4

    lda ptr2
    ldx ptr2+1
    jsr tokenIn
    bne L4

    lda ptr3
    ldx ptr3+1
    jsr tokenIn
    bne L4

    ; The token was in none of the lists.
    lda parserToken
    cmp #tcEndOfFile
    bne :+
    lda #errUnexpectedEndOfFile
    sta tmp1
    bra L1
:   lda #errUnexpectedToken
    sta tmp1
L1: jsr parserError

    ; Skip tokens until the token is found in one of the lists
    ; or the tcPeriod or tcEndOfFile token is encountered.
L2: lda ptr1
    ldx ptr1+1
    jsr tokenIn
    bne L3
    lda ptr2
    ldx ptr2+1
    jsr tokenIn
    bne L3
    lda ptr3
    ldx ptr3+1
    jsr tokenIn
    bne L3
    lda parserToken
    cmp #tcPeriod
    beq L3
    cmp #tcEndOfFile
    beq L3
    jsr getToken
    bra L2

L3: ; Flag an expected end of file
    lda parserToken
    cmp #tcEndOfFile
    bne L4
    lda tmp1
    cmp #errUnexpectedEndOfFile
    bne L4
    lda #errUnexpectedEndOfFile
    jsr parserError

L4: rts
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
