;
; icodeUnitDeclarations.s
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

.export icodeUnitDeclarations

.import units, icodeVariableDeclarations

.bss

thisUnit: .res 4
localVars: .res MAX_LOCAL_VARS
stmtPtr: .res 4
numToPop: .res 1

.code

.proc icodeUnitDeclarations
    ldq units
    stq thisUnit

    lda #0
    sta numToPop
    
    ; Loop through the units
L1: ldq thisUnit
    jsr isQZero
    bne :+
    lda numToPop
    rts

:   ldq thisUnit
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq stmtPtr
    stq ptr1

    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda #<localVars
    ldx #>localVars
    ldy #0
    ldz #0
    stq ptr1
    jsr popQ
    jsr icodeVariableDeclarations
    clc
    adc numToPop
    sta numToPop

    ldq stmtPtr
    stq ptr1
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda #<localVars
    ldx #>localVars
    ldy #0
    ldz #0
    stq ptr1
    jsr popQ
    jsr icodeVariableDeclarations
    clc
    adc numToPop
    sta numToPop

    ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq thisUnit
    jmp L1
.endproc
