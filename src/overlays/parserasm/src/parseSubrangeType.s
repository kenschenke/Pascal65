.include "ast.inc"
.include "asmlib.inc"
.include "error.inc"
.include "parser.inc"
.include "tokenizer.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export parseSubrangeType

.import parseSubrangeLimit, condGetToken, doResync, parserToken, parserError
.import tlSubrangeLimitFollow, tlDeclarationStart, copyNameToType

allowShorthandOffset = 0
nameOffset = allowShorthandOffset + 1

.bss

subrangeType: .res 4
declaredType: .res 4
minType: .res 1
maxType: .res 1
subrangeMin: .res 4
subrangeMax: .res 4

.code

; This routine parses a subrange.
; Inputs are on runtime stack, bottom to top:
;    name - 4 bytes
;    allowShorthand - 1 byte
.proc parseSubrangeType
    ; Initialize local variables
    lda #0
    tax
    tay
    taz
    stq subrangeType
    sta minType
    sta maxType
    stq subrangeMin
    stq subrangeMax

    ; If name is non-zero then this routine was called when an identifier
    ; was encountered. The identifier is the low limit of the subrange
    ; and is an enumeration value.

    ; <min-const>
    ldz #nameOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr pushQ
    lda #<subrangeMin
    ldx #>subrangeMin
    jsr pushAX
    jsr parseSubrangeLimit
    sta minType

    ; ..
    resync tlSubrangeLimitFollow, tlDeclarationStart
    ldz #allowShorthandOffset
    nop
    lda (stackPointer),z
    beq L1
    lda parserToken
    cmp #tcDotDot
    beq L1
    ; Only one value so minValue = 0 and maxValue = value
    lda minType
    sta maxType
    ldq subrangeMin
    stq ptr1
    ldz #expr::value
    nop
    lda (ptr1),z
    sec
    sbc #1
    sta intOp1
    pha
    inz
    nop
    lda (ptr1),z
    sbc #0
    sta intOp1+1
    pha
    dez
    lda #0
    nop
    sta (ptr1),z
    inz
    nop
    sta (ptr1),z
    ; Allocate a second expr for the max
    lda #.sizeof(expr)
    ldx #0
    jsr heapAlloc
    stq subrangeMax
    stq ptr2
    ldq subrangeMin
    stq ptr1
    ; Copy the min expr to the max (ptr1 => ptr2)
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    cpz #.sizeof(expr)
    bne :-
    ; Set the the value for the max
    ldz #expr::value+1
    pla
    nop
    sta (ptr2),z
    dez
    pla
    nop
    sta (ptr2),z
    bra L2

L1: lda #tcDotDot
    ldx #errMissingDotDot
    jsr condGetToken
    ; <max-const>
    jsr pushQZero
    lda #<subrangeMax
    ldx #>subrangeMax
    jsr pushAX
    jsr parseSubrangeLimit
    sta maxType

L2: lda minType
    cmp maxType
    beq :+
    lda #errIncompatibleTypes
    jsr parserError

:   lda #TYPE_SUBRANGE
    jsr pushA
    lda #0
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    stq subrangeType
    stq ptr1
    ldz #type::min
    ldx #0
:   lda subrangeMin,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldz #type::max
    ldx #0
:   lda subrangeMax,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldz #nameOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    jsr isQZero
    beq L3
    ; Copy name from ptr2 to type.name
    jsr copyNameToType

    ; If the lower limit is a declared value (a constant),
    ; look up the underlying type and use that for the
    ; subrange's type.
L3: lda minType
    cmp #TYPE_DECLARED
    bne L4
    lda #TYPE_DECLARED
    jsr pushA               ; kind
    lda #1
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq declaredType
    ldq subrangeType
    stq ptr1
    ldz #type::subtype
    ldx #0
:   lda declaredType,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldz #nameOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldq declaredType
    stq ptr1
    jsr copyNameToType
    bra L5
L4: lda minType
    jsr pushA
    lda #0
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    stq ptr2
    ldq subrangeType
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

L5: jsr popQ
    jsr popA
    ldq subrangeType
    rts
.endproc
