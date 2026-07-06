;
; getSubrangeLimit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getSubrangeLimit routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export getSubrangeLimit

; Subrange expression passed in Q
; Subrange limit returned in A/X
.proc getSubrangeLimit
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_BYTE_LITERAL
    bne :+
    jmp getByteLimit
:   cmp #EXPR_WORD_LITERAL
    bne :+
    jmp getWordLimit
:   cmp #EXPR_CHARACTER_LITERAL
    bne :+
    ldz #expr::value
    nop
    lda (ptr1),z
    ldx #0
    rts
:   cmp #EXPR_NAME
    bne :+
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq :+
    stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jmp getSubrangeLimit
:   lda #0
    ldx #0
    rts
.endproc

.proc getByteLimit
    ldz #expr::value
    nop
    lda (ptr1),z
    tax                 ; put the value in X
    ldz #expr::neg
    nop
    lda (ptr1),z
    bne :+
    txa
    ldx #0
    rts
    ; Negate the value in X
    txa
    eor #$ff
    clc
    adc #1
    ldx #0
    rts
.endproc

.proc getWordLimit
    ldq ptr1
    ldz #expr::value
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    sta intOp1+1
    ldz #expr::neg
    nop
    lda (ptr1),z
    bne :+
    lda intOp1
    ldx intOp1+1
    rts
:   jsr invertInt16
    lda intOp1
    ldx intOp1+1
    rts
.endproc
