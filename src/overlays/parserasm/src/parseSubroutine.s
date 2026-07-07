.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

isFuncOffset = 4
subOffset = 0

.export parseSubroutine

.import parserError, calcNamePtr

.bss

; These should only be used at the end of parseSubroutine while
; creating a declaration for the function's return type.
; The remainder of the routine needs to store everything on
; the runtime stack to be re-entrant.

declPtr: .res 4
routineType: .res 4
returnType: .res 4
returnDecl: .res 4

.data

strForward: .asciiz "forward"

.code

.import parserToken, parseFuncOrProcHeader, doResync, isInUnitInterface
.import tokenIn, getToken, parserString, parseBlock
.import tlHeaderFollow, tlDeclarationStart, tlStatementStart

.proc parseSubroutine
    ; <routine-header>
    lda #0
    ldx parserToken
    cpx #tcFUNCTION
    bne :+
    lda #1
:   pha
    jsr pushA                   ; store isFunc as a local variable
    pla
    jsr pushA                   ; pass isFunc to parseFuncOrProcHeader
    lda #0
    jsr pushA                   ; second parameter for parseFuncOrProcHeader
    jsr parseFuncOrProcHeader
    jsr pushQ

    ; semicolon
    resync tlHeaderFollow, tlDeclarationStart, tlStatementStart
    lda parserToken
    cmp #tcSemicolon
    bne :+
    jsr getToken
    bra L1
:   lda #<tlDeclarationStart
    ldx #>tlDeclarationStart
    jsr tokenIn
    beq :+
    lda #<tlStatementStart
    ldx #>tlStatementStart
    jsr tokenIn
    bne L1
:   lda #errMissingSemicolon
    jsr parserError

L1: ldz #subOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ; <block> or forward
    lda isInUnitInterface
    bne :+
    jsr isForward
    bne L3
:   lda isInUnitInterface
    bne :+
    ldq ptr2
    jsr pushQ
    jsr getToken
    jsr popQ
    stq ptr2
:   ldz #type::flags
    nop
    lda (ptr2),z
    ora #TYPE_FLAG_ISFORWARD
    nop
    sta (ptr2),z
    bra L4

    ; Not a forward declaration
L3: lda #0
    jsr parseBlock
    stq ptr2
    jsr popA                ; discard the isLibrary value
    ldz #subOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::code
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; If a function, add a variable to the function's local scope for the
    ; return value.
L4: ldz #isFuncOffset
    nop
    lda (stackPointer),z
    bne :+
    jmp L9
:   ldz #subOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::flags
    nop
    lda (ptr2),z
    and #TYPE_FLAG_ISFORWARD
    beq :+
    jmp L9

    ; Create a new declaration for the return value.
:   ldz #subOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq declPtr
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    stq routineType
    ; Create the return type
    ldz #type::kind
    nop
    lda (ptr2),z
    jsr pushA                   ; kind
    lda #0
    jsr pushA                   ; isConst
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    jsr pushQ                   ; subtype
    jsr pushQZero               ; params
    jsr typeCreate
    stq returnType
    stq ptr2
    ; Set the ISRETVAL flag
    ldz #type::flags
    lda #TYPE_FLAG_ISRETVAL
    nop
    sta (ptr2),z
    ldq routineType
    stq ptr2
    ldz #type::name
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq L5
    ; Clone the routine's return type name
    jsr nameClone
    stq ptr2
    ldq returnType
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
L5: ldq declPtr
    ldz #decl::name
    jsr calcNamePtr
    stq ptr1
    lda #DECL_VARIABLE
    jsr pushA                   ; kind
    ldq ptr1
    jsr pushQ                   ; name
    ldq returnType
    jsr pushQ                   ; type
    jsr pushQZero               ; value
    jsr declCreate
    stq returnDecl

    ; Append the return value declaration node to the routine's declarations
    jsr appendReturnValDecl

L9: jsr popQ
    stq ptr1
    jsr popA
    ldq ptr1
    rts
.endproc

.proc isForward
    ldx #0
L1: lda parserString,x
    beq L2
    cmp strForward,x
    bne L3
    inx
    bne L1
L2: lda strForward,x
L3: rts
.endproc

.proc appendReturnValDecl
    ldq returnDecl
    stq ptr2

    ldq declPtr
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L1
    ldz #stmt::decl
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts

    ; Walk through the routine's declarations.
L1: stq ptr1
L2: ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L3
    stq ptr1
    bra L2

    ; Set the return declaration to the last decl's "next"
L3: ldz #decl::next
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
