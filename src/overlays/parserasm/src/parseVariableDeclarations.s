.include "ast.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "error.inc"
.include "tokenizer.inc"
.include "zeropage.inc"
.include "4510macros.inc"

lastDeclOffset = 0
firstDeclOffset = 4

.export parseVariableDeclarations, parseFieldDeclarations

.import parserToken, doResync, condGetToken, parseTypeSpec, parseIdSublist
.import appendDecl, parseExpression, getToken
.import tlSublistFollow, tlDeclarationFollow, tlDeclarationStart
.import tlFieldDeclFollow, tlStatementStart

.bss

newType: .res 4
valueExpr: .res 4
lastId: .res 4

.code

.proc parseFieldDeclarations
    ; Calculate address of next stack variable (firstId)
    lda #4
    sta intOp1
    lda #0
    sta intOp1+1
    sta intOp1+2
    sta intOp1+3
    ldq stackPointer
    sec
    sbcq intOp1
    stq ptr1
    jsr pushQZero       ; firstDecl
    ldq ptr1
    jsr pushQ           ; firstDecl address
    jsr pushQZero       ; lastDecl
    lda #0
    jsr pushA           ; isVarDecl
    jsr parseVarOrFieldDecls
    jsr popQ            ; pop lastDecl
    jsr popQ            ; pop firstDecl address
    jsr popQ            ; pop firstDecl
    rts
.endproc

.proc parseVariableDeclarations
    lda #1
    jsr pushA           ; isVarDecl
    jsr parseVarOrFieldDecls
    jsr popQ                ; pop lastDecl
    stq ptr1                ; save lastDecl
    jsr popQ                ; pop firstDecl pointer
    ldq ptr1                ; load lastDecl
    rts
.endproc

.proc parseVarOrFieldDecls
    jsr popA                    ; Pop isVarDecl
    pha                         ; Keep it on the CPU stack

    ; Loop to parse a list of variable or field declarations
L1: lda parserToken
    cmp #tcIdentifier
    beq :+
    jmp L9

:   ldx #DECL_VARIABLE
    pla                         ; Peek at the isVarDecl value
    pha
    bne :+
    ldx #DECL_TYPE
:   txa
    jsr parseIdSublist
    jsr pushQ                   ; Store firstId on the stack

    ; colon
:   resync tlSublistFollow, tlDeclarationFollow
    lda #tcColon
    ldx #errMissingColon
    jsr condGetToken

    ; <type>
    lda #0
    jsr parseTypeSpec
    stq newType

    ; =
    lda parserToken
    cmp #tcEqual
    bne L2
    jsr getToken
    lda #1
    jsr parseExpression
    stq valueExpr
    bra L3
L2: lda #0
    tax
    tay
    taz
    stq valueExpr

L3: ; Now loop to assign the type to each identifier in the sublist.
    jsr popQ            ; firstId
    stq ptr1
    jsr pushQ

L4: ldq ptr1
    jsr isQZero
    beq L5
    stq lastId
    ; Set type to newType
    ldz #decl::type
    ldx #0
:   lda newType,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ; Set value to valueExpr
    ldz #decl::value
    ldx #0
:   lda valueExpr,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ; Set ptr1 to decl's next
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L4

L5: ; Append the declaration
    jsr popQ            ; firstId
    stq ptr2
    jsr appendDecl
    ; Set lastDecl to lastId
    ldz #lastDeclOffset
    ldx #0
:   lda lastId,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Semicolon
    ; END for record field declaration
    pla
    pha                     ; Peek at isVarDecl
    beq L6
    ; isVarDecl is non-zero
    resync tlDeclarationFollow, tlStatementStart
    lda #tcSemicolon
    ldx #errMissingSemicolon
    jsr condGetToken
    bra L7
L6: ; isVarDecl is zero
    resync tlFieldDeclFollow
    lda parserToken
    cmp #tcEND
    beq L7
    lda #tcSemicolon
    ldx #errMissingSemicolon
    jsr condGetToken
L7: ; skip extra semicolons
:   lda parserToken
    cmp #tcSemicolon
    bne :+
    jsr getToken
    bra :-
:   resync tlDeclarationFollow, tlDeclarationStart, tlStatementStart
    jmp L1

L9: pla                     ; Discard isVarDecl
    ; leave lastDecl and firstDecl on stack
    rts
.endproc
