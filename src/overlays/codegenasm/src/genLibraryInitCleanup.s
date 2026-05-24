;
; genLibraryInitCleanup.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; library initialization and cleanup routines

.include "asm.inc"
.include "ast.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export initLibraries, cleanupLibraries

.import findUnit, genThreeAddr

.data

lblInit: .asciiz "init"
lblCleanup: .asciiz "cleanup"

.bss

currentDecl: .res 4
isInit: .res 1
label: .res 15

.code

.proc initLibraries
    pha
    lda #1
    sta isInit
    pla
    jmp genLibraryInitCleanup
.endproc

.proc cleanupLibraries
    pha
    lda #0
    sta isInit
    pla
    ; Fall through to genLibraryInitCleanup
.endproc

; AST root passed in Q
.proc genLibraryInitCleanup
    stq ptr1

    ; Grab the code block from the root node
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

    ; Grab the first declaration from the code block
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq currentDecl

    ; Loop through the declarations
L1: ldq currentDecl
    jsr isQZero
    bne L2
    rts

L2: stq ptr1
    ; Is the kind DECL_USES?
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    bne NX

    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr findUnit
    jsr isQZero
    beq NX

    stq ptr1            ; ptr1 is unit
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2            ; ptr2 is unit decl

    ldz #decl::isLibrary
    nop
    lda (ptr2),z
    beq NX

    lda isInit
    bne IN

    ; Cleanup
    lda #<lblCleanup
    sta ptr3
    lda #>lblCleanup
    sta ptr3+1
    bra L3

    ; Init
IN: lda #<lblInit
    sta ptr3
    lda #>lblInit
    sta ptr3+1

    ; Write the prefix to the label
L3: ldy #0
    ldx #0
:   lda (ptr3),y
    beq :+
    sta label,x
    inx
    iny
    bne :-
:   stx tmp1            ; length of prefix in tmp1

    ; Pointer to unit AST in intOp32
    ldq ptr2
    stq intOp32
    lda #<label
    clc
    adc tmp1
    sta tmp2
    lda #>label
    adc #0
    tax
    lda tmp2
    jsr hexstr

    ; Write the JSR to the init/cleanup routine
    lda #<label
    ldx #>label
    ldy #LINKADDR_BOTH
    ldz #1
    jsr linkAddressLookup
    genThree OC_JSR, 0

NX: ldq currentDecl
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq currentDecl
    jmp L1

    rts
.endproc
