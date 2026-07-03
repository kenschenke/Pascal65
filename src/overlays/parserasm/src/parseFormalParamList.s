.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseFormalParamList

.import getToken, parserToken, doResync, condGetToken, parseArrayType, parserString
.import tlIdentifierStart, tlIdentifierFollow, tlSublistFollow, tlDeclarationFollow
.import tlFormalParmsFollow, parserError

.bss

isByRef: .res 1
pointerParam: .res 1
firstId: .res 4
lastId: .res 4
paramType: .res 4
firstParam: .res 4
lastParam: .res 4
firstType: .res 1

.code

.proc parseFormalParamList
    lda #0
    tax
    tay
    taz
    stq firstParam
    stq lastParam

    jsr getToken

    ; Loop to parse parameter declarations separated by semicolons
    ; i, j, k : integer; a, b, c : character; r, s, t : real
L1: lda #0
    sta isByRef
    lda parserToken
    cmp #tcIdentifier
    beq L2
    cmp #tcVAR
    beq :+
    jmp L9
:   lda #1
    sta isByRef
    jsr getToken

    ; Loop to parse the comma-separated sublist of parameter ids
L2: jsr parseParamSubList

    ; colon
    resync tlSublistFollow, tlDeclarationFollow
    lda #tcColon
    ldx #errMissingColon
    jsr condGetToken

    lda parserToken
    cmp #tcUpArrow
    bne :+
    lda #1
    sta pointerParam
    jsr getToken
    
    ; <id-type>
:   jsr parseParamType
    lda #1
    sta firstType

    ; Loop to assign the offset and type to each
    ; param in the list.
    ldq firstId
    stq ptr1
L5: ldq ptr1
    jsr pushQ
    jsr getParamType
    stq ptr2
    jsr popQ
    stq ptr1
    ldz #param_list::type
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr isQZero
    bne L5

    ; Link the sublist to the previous sublist
    ldq firstParam
    jsr isQZero
    beq L6
    ; firstParam is non-null
    ldq lastParam
    stq ptr1
    ldz #param_list::next
    ldx #0
:   lda firstId,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    bra L7
    ; firstParam is null
L6: ldq firstId
    stq firstParam

L7: ldq lastId
    stq lastParam

    ; Semicolon or )
    resync tlFormalParmsFollow, tlDeclarationFollow
    lda parserToken
    cmp #tcIdentifier
    beq :+
    cmp #tcVAR
    bne L8
:   lda #errMissingSemicolon
    jsr parserError
    jmp L1
L8: lda parserToken
    cmp #tcSemicolon
    bne :+
    jsr getToken
    bra L8

:   jmp L1

    ; right paren
L9: lda #tcRParen
    ldx #errMissingRightParen
    jsr condGetToken

    ldq firstParam
    rts
.endproc

; This routine returns either:
;    A clone of paramType
;
;    or
;
;    paramType if firstType is non-zero.
.proc getParamType
    lda firstType
    beq L1

    lda #0
    sta firstType
    ldq paramType
    rts

L1: ldq paramType
    jsr typeClone
    rts
.endproc

.proc parseParamSubList
    lda #0
    tax
    tay
    taz
    sta pointerParam
    stq firstId
    stq lastId

L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    rts
:   lda #<parserString
    ldx #>parserString
    jsr paramListCreate
    stq ptr2
    ldq firstId
    jsr isQZero
    bne :+
    ; firstId is null
    ldq ptr2
    stq firstId
    bra L2
:   ldq lastId
    stq ptr1
    ldz #param_list::next
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
L2: ldq ptr2
    stq lastId

    ; Comma
    jsr getToken
    resync tlIdentifierFollow
    lda parserToken
    cmp #tcComma
    bne L5
    ; Saw comma.
    ; Skip extra commas and look for an identifier
L3: jsr getToken
    resync tlIdentifierStart, tlIdentifierFollow
    lda parserToken
    cmp #tcComma
    bne L4
    lda #errMissingIdentifier
    jsr parserError
    bra L3
L4: cmp #tcIdentifier
    beq :+
    lda #errMissingIdentifier
    jsr parserError
    jmp L1
L5: cmp #tcIdentifier
    bne :+
    lda #errMissingComma
    jsr parserError
:   jmp L1
.endproc

.proc parseParamType
    lda parserToken
    cmp #tcIdentifier
    bne L1
    lda #TYPE_DECLARED
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq paramType
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq ptr2
    ldq paramType
    stq ptr1
    ldz #type::name
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    jsr setByIsRefFlag
    jsr getToken
    jmp L8

L1: cmp #tcARRAY
    bne L2
    jsr parseArrayType
    stq paramType
    stq ptr1
    jsr setByIsRefFlag
    jmp L8

L2: lda parserToken
    cmp #tcBOOLEAN
    bne :+
    lda #TYPE_BOOLEAN
    bra L3
:   cmp #tcCHAR
    bne :+
    lda #TYPE_CHARACTER
    bra L3
:   cmp #tcBYTE
    bne :+
    lda #TYPE_BYTE
    bra L3
:   cmp #tcSHORTINT
    bne :+
    lda #TYPE_SHORTINT
    bra L3
:   cmp #tcWORD
    bne :+
    lda #TYPE_WORD
    bra L3
:   cmp #tcINTEGER
    bne :+
    lda #TYPE_INTEGER
    bra L3
:   cmp #tcCARDINAL
    bne :+
    lda #TYPE_CARDINAL
    bra L3
:   cmp #tcLONGINT
    bne :+
    lda #TYPE_LONGINT
    bra L3
:   cmp #tcREAL
    bne :+
    lda #TYPE_REAL
    bra L3
:   cmp #tcSTRING
    bne :+
    lda #TYPE_STRING_VAR
    bra L3
:   cmp #tcFILE
    bne :+
    lda #TYPE_FILE
    bra L3
:   cmp #tcTEXT
    bne :+
    lda #TYPE_TEXT
    bra L3
:   lda #errInvalidType
    jsr parserError
    lda #TYPE_VOID
L3: jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq paramType
    stq ptr1
    jsr setByIsRefFlag
    jsr getToken

L8: lda pointerParam
    bne :+
    rts
    lda #TYPE_POINTER       ; kind
    jsr pushA
    lda #0
    jsr pushA               ; isConst
    ldq paramType
    jsr pushQ               ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq paramType
    stq ptr1
    jmp setByIsRefFlag
.endproc

; This routine sets the ISBYREF flag in the type structure
; in ptr1
.proc setByIsRefFlag
    ldz #type::flags
    lda isByRef
    beq :+
    ; isByRef is true
    nop
    lda (ptr1),z
    ora #TYPE_FLAG_ISBYREF
    nop
    sta (ptr1),z
    rts
:   ; isByRef is false
    lda #TYPE_FLAG_ISBYREF
    eor #$ff
    sta tmp1
    nop
    lda (ptr1),z
    and tmp1
    nop
    sta (ptr1),z
    rts
.endproc
