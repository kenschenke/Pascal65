.include "asmlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

lastDeclOffset = 0
firstDeclOffset = lastDeclOffset + 4
isProgramOrUnitBlockOffset = firstDeclOffset + 4

.export parseDeclarations

.import units, addUnit, getToken, parserToken, tokenIn
.import parseUsesReferences, parseConstantDefinitions
.import parseTypeDefinitions, parseVariableDeclarations
.import parseSubroutineDeclarations, tlProcFuncStart, loadStackValue

.data

systemName: .asciiz "system"

.code

.proc parseDeclarations
    jsr pushA               ; isProgramOrUnitBlock
    jsr pushQZero           ; firstDecl
    jsr pushQZero           ; lastDecl
    ldq units
    jsr isQZero
    bne L1
    jsr getLastDecl
    jsr calcFirstDeclPointer
    lda #<systemName
    ldx #>systemName
    jsr pushAX
    ldq intOp1
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr addUnit
    jsr storeLastDecl

L1: ldz #isProgramOrUnitBlockOffset
    nop
    lda (stackPointer),z
    beq L2
    lda parserToken
    cmp #tcUSES
    bne L2
    jsr getToken
    jsr calcFirstDeclPointer
    jsr getLastDecl
    ldq intOp1
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr parseUsesReferences
    jsr storeLastDecl

L2: lda parserToken
    cmp #tcCONST
    bne L3
    jsr getToken
    jsr calcFirstDeclPointer
    jsr getLastDecl
    ldq intOp1
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr parseConstantDefinitions
    jsr storeLastDecl

L3: lda parserToken
    cmp #tcTYPE
    bne L4
    jsr getToken
    jsr calcFirstDeclPointer
    jsr getLastDecl
    ldq intOp1
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr parseTypeDefinitions
    jsr storeLastDecl

L4: lda parserToken
    cmp #tcVAR
    bne L5
    jsr getToken
    jsr calcFirstDeclPointer
    jsr getLastDecl
    ldq intOp1
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr parseVariableDeclarations
    jsr storeLastDecl

L5: lda #<tlProcFuncStart
    ldx #>tlProcFuncStart
    jsr tokenIn
    bne L6
    jsr calcFirstDeclPointer
    jsr getLastDecl
    ldq intOp1
    jsr pushQ
    ldq ptr1
    jsr pushQ
    jsr parseSubroutineDeclarations
    jsr storeLastDecl

L6: jsr popQ
    jsr popQ
    stq ptr1
    jsr popA
    ldq ptr1
    rts
.endproc

; This routine calculates the pointer to firstDecl
; on the runtime stack. The pointer is stored in intOp1.
.proc calcFirstDeclPointer
    lda #firstDeclOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq intOp1
    rts
.endproc

; Gets the lastDecl pointer and stores in ptr1
.proc getLastDecl
    ldz #lastDeclOffset
    jsr loadStackValue
    stq ptr1
    rts
.endproc

; This routine stores the value in Q to lastDecl
.proc storeLastDecl
    stq ptr1
    ldz #lastDeclOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
