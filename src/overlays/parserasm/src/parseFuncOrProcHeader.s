.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

isFuncOffset = 1
isRtnTypeOffset = 0

.export parseFuncOrProcHeader

.import getToken, parserToken, parserString, doResync, parseFormalParamList
.import tlFuncIdFollow, tlProgProcIdFollow, parserError
.import tlDeclarationStart, tlStatementStart

.bss

name: .res 4
params: .res 4
returnType: .res 4
subtype: .res 4
isPtr: .res 1

.code

.proc parseFuncOrProcHeader
    jsr getToken

    lda #0
    tax
    tay
    taz
    stq name
    stq params
    stq returnType

    ; <id>
    lda parserToken
    cmp #tcIdentifier
    bne :+
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq name
    jsr getToken
    bra L1
:   ldz #isRtnTypeOffset
    nop
    lda (stackPointer),z
    bne L1
    lda #errMissingIdentifier
    jsr parserError

    ; ( or : or ;
L1: ldz #isFuncOffset
    nop
    lda (stackPointer),z
    beq :+
    resync tlFuncIdFollow, tlDeclarationStart, tlStatementStart
    bra L2
:   resync tlProgProcIdFollow, tlDeclarationStart, tlStatementStart

    ; Optional <id-list>
L2: lda parserToken
    cmp #tcLParen
    bne :+
    lda #1
    jsr parseFormalParamList
    stq params

:   ldz #isFuncOffset
    nop
    lda (stackPointer),z
    beq L3
    jsr parseFuncReturnType

L3: ldx #TYPE_PROCEDURE
    ldz #isFuncOffset
    nop
    lda (stackPointer),z
    beq :+
    ldx #TYPE_FUNCTION
:   txa
    jsr pushA                   ; kind
    lda #0
    jsr pushA                   ; isConst
    ldq returnType
    jsr pushQ                   ; subtype (return type)
    ldq params
    jsr pushQ                   ; params
    jsr typeCreate
    stq subtype

    ldz #isRtnTypeOffset
    nop
    lda (stackPointer),z
    beq :+
    ; This is a routine pointer - the type just created is a subtype
    ; of the routine pointer type
    lda #TYPE_ROUTINE_POINTER
    jsr pushA                   ; kind
    lda #0
    jsr pushA                   ; isConst
    ldq subtype
    jsr pushQ                   ; subtype
    jsr pushQZero               ; params
    jsr typeCreate
    stq subtype
:   lda #DECL_TYPE
    jsr pushA                   ; kind
    ldq name
    jsr pushQ                   ; name
    ldq subtype
    jsr pushQ                   ; type
    jsr pushQZero               ; value
    jsr declCreate
    stq ptr1
    jsr popA                    ; pop isRtnType parameter off stack
    jsr popA                    ; pop isFunc parameter off stack
    ldq ptr1
    rts
.endproc

.proc parseFuncReturnType
    lda parserToken
    cmp #tcColon
    beq :+
    lda #errMissingColon
    jmp parserError
    rts

:   jsr getToken
    lda parserToken
    cmp #tcIdentifier
    bne L1
    ; The return type must be a declared type
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    stq ptr1
    lda #TYPE_DECLARED
    jsr pushA                   ; kind
    ldq ptr1
    jsr pushQ                   ; name
    jsr pushQZero               ; type
    jsr pushQZero               ; value
    jsr declCreate
    stq returnType
    jmp getToken

L1: lda #0
    sta isPtr
    lda parserToken
    cmp #tcUpArrow
    bne :+
    jsr getToken
    lda #1
    sta isPtr

    ; The return type should be one of the pre-defined Pascal types
:   lda parserToken
    cmp #tcBYTE
    bne :+
    lda #TYPE_BYTE
    bra L2
:   cmp #tcSHORTINT
    bne :+
    lda #TYPE_SHORTINT
    bra L2
:   cmp #tcBOOLEAN
    bne :+
    lda #TYPE_BOOLEAN
    bra L2
:   cmp #tcCHAR
    bne :+
    lda #TYPE_CHARACTER
    bra L2
:   cmp #tcWORD
    bne :+
    lda #TYPE_WORD
    bra L2
:   cmp #tcINTEGER
    bne :+
    lda #TYPE_INTEGER
    bra L2
:   cmp #tcLONGINT
    bne :+
    lda #TYPE_LONGINT
    bra L2
:   cmp #tcCARDINAL
    bne :+
    lda #TYPE_CARDINAL
    bra L2
:   cmp #tcREAL
    bne :+
    lda #TYPE_REAL
    bra L2
:   cmp #tcSTRING
    bne :+
    lda #TYPE_STRING_VAR
    bra L2
:   lda #errIncompatibleTypes
    jsr parserError
    lda #TYPE_VOID

L2: jsr pushA                   ; kind
    lda #0
    jsr pushA                   ; isConst
    jsr pushQZero               ; subtype
    jsr pushQZero               ; params
    jsr typeCreate
    stq returnType
    lda isPtr
    beq :+
    lda #TYPE_POINTER           ; kind
    lda #0
    jsr pushA                   ; isConst
    ldq returnType
    jsr pushQ                   ; subtype
    jsr pushQZero               ; params
    jsr typeCreate
    stq returnType

:   jmp getToken
.endproc
