;
; evalConstInt.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Computes the value of an integer expression made only of literals and
; constants, so a precision or sign warning can look at the value instead
; of the type. A positive literal under 128 is a ShortInt, so 4 * 12 is an
; Integer, which a Word can't hold every value of, but 48 fits.

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export evalConstInt, constIntFits, constSign, constMag

.import isSigned
.import followPtr1, loadQPtr1

; Deep enough for a chain of constants, such as a + b + c + d + e, and
; shallow enough for the CPU stack (each level is two JSRs)
MAX_DEPTH = 16

MULTINA = $d770
MULTINB = $d774
MULTOUT = $d778

.bss

constSign: .res 1           ; 1 if the value is negative
constMag: .res 4            ; The value without its sign
leftSign: .res 1
leftMag: .res 4
opKind: .res 1
depth: .res 1
fitKind: .res 1
fitIdx: .res 1

.data

; The largest value of each kind (TYPE_BYTE to TYPE_LONGINT), for a
; positive value. A negative one can be one more, for a signed kind.
maxMags:
    .dword $ff              ; Byte
    .dword $7f              ; ShortInt
    .dword $ffff            ; Word
    .dword $7fff            ; Integer
    .dword $ffffffff        ; Cardinal
    .dword $7fffffff        ; LongInt

.code

; Q holds an expression. If it's an integer expression of literals,
; constants, unary minus, addition, subtraction and multiplication, this
; returns with the carry clear and its value in constSign and constMag.
; Otherwise, or if a step doesn't fit 32 bits, it returns with the carry
; set. Changes ptr1.
.proc evalConstInt
    stq ptr1
    lda #0
    sta depth
    ; Fall through to evalNode
.endproc

; Evaluates the expression in ptr1, as evalConstInt does
.proc evalNode
    lda depth
    cmp #MAX_DEPTH
    bcs DN                  ; Branch if too deep (carry is set)
    inc depth
    jsr evalKind
    dec depth               ; Keeps the carry
DN: rts
.endproc

.proc evalKind
    ldq ptr1
    jsr isQZero
    bne :+
    jmp NO                  ; Branch if no expression
:   ldz #expr::kind
    nop
    lda (ptr1),z
    ldx #1
    cmp #EXPR_BYTE_LITERAL
    beq LT
    ldx #2
    cmp #EXPR_WORD_LITERAL
    beq LT
    ldx #4
    cmp #EXPR_DWORD_LITERAL
    beq LT
    cmp #EXPR_NAME
    beq NM
    cmp #EXPR_NEGATE
    beq NG
    cmp #EXPR_ADD
    beq :+
    cmp #EXPR_SUB
    beq :+
    cmp #EXPR_MUL
    beq :+
    jmp NO
:   jmp BI

    ; A literal: X bytes of value, made negative by its neg flag
LT: lda #0
    sta constMag
    sta constMag+1
    sta constMag+2
    sta constMag+3
    ldy #0
    ldz #expr::value
:   nop
    lda (ptr1),z
    sta constMag,y
    iny
    inz
    dex
    bne :-
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq :+
    lda #1
:   sta constSign
    jmp normalize

N2: sec                     ; Not a constant
    rts

    ; A name: the value of the constant it names
NM: ldz #expr::node
    jsr loadPtr1
    beq N2
    ldz #symbol::decl
    jsr loadPtr1
    beq N2
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_CONST
    bne N2
    ldz #decl::value
    jsr loadPtr1
    beq N2
    jmp evalNode

    ; Unary minus of a non-literal
NG: ldz #expr::left
    jsr loadPtr1
    jsr evalNode
    bcs DN
    jmp flipSign

    ; Addition, subtraction or multiplication. The runtime stack keeps
    ; the operation and the right operand while the left is evaluated.
BI: jsr pushA
    ldz #expr::right
    jsr loadQPtr1
    jsr pushQ
    ldz #expr::left
    jsr loadPtr1
    jsr evalNode
    bcc :+
    jsr popQ                ; The left isn't a constant
    jsr popA
    jmp NO
:   jsr popQ
    stq ptr1                ; The right operand
    ldq constMag
    jsr pushQ
    lda constSign
    jsr pushA
    jsr evalNode
    php
    jsr popA
    sta leftSign
    jsr popQ
    stq leftMag
    jsr popA
    sta opKind
    plp
    bcs DN                  ; Branch if the right isn't a constant
    lda opKind
    cmp #EXPR_MUL
    beq multiply
    cmp #EXPR_ADD
    beq add
    jsr flipSign            ; Subtraction adds the negated right
    jmp add

NO: sec
DN: rts
.endproc

; Loads the pointer at offset Z of the structure in ptr1 into ptr1. Clears
; the Z flag unless it's null.
.proc loadPtr1
    jsr followPtr1
    jmp isQZero
.endproc

; Negates the value (zero stays positive). Returns with the carry clear.
.proc flipSign
    lda constSign
    eor #1
    sta constSign
    ; Fall through to normalize
.endproc

; Makes a zero positive and returns with the carry clear
.proc normalize
    ldq constMag
    jsr isQZero
    bne :+
    lda #0
    sta constSign
:   clc
    rts
.endproc

; constSign/constMag = leftSign/leftMag + constSign/constMag
.proc add
    lda leftSign
    cmp constSign
    bne DF                  ; Branch if the signs differ
    ldq leftMag
    clc
    adcq constMag
    bcs NO                  ; Branch if over 32 bits
    stq constMag
    jmp normalize

DF: ldq leftMag
    sec
    sbcq constMag
    bcc :+                  ; Branch if the right's magnitude is larger
    stq constMag
    lda leftSign            ; The left's sign
    sta constSign
    jmp normalize
:   ldq constMag
    sec
    sbcq leftMag
    stq constMag            ; The right's sign
    jmp normalize

NO: sec
    rts
.endproc

; constSign/constMag = leftSign/leftMag * constSign/constMag, if both
; magnitudes fit 16 bits
.proc multiply
    lda leftMag+2
    ora leftMag+3
    ora constMag+2
    ora constMag+3
    bne NO                  ; Branch if an operand is over 16 bits
    ldq leftMag
    stq MULTINA
    ldq constMag
    stq MULTINB
    lda leftSign
    eor constSign
    sta constSign
    ldq MULTOUT
    stq constMag
    jmp normalize
NO: sec
    rts
.endproc

; Sets the Z flag if the value from evalConstInt fits the integer kind
; in A
.proc constIntFits
    sta fitKind
    sec
    sbc #TYPE_BYTE          ; The kind's dword in maxMags
    asl a
    asl a
    sta fitIdx              ; ldq changes X
    lda fitKind
    jsr isSigned
    beq SG                  ; Branch if a signed kind
    lda constSign
    bne NO                  ; A negative value doesn't fit unsigned
    bra CM
SG: lda constSign
    beq CM                  ; Branch if positive
    ; A negative value fits if its magnitude less 1 does
    ldq constMag
    deq
    bra CQ
CM: ldq constMag
CQ: stq leftMag
    ldx fitIdx
    sec                     ; The largest less the magnitude
    lda maxMags,x
    sbc leftMag
    lda maxMags+1,x
    sbc leftMag+1
    lda maxMags+2,x
    sbc leftMag+2
    lda maxMags+3,x
    sbc leftMag+3
    bcc NO                  ; Branch if the magnitude is over the largest
    lda #0
    rts
NO: lda #1
    rts
.endproc
