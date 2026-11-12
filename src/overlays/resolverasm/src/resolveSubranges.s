;
; resolveSubranges.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveSubranges routine
;
; The limits of a subrange must be of the same general type: both integers,
; both characters or both values of the same enumeration. A limit can be a
; constant or an enumeration value, so the parser can't check them. This
; routine checks them, and gives an integer subrange a subtype that holds
; both limits: the narrowest of Byte, Word and Cardinal when the low limit
; isn't negative, and of ShortInt, Integer and LongInt when it is. A
; character subrange gets the Char subtype. An enumeration subrange keeps
; the parser's subtype, a declared type named after its low limit (see
; getBaseType).

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export resolveSubranges

.import resolverError

LIMIT_INT = 0
LIMIT_CHAR = 1
LIMIT_ENUM = 2
LIMIT_BAD = $ff                 ; Reported already, or by the parser

.bss

arrType: .res 4                 ; The array whose index is being looked at
subType: .res 4                 ; The subrange being resolved
limKind: .res 1                 ; LIMIT_* of the last limit (getLimit)
limVal: .res 4                  ; Its value, for an integer or character
limDecl: .res 4                 ; Its declaration, for an enumeration value
minKind: .res 1                 ; The same for the low limit
minVal: .res 4
minDecl: .res 4
chk: .res 4                     ; The value fitsSigned checks

.code

; This routine resolves the subranges in a declaration's type: the type
; itself, or an array's index types and element type. The type is in Q
; and can be NULL. It must run before the declaration's symbol gets its
; copy of the type.
.proc resolveSubranges
L1: jsr isQZero
    bne :+
    rts
:   stq arrType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_SUBRANGE
    bne :+
    ldq arrType
    jmp resolveSubrange
:   cmp #TYPE_ARRAY
    beq :+
    rts
    ; A dynamic array's index (0..-1) is made by the parser
:   ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISDYNAMIC
    bne L2
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_SUBRANGE
    bne L2
    ldq ptr1
    jsr resolveSubrange
    ; The element type, which is the next index's array for an array of
    ; more than one index
L2: ldq arrType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
.endproc

; This routine checks the limits of the subrange type in Q and sets its
; subtype.
.proc resolveSubrange
    stq subType
    stq ptr1
    ldz #type::min
    neg
    neg
    nop
    lda (ptr1),z
    jsr getLimit
    lda limKind
    cmp #LIMIT_BAD
    beq DN
    sta minKind
    ldq limVal
    stq minVal
    ldq limDecl
    stq minDecl

    ldq subType
    stq ptr1
    ldz #type::max
    neg
    neg
    nop
    lda (ptr1),z
    jsr getLimit
    lda limKind
    cmp #LIMIT_BAD
    beq DN

    cmp minKind
    bne ER
    cmp #LIMIT_ENUM
    beq EN
    cmp #LIMIT_CHAR
    beq CH
    jsr intSubtypeKind
    jmp setSubtype
CH: lda #TYPE_CHARACTER
    jmp setSubtype

EN: jsr isSameEnum
    beq DN
ER: lda #errIncompatibleTypes
    jmp resolverError

DN: rts
.endproc

; This routine evaluates the subrange limit expression in Q. It sets
; limKind, and limVal or limDecl. A constant is evaluated by its value.
; A name that isn't a constant or an enumeration value is an error.
.proc getLimit
    stq limDecl                 ; Keep Q (limDecl is set for an enumeration)
    lda #LIMIT_BAD
    sta limKind
    lda #0
    ldx #3
:   sta limVal,x
    dex
    bpl :-
    ldq limDecl

L1: jsr isQZero
    bne :+
    rts                         ; No limit: the parser reported it
:   stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_CHARACTER_LITERAL
    bne :+
    ldz #expr::value
    nop
    lda (ptr1),z
    sta limVal
    lda #LIMIT_CHAR
    sta limKind
    rts
:   ldx #1
    cmp #EXPR_BYTE_LITERAL
    beq LV
    ldx #2
    cmp #EXPR_WORD_LITERAL
    beq LV
    ldx #4
    cmp #EXPR_DWORD_LITERAL
    beq LV
    cmp #EXPR_NAME
    beq LN
    rts                         ; Anything else was reported by the parser

    ; An integer literal of X bytes, negated if its neg flag is set
