.include "ast.inc"
.include "asmlib.inc"
.include "error.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseTypeSpec

.import parserToken, parseEnumerationType, parseRecordType, parseArrayType
.import parseSubrangeType, getToken, parseFileType, parserString, parserError
.import parseFuncOrProcHeader

.bss

allowSubrangeShorthand: .res 1

.code

.proc parseTypeSpec
    sta allowSubrangeShorthand

    lda parserToken
    cmp #tcBOOLEAN
    bne :+
    lda #TYPE_BOOLEAN
    jmp L9

:   cmp #tcCHAR
    bne :+
    lda #TYPE_CHARACTER
    jmp L9

:   cmp #tcBYTE
    bne :+
    lda #TYPE_BYTE
    jmp L9

:   cmp #tcSHORTINT
    bne :+
    lda #TYPE_SHORTINT
    jmp L9

:   cmp #tcINTEGER
    bne :+
    lda #TYPE_INTEGER
    jmp L9

:   cmp #tcWORD
    bne :+
    lda #TYPE_WORD
    jmp L9

:   cmp #tcLONGINT
    bne :+
    lda #TYPE_LONGINT
    jmp L9

:   cmp #tcCARDINAL
    bne :+
    lda #TYPE_CARDINAL
    jmp L9

:   cmp #tcREAL
    bne :+
    lda #TYPE_REAL
    jmp L9

:   cmp #tcSTRING
    bne :+
    lda #TYPE_STRING_VAR
    jmp L9

:   cmp #tcIdentifier
    bne :+
    jmp parserIdentifierTypeSpec

:   cmp #tcLParen
    bne :+
    jmp parseEnumerationType

:   cmp #tcARRAY
    bne :+
    jmp parseArrayType

:   cmp #tcRECORD
    bne :+
    jmp parseRecordType

:   cmp #tcFILE
    bne :+
    jmp parseFileType

:   cmp #tcTEXT
    bne :+
    lda #TYPE_TEXT
    jmp L9

:   cmp #tcPlus
    bne :+
    lda #0
    jmp parseSubrangeTypeSpec

:   cmp #tcMinus
    bne :+
    lda #0
    jmp parseSubrangeTypeSpec

:   cmp #tcString
    bne :+
    lda #0
    jmp parseSubrangeTypeSpec

:   cmp #tcNumber
    bne :+
    lda allowSubrangeShorthand
    jmp parseSubrangeTypeSpec

:   cmp #tcUpArrow
    bne :+
    jmp parsePointerTypeSpec

:   cmp #tcFUNCTION
    bne :+
    jmp parseRoutineTypeSpec

:   cmp #tcPROCEDURE
    bne :+
    jmp parseRoutineTypeSpec

:   lda #errInvalidType
    jsr parserError
    lda #TYPE_VOID
    ; fall through to L9

L9: jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    jsr pushQ
    jsr getToken
    jsr popQ
    rts
.endproc

.proc parserIdentifierTypeSpec
    ; Save the parser string on the stack
    lda #NAMELEN
    jsr pushBlock
    ldz #0
    ldx #0
:   lda parserString,x
    beq :+
    nop
    sta (stackPointer),z
    inz
    inx
    bne :-
:   nop
    sta (stackPointer),z
    jsr getToken
    lda parserToken
    cmp #tcDotDot
    bne :+
    ldq stackPointer
    jsr pushQ
    lda #0
    jsr pushA
    jsr parseSubrangeType
    stq ptr1
    lda #NAMELEN
    jsr popBlock
    ldq ptr1
    rts
:   lda #TYPE_DECLARED
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq ptr1
    ; Copy the parser string back off the stack
    lda #0
    sta tmp2                ; index for stack
    lda #type::name
    sta tmp1                ; index for type::name
:   ldz tmp2
    nop
    lda (stackPointer),z
    beq :+
    ldz tmp1
    nop
    sta (ptr1),z
    inc tmp1
    inc tmp2
    bne :-
:   ldz tmp1
    nop
    sta (ptr1),z
    ; Pop the parser string back off the stack
    lda #NAMELEN
    jsr popBlock
    ldq ptr1
    rts
.endproc

.proc parseSubrangeTypeSpec
    pha
    jsr pushQZero
    pla
    jsr pushA
    jmp parseSubrangeType
.endproc

.proc parsePointerTypeSpec
    jsr getToken
    lda #0
    jsr parseTypeSpec
    stq ptr1
    lda #TYPE_POINTER
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    ldq ptr1
    jsr pushQ               ; subtype
    jsr pushQZero           ; params
    jmp typeCreate
.endproc

.proc parseRoutineTypeSpec
    ldx #0
    lda parserToken
    cmp #tcFUNCTION
    bne :+
    ldx #1
:   txa
    jsr pushA
    lda #1
    jsr pushA
    jsr parseFuncOrProcHeader
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    ; Save the type but free the declaration
    jsr pushQ
    ldz #decl::type
    lda #0
    tax
:   nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    ldq ptr1
    jsr astFree
    jsr popQ
    rts
.endproc
