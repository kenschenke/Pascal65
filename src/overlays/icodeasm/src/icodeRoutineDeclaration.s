;
; icodeRoutineDeclaration.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

; Local variables: pointers to the heap storage that the routine's
; cleanup frees its locals from (see icodeVariableDeclarations), sized to
; the routine by countLocals.
localVarsOffset = 0
localDeclsOffset = localVarsOffset + 4
numLocalsOffset = localDeclsOffset + 4
; Parameters passed from caller
typeOffset = numLocalsOffset + 1
declOffset = typeOffset + 4

.export icodeRoutineDeclaration

.import loadStackValue, icodeRoutineDeclarations, icodeFormatLabel
.import lblRoutineEnter, icodeOper1Label, icodeWriteInstruction
.import icodeVariableDeclarations, icodeRoutineCleanup, icodeStmts
.import icodeArrayInit, formatArrayDeclLabel, icodeLabel, heapOffset

.bss

paramPtr: .res 4
paramSym: .res 4
paramType: .res 4
paramLabel: .res 20

.code

; The name is the first field of a parameter, so a parameter's address is
; also the address of its name.
.assert param_list::name = 0, error, "param_list::name must be first"

; This routine writes the declaration block for each of the routine's
; dynamic array parameters. A variable's block is written with its
; declaration, but a parameter has no declaration and SetLength needs the
; block. Only the data is written; a parameter's array comes from the caller.
; The routine's scope must be entered. Its stack frame is on the runtime
; stack, so typeOffset still applies.
.proc dynArrayParamDecls
    ldz #typeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq paramPtr

L1: ldq paramPtr
    jsr isQZero
    bne :+
    rts
:   stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq NX
    stq paramSym
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq paramType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne NX
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISDYNAMIC
    beq NX

    ; icodeLabel is reused while the block is written, so copy the label
    ldq paramSym
    jsr formatArrayDeclLabel
    ldx #0
:   lda icodeLabel,x
    sta paramLabel,x
    beq :+
    inx
    bne :-

:   lda #0
    sta heapOffset
    sta heapOffset+1
    lda #<paramLabel
    ldx #>paramLabel
    ldy #0
    ldz #0
    jsr pushQ               ; label
    ldq paramType
    jsr pushQ               ; type
    jsr pushQZero           ; value (a parameter has no literals)
    ldq paramSym
    jsr pushQ               ; declaration
    jsr icodeArrayInit

NX: ldq paramPtr
    stq ptr1
    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr1),z
    stq paramPtr
    jmp L1
.endproc

; Parameters are passed on the stack, bottom to top:
;   Declaration
;   Type
.proc icodeRoutineDeclaration
    lda #0
    jsr pushA               ; numLocals
    jsr pushQZero           ; localDecls
    jsr pushQZero           ; localVars

    ; If this is a forward declaration, skip it
    ldz #typeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISFORWARD
    beq :+
    jmp DN

    ; Handle any nested routines
:   ldz #declOffset
    jsr loadStackValue
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
    jsr icodeRoutineDeclarations

    ; If this is a unit, enter the unit's scope
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::unitSymtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr scopeEnterSymtab

:   jsr dynArrayParamDecls

    ldz #declOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblRoutineEnter
    ldx #>lblRoutineEnter
    jsr icodeFormatLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    ; Storage for the locals' cleanup, sized to the routine. A fixed 32
    ; entries once overflowed into numLocals and the routine's own
    ; declaration pointer when a routine had more locals.
    jsr loadFirstDecl
    jsr countLocals         ; entries, in A/X
    pha
    phx
    jsr heapAlloc           ; a byte each (zeroed)
    stq ptr4
    ldz #localVarsOffset
    jsr storeStackPtr4
    plx
    pla
    stx tmp2                ; four bytes each
    asl a
    rol tmp2
    asl a
    rol tmp2
    ldx tmp2
    jsr heapAlloc
    stq ptr4
    ldz #localDeclsOffset
    jsr storeStackPtr4

    ; Push the local variables onto the stack
    jsr loadFirstDecl
    stq ptr2
    ldz #localVarsOffset
    jsr loadStackValue
    stq ptr1
    ldz #localDeclsOffset
    jsr loadStackValue
    stq ptr3
    ldq ptr1
    jsr pushQ               ; localVars storage
    ldq ptr3
    jsr pushQ               ; localDecls storage
    ldq ptr2
    jsr pushQ               ; first declaration
    jsr icodeVariableDeclarations
    ldz #numLocalsOffset
    nop
    sta (stackPointer),z

    ; Process the routine's statements
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    ; If this is a unit, exit the unit's scope
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::unitSymtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr scopeExit

    ; Tear down the routine's stack frame and free its local variables
:   ldz #localVarsOffset
    jsr loadStackValue
    stq ptr1
    ldz #localDeclsOffset
    jsr loadStackValue
    stq ptr2
    ldz #numLocalsOffset
    nop
    lda (stackPointer),z
    pha
    ldq ptr1
    jsr pushQ               ; localVars
    ldq ptr2
    jsr pushQ               ; localDecls
    pla
    jsr pushA               ; numLocals
    jsr icodeRoutineCleanup
    lda #IC_RTS
    jsr icodeWriteInstruction

    ; Free the storage (none for a forward declaration)
DN: ldz #localVarsOffset
    jsr loadStackValue
    jsr isQZero
    beq :+
    jsr heapFree
:   ldz #localDeclsOffset
    jsr loadStackValue
    jsr isQZero
    beq :+
    jsr heapFree
:   jsr popQ                ; localVars
    jsr popQ                ; localDecls
    jsr popA                ; numLocals
    jsr popQ
    jsr popQ
    rts
.endproc

; This routine returns the first of the routine's declarations in Q
.proc loadFirstDecl
    ldz #declOffset
    jsr loadStackValue
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
    rts
.endproc

; This routine returns in A/X the number of entries the cleanup storage
; needs for the declarations starting with the one in Q: one for each
; constant and variable, and one more for a declaration after the last of
; them (icodeVariableDeclarations clears an entry for every declaration).
.proc countLocals
    stq ptr1
    lda #1
    sta intOp1
    lda #0
    sta intOp1+1

L1: ldq ptr1
    jsr isQZero
    beq DN
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_CONST
    beq :+
    cmp #DECL_VARIABLE
    bne NX
:   inc intOp1
    bne NX
    inc intOp1+1
NX: ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

DN: lda intOp1
    ldx intOp1+1
    rts
.endproc

; This routine stores ptr4 at offset Z of the stack frame
.proc storeStackPtr4
    ldx #0
:   lda ptr4,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