LV: stx tmp1
    ldz #expr::value
    ldx #0
:   nop
    lda (ptr1),z
    sta limVal,x
    inz
    inx
    cpx tmp1
    bne :-
    ldz #expr::neg
    nop
    lda (ptr1),z
    beq :+
    ldq limVal
    stq intOp1                  ; intOp1 and intOp2 are the 32-bit value
    jsr invertInt32
    ldq intOp1
    stq limVal
:   lda #LIMIT_INT
    sta limKind
    rts

    ; A name: a constant or an enumeration value
LN: ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jmp resolverError
:   stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq NA
    stq ptr2
    ldz #decl::kind
    nop
    lda (ptr2),z
    cmp #DECL_CONST
    bne :+
    ldz #decl::value            ; Evaluate the constant's value
    neg
    neg
    nop
    lda (ptr2),z
    jmp L1

    ; An enumeration value's symbol has an enumeration value type and its
    ; declaration has the value. (getBaseType can change the kind of the
    ; type to an enumeration.)
:   ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq NA
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_ENUMERATION_VALUE
    beq :+
    cmp #TYPE_ENUMERATION
    bne NA
:   ldz #decl::value
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq NA
    ldq ptr2
    stq limDecl
    lda #LIMIT_ENUM
    sta limKind
    rts

NA: lda #errNotAConstantIdentifier
    jmp resolverError
.endproc

; This routine sets the Z flag if the enumeration values in minDecl and
; limDecl are of the same enumeration. An enumeration's values are a chain
; of declarations, so one of them follows the other in the chain.
.proc isSameEnum
    ldq minDecl
    stq ptr1
    ldq limDecl
    stq ptr2
    jsr follows
    beq DN
    ldq limDecl
    stq ptr1
    ldq minDecl
    stq ptr2
    jsr follows
DN: rts
.endproc

; This routine sets the Z flag if the declaration in ptr2 is the one in
; ptr1 or one after it in its chain.
.proc follows
L1: ldx #3
:   lda ptr1,x
    cmp ptr2,x
    bne :+
    dex
    bpl :-
    lda #0                      ; Found: set Z
    rts
:   ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr isQZero
    bne L1
    lda #1                      ; End of the chain: clear Z
    rts
.endproc

; This routine returns in A the integer type kind that holds the limits in
; minVal and limVal.
.proc intSubtypeKind
    lda minVal+3
    bmi NG

    ; The low limit isn't negative: Byte, Word or Cardinal
    lda limVal+3
    ora limVal+2
    bne :+
    lda limVal+1
    bne :++
    lda #TYPE_BYTE
    rts
:   lda #TYPE_CARDINAL
    rts
:   lda #TYPE_WORD
    rts

    ; The low limit is negative: ShortInt, Integer or LongInt
NG: lda #1
    jsr bothFit
    bne :+
    lda #TYPE_SHORTINT
    rts
:   lda #2
    jsr bothFit
    bne :+
    lda #TYPE_INTEGER
    rts
:   lda #TYPE_LONGINT
    rts
.endproc

; This routine sets the Z flag if minVal and limVal both fit in a signed
; number of A (1 or 2) bytes.
.proc bothFit
    pha
    ldq minVal
    stq chk
    pla
    pha
    jsr fitsSigned
    bne :+
    ldq limVal
    stq chk
    pla
    jmp fitsSigned
:   pla
    lda #1                      ; Clear Z
    rts
.endproc

; This routine sets the Z flag if the value in chk fits in a signed number
; of A (1 or 2) bytes: every byte above them is the sign of the top one.
.proc fitsSigned
    tax
    lda chk-1,x
    and #$80
    beq :+
    lda #$ff
:   cmp chk,x
    bne DN
    inx
    cpx #4
    bne :-
    lda #0                      ; Set Z
DN: rts
.endproc

; This routine replaces the subrange's subtype with a new type of the kind
; in A.
.proc setSubtype
    pha
    ldq subType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr freeType                ; NULL is all right
    pla
    jsr pushA                   ; kind
    lda #0
    jsr pushA                   ; isConst
    jsr pushQZero               ; subtype
    jsr pushQZero               ; params
    jsr typeCreate
    stq ptr2
    ldq subType
    stq ptr1
    ldz #type::subtype
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
